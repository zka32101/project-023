import 'package:flutter/material.dart';

/// 音量メーター表示ウィジェット
class VolumeMeter extends StatelessWidget {
  final double amplitude; // 0.0 - 1.0
  final bool isRecording;

  const VolumeMeter({
    Key? key,
    required this.amplitude,
    required this.isRecording,
  }) : super(key: key);

  /// 振幅値に基づいて色を決定
  Color _getColor(double value) {
    // 正規化: 0-100の値を0-1にスケール
    final normalized = (value * 100).clamp(0.0, 1.0);

    if (normalized < 0.3) {
      return Colors.green;
    } else if (normalized < 0.6) {
      return Colors.yellow;
    } else if (normalized < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// ピークレベルを計算（0-100）
  int _getPeakLevel() {
    final normalized = (amplitude * 100).clamp(0.0, 1.0);
    return (normalized * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final peakLevel = _getPeakLevel();
    final color = _getColor(amplitude);
    final normalized = (amplitude * 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // メーターバー
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Stack(
            children: [
              // 背景グリッド
              Row(
                children: List.generate(
                  10,
                  (index) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade800,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 音量バー
              Container(
                width: 200 * normalized, // 最大幅200px
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              // ピークインジケータ
              if (isRecording)
                Positioned(
                  left: 200 * normalized - 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // レベル表示（dB）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'レベル: $peakLevel%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isRecording ? '録音中' : 'スタンバイ',
              style: TextStyle(
                color: isRecording ? Colors.red : Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // スケール表示
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('静か', style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text('通常', style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text('大きい', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
