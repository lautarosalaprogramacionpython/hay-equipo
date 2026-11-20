import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import 'community_screens.dart';
import 'demo_store.dart';
import 'ui_kit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.store,
    required this.onOpenMatches,
    required this.onOpenCommunity,
    super.key,
  });

  final DemoStore store;
  final VoidCallback onOpenMatches;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageBody(
          children: [
            _StoriesStrip(store: store),
            const SizedBox(height: 16),
            _PostComposer(store: store),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.sports_soccer_outlined, size: 18),
                  label: const Text('Buscar partido'),
                  onPressed: onOpenMatches,
                ),
                ActionChip(
                  avatar: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('Ver equipos'),
                  onPressed: onOpenCommunity,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeading(
              title: 'Publicaciones',
              subtitle: 'Momentos y convocatorias de la comunidad.',
            ),
            const SizedBox(height: 12),
            if (store.posts.isEmpty)
              const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'El muro está tranquilo',
                message: 'Compartí una jugada para empezar la conversación.',
              )
            else
              for (final post in store.posts) ...[
                _PostCard(post: post, store: store),
                const SizedBox(height: 14),
              ],
          ],
        ),
      );
}

class _StoriesStrip extends StatelessWidget {
  const _StoriesStrip({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final stories = store.stories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: 'Historias',
          actionLabel: 'Tu historia +',
          onAction: () => _createStory(context),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 91,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _StoryBubble(
                  name: 'Tu historia',
                  isOwn: true,
                  store: store,
                  onTap: () => _createStory(context),
                );
              }
              final story = stories[index - 1];
              return _StoryBubble(
                name: story.author,
                store: store,
                onTap: () => _showStory(context, story),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createStory(BuildContext context) async {
    final controller = TextEditingController();
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Una historia rápida',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: '¿Qué pasa en la cancha?',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, controller.text),
              child: const Text('Compartir historia'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (caption == null || !context.mounted) return;
    try {
      await store.addStory(caption);
    } catch (error) {
      if (context.mounted) {
        _showError(context, 'No se pudo guardar: $error');
      }
    }
  }

  Future<void> _showStory(BuildContext context, DemoStory story) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.sports_soccer),
        title: Text(story.author),
        content: Text(story.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.name,
    required this.store,
    required this.onTap,
    this.isOwn = false,
  });

  final String name;
  final DemoStore store;
  final VoidCallback onTap;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: isOwn ? 'Agregar una historia' : 'Ver historia de $name',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOwn ? scheme.outlineVariant : scheme.primary,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    PlayerAvatar(
                      name: isOwn ? store.playerName : name,
                      photoBase64: isOwn ? store.playerPhotoBase64 : null,
                      size: 48,
                    ),
                    if (isOwn)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 19,
                          height: 19,
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 13,
                            color: scheme.onSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isOwn ? 'Tu historia' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => showPostComposer(context, store),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              PlayerAvatar(
                name: store.playerName,
                photoBase64: store.playerPhotoBase64,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Qué querés compartir?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.photo_camera_outlined, color: scheme.primary, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDraft {
  const _PostDraft({required this.caption, this.photoBase64});

  final String caption;
  final String? photoBase64;
}

Future<void> showPostComposer(
  BuildContext context,
  DemoStore store,
) async {
  final result = await showModalBottomSheet<_PostDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CreatePostSheet(),
  );
  if (result == null || !context.mounted) return;
  try {
    await store.addPost(
      caption: result.caption,
      photoBase64: result.photoBase64,
    );
  } catch (error) {
    if (context.mounted) _showError(context, 'No se pudo compartir: $error');
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _caption = TextEditingController();
  String? _photoBase64;
  bool _picking = false;
  String? _error;

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 78,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        setState(() => _error = 'La foto supera el límite local de 2 MB.');
        return;
      }
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir la galería: $error');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    if (_caption.text.trim().isEmpty && _photoBase64 == null) {
      setState(() => _error = 'Agregá una foto o escribí algo para compartir.');
      return;
    }
    Navigator.pop(
      context,
      _PostDraft(
        caption: _caption.text.trim(),
        photoBase64: _photoBase64,
      ),
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Compartir una jugada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Un momento del partido, una convocatoria o un saludo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_photoBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(_photoBase64!),
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 105,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _picking ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(_picking ? 'Abriendo galería…' : 'Elegir foto'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _caption,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Escribí algo para tu equipo…',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 8),
                const LocalDemoBadge(
                  label: 'Se guarda solo en este dispositivo',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _picking ? null : _submit,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text('Compartir en mi muro'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.store});

  final DemoPost post;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DemoPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthor(post: post, onMore: () => _showPostInfo(context)),
          if (post.photoBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(post.photoBase64!),
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
          if (post.artwork != null && post.photoBase64 == null)
            _PostArtwork(post: post),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: post.isLiked ? 'Quitar me gusta' : 'Me gusta',
                  onPressed: () => store.toggleLike(post.id),
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color:
                        post.isLiked ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Comentar',
                  onPressed: () => _showComments(context),
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                IconButton(
                  tooltip: 'Compartir por chat',
                  onPressed: () => _sharePost(context),
                  icon: const Icon(Icons.send_outlined),
                ),
                const Spacer(),
                IconButton(
                  tooltip: post.isSaved ? 'Quitar de guardados' : 'Guardar',
                  onPressed: () => store.toggleSaved(post.id),
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
            child: Text(
              '${post.likes} Me gusta',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 3),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${post.author}  ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: InkWell(
                onTap: () => _showComments(context),
                child: Text(
                  'Ver los ${post.comments.length} comentarios',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          if (post.teamId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: TextButton.icon(
                onPressed: () => _openTeam(context),
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: const Text('Ver búsqueda del equipo'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 13),
            child: Text(
              _timeAgo(post.createdAt).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: .5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showComments(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CommentsSheet(store: store, postId: post.id),
      );

  Future<void> _sharePost(BuildContext context) async {
    final chatId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Compartir en un chat',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final chat in store.conversations)
                ListTile(
                  leading: PlayerAvatar(name: chat.title, size: 38),
                  title: Text(chat.title),
                  onTap: () => Navigator.pop(sheetContext, chat.id),
                ),
              const LocalDemoBadge(label: 'Compartir es local a esta demo'),
            ],
          ),
        ),
      ),
    );
    if (chatId == null || !context.mounted) return;
    try {
      await store.sendMessage(
        chatId,
        post.caption.isEmpty ? 'Te comparto esta publicación.' : post.caption,
        attachmentType: post.photoBase64 == null ? null : 'image',
        attachmentBase64: post.photoBase64,
        mimeType: post.photoBase64 == null ? null : 'image/jpeg',
      );
      if (context.mounted) {
        _showError(context, 'Publicación compartida en el chat de la demo.');
      }
    } catch (error) {
      if (context.mounted) _showError(context, 'No se pudo compartir: $error');
    }
  }

  void _openTeam(BuildContext context) {
    final teamId = post.teamId;
    if (teamId == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(store: store, teamId: teamId),
      ),
    );
  }

  void _showPostInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Text(
            'Las publicaciones de esta demo se guardan en este dispositivo. '
            'La distribución y moderación se conectan en la etapa de producción.',
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'ahora';
    if (difference.inHours < 1) return 'hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'hace ${difference.inHours} h';
    return 'hace ${difference.inDays} días';
  }
}

class _PostAuthor extends StatelessWidget {
  const _PostAuthor({required this.post, required this.onMore});

  final DemoPost post;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 8, 8),
        child: Row(
          children: [
            PlayerAvatar(name: post.author, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    '${post.handle} · ${_postTimeAgo(post.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Más opciones',
              onPressed: onMore,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      );
}

class _PostArtwork extends StatelessWidget {
  const _PostArtwork({required this.post});

  final DemoPost post;

  @override
  Widget build(BuildContext context) {
    final recruiting = post.artwork == 'recruitment';
    final night = post.artwork == 'night';
    final colors = night
        ? const [Color(0xFF132D39), Color(0xFF3B5860)]
        : recruiting
            ? const [Color(0xFF27513D), Color(0xFF84A76C)]
            : const [Color(0xFF1E674D), Color(0xFF77A775)];
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _PitchPainter()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recruiting ? 'CONVOCATORIA ABIERTA' : 'DE LA CANCHA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  recruiting
                      ? 'Hay lugar\\nen la cancha'
                      : night
                          ? 'Partido\\nbajo las luces'
                          : 'Un equipo.\\nUn domingo.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  recruiting ? post.caption : 'Fútbol, amigos y tercer tiempo.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final field = Rect.fromLTWH(
      size.width * .19,
      size.height * .14,
      size.width * .62,
      size.height * .72,
    );
    canvas.drawRect(field, paint);
    canvas.drawLine(
      Offset(field.center.dx, field.top),
      Offset(field.center.dx, field.bottom),
      paint,
    );
    canvas.drawCircle(field.center, size.height * .115, paint);
    canvas.drawRect(
      Rect.fromLTWH(field.left, field.top + field.height * .29,
          field.width * .16, field.height * .42),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(field.right - field.width * .16,
          field.top + field.height * .29, field.width * .16, field.height * .42),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.store, required this.postId});

  final DemoStore store;
  final String postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await widget.store.addComment(widget.postId, _comment.text);
      _comment.clear();
    } catch (error) {
      if (mounted) _showError(context, 'No se pudo agregar el comentario: $error');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final posts =
                widget.store.posts.where((post) => post.id == widget.postId);
            final comments = posts.isEmpty ? const <String>[] : posts.first.comments;
            return SizedBox(
              height: MediaQuery.of(context).size.height * .7,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Comentarios',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Expanded(
                      child: comments.isEmpty
                          ? const EmptyState(
                              icon: Icons.mode_comment_outlined,
                              title: 'Todavía no hay comentarios',
                              message: 'Sumá el primero.',
                            )
                          : ListView(
                              children: [
                                for (final comment in comments)
                                  ListTile(
                                    leading: PlayerAvatar(
                                      name: widget.store.playerName,
                                      photoBase64:
                                          widget.store.playerPhotoBase64,
                                      size: 36,
                                    ),
                                    title: Text(widget.store.playerName),
                                    subtitle: Text(comment),
                                  ),
                              ],
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            maxLength: 280,
                            decoration: const InputDecoration(
                              hintText: 'Escribí un comentario…',
                              counterText: '',
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Publicar comentario',
                          onPressed: _submit,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

String _postTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'ahora';
  if (difference.inHours < 1) return 'hace ${difference.inMinutes} min';
  if (difference.inDays < 1) return 'hace ${difference.inHours} h';
  return 'hace ${difference.inDays} días';
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
