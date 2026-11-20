import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import 'local_media_io.dart'
    if (dart.library.html) 'local_media_web.dart' as media_platform;

Future<String> createRecordingPath() => media_platform.createRecordingPath();

Future<Uint8List> readRecordedAudio(String path) =>
    media_platform.readRecordedAudio(path);

Future<VideoPlayerController> createVideoController(
  Uint8List bytes,
  String mimeType,
) =>
    media_platform.createVideoController(bytes, mimeType);
