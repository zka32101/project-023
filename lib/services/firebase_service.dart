import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/project.dart';
import '../models/frame.dart';
import '../config/constants.dart';
import '../utils/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  late final FirebaseRemoteConfig _remoteConfig;

  String? _userId;

  String? get userId => _userId;

  Future<void> initialize() async {
    try {
      // Initialize Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default values for Remote Config
      await _remoteConfig.setDefaults({
        'free_trial_minutes': FirestoreConstants.appConfigCollection,
        'price_jpy': AppPrices.priceJPY,
        'paywall_text_variant': 'A',
        'aha_moment_frame_threshold': ARConstants.ahaFrameThreshold,
        'max_frames_free': ARConstants.maxFramesFree,
      });

      await _remoteConfig.fetchAndActivate();

      // Crashlytics error handling
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterError(errorDetails);
      };
    } catch (e) {
      AppLogger.error('Firebase initialization error', e);
    }
  }

  // Auth Methods
  Future<String> anonymousSignIn() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      _userId = userCredential.user?.uid;

      // Create user document in Firestore
      if (_userId != null) {
        await _firestore
            .collection(FirestoreConstants.usersCollection)
            .doc(_userId)
            .set({
          'userId': _userId,
          'createdAt': FieldValue.serverTimestamp(),
          'isPurchased': false,
          'deviceModel': 'unknown', // TODO: device_info_plus で取得
          'osVersion': 'unknown',
        });
      }

      // Log event
      await logEvent('free_trial_started');

      return _userId ?? '';
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  // Project Methods
  Future<String> createProject(String title) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final projectId = _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .doc()
          .id;

      final project = Project(
        projectId: projectId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        title: title,
        fpsPreset: ARConstants.defaultFPS,
        frameCount: 0,
        videoDuration: 0.0,
        status: ProjectStatus.draft,
        deviceOrientation: 'portrait',
      );

      await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .doc(projectId)
          .set(project.toJson());

      return projectId;
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProject(String projectId, Project project) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .doc(projectId)
          .update({
        ...project.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<Project>> getProjects() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Project.fromJson(doc.data())).toList();
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  // Frame Methods
  Future<void> addFrame(
    String projectId,
    Frame frame,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .doc(projectId)
          .collection(FirestoreConstants.framesCollection)
          .doc(frame.frameId)
          .set(frame.toJson());
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<Frame>> getFrames(String projectId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_userId)
          .collection(FirestoreConstants.projectsCollection)
          .doc(projectId)
          .collection(FirestoreConstants.framesCollection)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Frame.fromJson(doc.data())).toList();
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  // Analytics Methods
  Future<void> logEvent(String eventName, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters ?? {},
      );
    } catch (e) {
      AppLogger.error('Analytics error', e);
    }
  }

  // Remote Config Methods
  String getRemoteConfigString(String key, String defaultValue) {
    return _remoteConfig.getString(key);
  }

  int getRemoteConfigInt(String key, int defaultValue) {
    return _remoteConfig.getInt(key);
  }

  bool getRemoteConfigBool(String key, bool defaultValue) {
    return _remoteConfig.getBool(key);
  }
}
