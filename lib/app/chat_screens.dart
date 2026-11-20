import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import 'demo_store.dart';
import 'local_media.dart';
import 'ui_kit.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({required this.store, super.key});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageBody(
          children: [
            Text('Conversaciones',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Coordiná con jugadores, equipos y rivales.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            const LocalDemoBadge(
              label: 'Mensajes guardados solo en este dispositivo',
            ),
            const SizedBox(height: 15),
            if (store.conversations.isEmpty)
              const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Todavía no hay chats',
                message: 'Abrí el perfil de un jugador para iniciar uno.',
              )
            else
              for (final conversation in store.conversations) ...[
                _ConversationTile(
                  conversation: conversation,
                  onTap: () => _openConversation(context, conversation),
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      );

  Future<void> _openConversation(
    BuildContext context,
    DemoConversation conversation,
  ) async {
    try {
      await store.markConversationRead(conversation.id);
      if (context.mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(store: store, chatId: conversation.id),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir la conversación: $error')),
        );
      }
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final DemoConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DemoPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          leading: Stack(
            children: [
              PlayerAvatar(name: conversation.title, size: 50),
              if (conversation.unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conversation.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              conversation.messages.isEmpty
                  ? conversation.subtitle
                  : _messagePreview(conversation.messages.last),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel(conversation.updatedAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 5),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );

  String _messagePreview(DemoMessage message) {
    if (message.text.isNotEmpty) return message.text;
    return switch (message.attachmentType) {
      'image' => '📷 Foto',
      'video' => '🎬 Video',
      'audio' => '🎤 Nota de voz',
      _ => 'Mensaje',
    };
  }

  String _timeLabel(DateTime date) {
    final delta = DateTime.now().difference(date);
    if (delta.inDays > 0) return '${delta.inDays} d';
    if (delta.inHours > 0) return '${delta.inHours} h';
    return '${delta.inMinutes.clamp(1, 59)} min';
  }
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.store,
    required this.chatId,
    super.key,
  });

  final DemoStore store;
  final String chatId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _message = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;
  bool _recording = false;
  Duration _recordedDuration = Duration.zero;
  AudioRecorder? _recorder;
  Stopwatch? _recordingClock;
  Timer? _recordingTimer;

  @override
  void dispose() {
    _message.dispose();
    _recordingTimer?.cancel();
    final recorder = _recorder;
    if (recorder != null) unawaited(recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final results = widget.store.conversations
              .where((chat) => chat.id == widget.chatId);
          if (results.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Esta conversación ya no existe.')),
            );
          }
          final chat = results.first;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  PlayerAvatar(name: chat.title, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat.title),
                        Text(
                          chat.subtitle,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Acerca de este chat',
                  onPressed: () => _showInfo(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  child: const Text(
                    'Chat de demostración · los mensajes no se envían a otras personas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  child: chat.messages.isEmpty
                      ? const EmptyState(
                          icon: Icons.waving_hand_outlined,
                          title: 'Empezá la charla',
                          message: 'Los mensajes que escribas quedan locales.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final message = chat.messages[index];
                            return _MessageBubble(message: message);
                          },
                        ),
                ),
                _MessageComposer(
                  controller: _message,
                  sending: _sending,
                  onSend: _send,
                  recording: _recording,
                  recordingDuration: _recordedDuration,
                  onPickAttachment: _pickAttachment,
                  onToggleRecording: _toggleRecording,
                ),
              ],
            ),
          );
        },
      );

  Future<void> _send() async {
    if (_sending) return;
    final text = _message.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.store.sendMessage(widget.chatId, text);
      _message.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el mensaje: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAttachment(String type) async {
    try {
      final file = type == 'image'
          ? await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1400,
              imageQuality: 78,
            )
          : await _picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 30),
            );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      const maxAttachmentBytes = 3 * 1024 * 1024;
      if (bytes.length > maxAttachmentBytes) {
        _showMessageError(
          type == 'image'
              ? 'La foto supera el límite local de 3 MB.'
              : 'El video supera el límite local de 3 MB.',
        );
        return;
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => type == 'image' ? 'image/jpeg' : 'video/mp4',
      };
      await widget.store.sendMessage(
        widget.chatId,
        '',
        attachmentType: type,
        attachmentBase64: base64Encode(bytes),
        mimeType: mimeType,
      );
    } catch (error) {
      if (mounted) _showMessageError('No se pudo adjuntar el archivo: $error');
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _finishRecording();
      return;
    }
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        _showMessageError('Permití el acceso al micrófono para grabar.');
        return;
      }
      final path = await createRecordingPath();
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
        ),
        path: path,
      );
      _recordingClock = Stopwatch()..start();
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final elapsed = _recordingClock?.elapsed ?? Duration.zero;
        if (mounted) setState(() => _recordedDuration = elapsed);
        if (elapsed >= const Duration(seconds: 60)) {
          unawaited(_finishRecording());
        }
      });
      if (mounted) setState(() => _recording = true);
    } catch (error) {
      if (mounted) _showMessageError('No se pudo iniciar la grabación: $error');
    }
  }

  Future<void> _finishRecording() async {
    final recorder = _recorder;
    final clock = _recordingClock;
    if (recorder == null || clock == null) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    clock.stop();
    final duration = clock.elapsed;
    _recordingClock = null;
    if (mounted) setState(() => _recording = false);
    try {
      final path = await recorder.stop();
      if (path == null) throw StateError('La grabación no produjo un archivo.');
      final bytes = await readRecordedAudio(path);
      if (bytes.isEmpty) throw StateError('La grabación quedó vacía.');
      if (bytes.length > 2 * 1024 * 1024) {
        throw StateError('La nota de voz supera el límite local de 2 MB.');
      }
      await widget.store.sendMessage(
        widget.chatId,
        '',
        attachmentType: 'audio',
        attachmentBase64: base64Encode(bytes),
        mimeType: 'audio/mp4',
        durationMs: duration.inMilliseconds,
      );
    } catch (error) {
      if (mounted) _showMessageError('No se pudo guardar la nota de voz: $error');
    } finally {
      if (mounted) setState(() => _recordedDuration = Duration.zero);
    }
  }

  void _showMessageError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Text(
            'Este chat sirve para recorrer la experiencia. Los mensajes son '
            'locales y no se comparten ni notifican a otro jugador.',
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});

  final DemoMessage message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  AudioPlayer? _audioPlayer;
  StreamSubscription<void>? _audioComplete;
  bool _playing = false;

  DemoMessage get message => widget.message;

  @override
  void dispose() {
    _audioComplete?.cancel();
    final player = _audioPlayer;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final player = _audioPlayer ??= AudioPlayer();
    try {
      if (_playing) {
        await player.stop();
        if (mounted) setState(() => _playing = false);
        return;
      }
      _audioComplete ??= player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
      await player.play(
        BytesSource(
          base64Decode(message.attachmentBase64!),
          mimeType: message.mimeType ?? 'audio/mp4',
        ),
      );
      if (mounted) setState(() => _playing = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reproducir el audio: $error')),
        );
      }
    }
  }

  Future<void> _showVideo() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VideoPlaybackDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alignment =
        message.isMine ? Alignment.centerRight : Alignment.centerLeft;
    final background =
        message.isMine ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final foreground =
        message.isMine ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(message.isMine ? 17 : 5),
              bottomRight: Radius.circular(message.isMine ? 5 : 17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.author,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              if (message.attachmentType == 'image' &&
                  message.attachmentBase64 != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(message.attachmentBase64!),
                    width: 260,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text(
                      'No se pudo mostrar esta foto.',
                    ),
                  ),
                ),
              if (message.attachmentType == 'video' &&
                  message.attachmentBase64 != null)
                _VideoAttachment(
                  onTap: _showVideo,
                  foreground: foreground,
                ),
              if (message.attachmentType == 'audio' &&
                  message.attachmentBase64 != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleAudio,
                      visualDensity: VisualDensity.compact,
                      color: foreground,
                      icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                    ),
                    Text(
                      'Nota de voz · ${_formatDuration(Duration(milliseconds: message.durationMs ?? 0))}',
                      style: TextStyle(color: foreground),
                    ),
                  ],
                ),
              if (message.text.isNotEmpty) ...[
                if (message.attachmentBase64 != null)
                  const SizedBox(height: 7),
                Text(message.text, style: TextStyle(color: foreground)),
              ],
              const SizedBox(height: 4),
              Text(
                '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: .64),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoAttachment extends StatelessWidget {
  const _VideoAttachment({required this.onTap, required this.foreground});

  final VoidCallback onTap;
  final Color foreground;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 260,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 54,
            ),
          ),
        ),
      );
}

class _VideoPlaybackDialog extends StatefulWidget {
  const _VideoPlaybackDialog({required this.message});

  final DemoMessage message;

  @override
  State<_VideoPlaybackDialog> createState() => _VideoPlaybackDialogState();
}

class _VideoPlaybackDialogState extends State<_VideoPlaybackDialog> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = await createVideoController(
        base64Decode(widget.message.attachmentBase64!),
        widget.message.mimeType ?? 'video/mp4',
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _error != null
              ? Text('No se pudo reproducir el video: $_error')
              : _controller == null
                  ? const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),
                          IconButton.filled(
                            onPressed: () {
                              setState(() {
                                _controller!.value.isPlaying
                                    ? _controller!.pause()
                                    : _controller!.play();
                              });
                            },
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      );
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.recording,
    required this.recordingDuration,
    required this.onPickAttachment,
    required this.onToggleRecording,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final bool recording;
  final Duration recordingDuration;
  final ValueChanged<String> onPickAttachment;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Adjuntar foto o video',
                onSelected: onPickAttachment,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'image',
                    child: ListTile(
                      leading: Icon(Icons.image_outlined),
                      title: Text('Foto'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'video',
                    child: ListTile(
                      leading: Icon(Icons.videocam_outlined),
                      title: Text('Video'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
              IconButton(
                tooltip: recording
                    ? 'Detener y enviar nota de voz'
                    : 'Grabar nota de voz',
                onPressed: onToggleRecording,
                color: recording ? Theme.of(context).colorScheme.error : null,
                icon: Icon(
                  recording ? Icons.stop_circle_outlined : Icons.mic_none,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribí un mensaje',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              if (recording)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
                  child: Text(
                    _formatDuration(recordingDuration),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              const SizedBox(width: 2),
              IconButton.filled(
                tooltip: 'Enviar mensaje',
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      );
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}
