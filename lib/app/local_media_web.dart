import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';

Future<String> createRecordingPath() async =>
    'hay_equipo_${DateTime.now().microsecondsSinceEpoch}.m4a';

Future<Uint8List> readRecordedAudio(String path) =>
    XFile(path).readAsBytes();

Future<VideoPlayerController> createVideoController(
  Uint8List bytes,
  String mimeType,
) async =>
    VideoPlayerController.networkUrl(
      Uri.dataFromBytes(bytes, mimeType: mimeType),
    );
