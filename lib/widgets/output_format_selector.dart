import 'package:flutter/material.dart';

/// Output format and settings selector widget
class OutputFormatSelector extends StatefulWidget {
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onResolutionChanged;
  final ValueChanged<int> onFpsChanged;

  const OutputFormatSelector({
    Key? key,
    required this.onFormatChanged,
    required this.onResolutionChanged,
    required this.onFpsChanged,
  }) : super(key: key);

  @override
  State<OutputFormatSelector> createState() => _OutputFormatSelectorState();
}

class _OutputFormatSelectorState extends State<OutputFormatSelector> {
  late String _selectedFormat;
  late String _selectedResolution;
  late int _selectedFps;

  @override
  void initState() {
    super.initState();
    _selectedFormat = 'mp4';
    _selectedResolution = '1080p';
    _selectedFps = 30;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '出力フォーマット設定',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Format selection
            _buildFormatSelector(),
            const SizedBox(height: 16),

            // Resolution selection
            _buildResolutionSelector(),
            const SizedBox(height: 16),

            // FPS selection
            _buildFpsSelector(),
            const SizedBox(height: 8),

            // Format info
            _buildFormatInfo(),
          ],
        ),
      ),
    );
  }

  /// Build format selector
  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ファイル形式',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['mp4', 'webm', 'mov']
              .map((format) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(format.toUpperCase()),
                        selected: _selectedFormat == format,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFormat = format);
                            widget.onFormatChanged(format);
                          }
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build resolution selector
  Widget _buildResolutionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '解像度',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['720p', '1080p', '4k']
              .map((resolution) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(resolution),
                        selected: _selectedResolution == resolution,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedResolution = resolution);
                            widget.onResolutionChanged(resolution);
                          }
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build FPS selector
  Widget _buildFpsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'フレームレート',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [24, 30, 60]
              .map((fps) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('${fps}fps'),
                        selected: _selectedFps == fps,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFps = fps);
                            widget.onFpsChanged(fps);
                          }
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build format information
  Widget _buildFormatInfo() {
    final info = _getFormatInfo(_selectedFormat);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedFormat.toUpperCase()}フォーマット情報',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ビデオコーデック: ${info['videoCodec']}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            'オーディオコーデック: ${info['audioCodec']}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Get format information
  Map<String, String> _getFormatInfo(String format) {
    return switch (format) {
      'mp4' => {
        'videoCodec': 'H.264',
        'audioCodec': 'AAC',
      },
      'webm' => {
        'videoCodec': 'VP9',
        'audioCodec': 'Opus',
      },
      'mov' => {
        'videoCodec': 'ProRes',
        'audioCodec': 'AAC',
      },
      _ => {
        'videoCodec': 'Unknown',
        'audioCodec': 'Unknown',
      },
    };
  }
}
