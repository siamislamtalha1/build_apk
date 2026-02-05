import 'dart:typed_data';

import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioVisualizer extends StatefulWidget {
  final double height;
  const AudioVisualizer({super.key, this.height = 70});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> {
  late final BloomeePlayerCubit _playerCubit;

  @override
  void initState() {
    super.initState();
    _playerCubit = context.read<BloomeePlayerCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playerCubit.bloomeePlayer.setVisualizerEnabled(true);
    });
  }

  @override
  void dispose() {
    try {
      _playerCubit.bloomeePlayer.setVisualizerEnabled(false);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _playerCubit.bloomeePlayer;

    return SizedBox(
      height: widget.height,
      child: StreamBuilder<Uint8List>(
        stream: player.visualizerWaveformStream,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const SizedBox();
          }
          return CustomPaint(
            painter: _WaveformPainter(data),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Uint8List data;
  _WaveformPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.55);

    final midY = size.height / 2;
    final step = (data.length / (size.width > 0 ? size.width : 1))
        .clamp(1, data.length)
        .toInt();

    final path = Path();
    bool started = false;
    int x = 0;

    for (int i = 0; i < data.length; i += step) {
      final v = (data[i].toInt() & 0xFF) - 128;
      final y = midY + (v / 128.0) * midY;
      if (!started) {
        path.moveTo(0, y);
        started = true;
      } else {
        path.lineTo(x.toDouble(), y);
      }
      x++;
      if (x >= size.width) break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
