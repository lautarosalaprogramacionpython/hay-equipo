import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<String> createRecordingPath() async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}${Platform.pathSeparator}'
      'hay_equipo_${DateTime.now().microsecondsSinceEpoch}.m4a';
}

Future<Uint8List> readRecordedAudio(String path) => File(path).readAsBytes();

Future<VideoPlayerController> createVideoController(
  Uint8List bytes,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();
  final extension = mimeType.split('/').last.split(';').first;
  final path = '${directory.path}${Platform.pathSeparator}'
      'hay_equipo_${DateTime.now().microsecondsSinceEpoch}.$extension';
  final file = await File(path).writeAsBytes(bytes, flush: true);
  return VideoPlayerController.file(file);
}
