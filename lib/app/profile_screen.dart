import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'demo_store.dart';
import 'ui_kit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.store, super.key});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageBody(
          children: [
            Text('Mi perfil',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 15),
            _ProfileHeader(store: store),
            const SizedBox(height: 16),
            _ProfileStats(store: store),
            const SizedBox(height: 20),
            SectionHeading(
              title: 'Preferencias',
              subtitle: 'Ajustá la experiencia a tu manera.',
            ),
            const SizedBox(height: 10),
            _AppearanceSettings(store: store),
            const SizedBox(height: 10),
            _ProfileAction(
              icon: Icons.campaign_outlined,
              title: 'Promocionar un comercio o torneo',
              subtitle: 'Consulta manual · sin pagos en la app',
              onTap: () => _showSponsorshipInfo(context),
            ),
            const SizedBox(height: 10),
            _ProfileAction(
              icon: Icons.shield_outlined,
              title: 'Datos y privacidad',
              subtitle: 'Conocé qué guarda esta demo y dónde.',
              onTap: () => _showPrivacyInfo(context),
            ),
            if (store.reports.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeading(
                title: 'Reportes de esta demo',
                subtitle: 'Guardados solo en este dispositivo.',
              ),
              const SizedBox(height: 8),
              for (final report in store.reports.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(report),
                ),
            ],
            const SizedBox(height: 16),
            const LocalDemoBadge(
              label: 'Perfil privado de esta demostración',
            ),
          ],
        ),
      );

  void _showSponsorshipInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Espacios patrocinados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 9),
              const Text(
                'Los comercios y organizadores pueden consultar por espacios '
                'identificados como patrocinados. El equipo revisa cada '
                'propuesta manualmente; esta app no procesa pagos ni publica '
                'anuncios automáticamente.',
              ),
              const SizedBox(height: 14),
              SelectableText('nsala932@gmail.com'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        const ClipboardData(text: 'nsala932@gmail.com'),
                      );
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Correo copiado.')),
                        );
                      }
                    } catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text('No se pudo copiar: $error')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar contacto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Text(
            'El perfil, las publicaciones, los equipos, los partidos, los chats '
            'y las preferencias se guardan en este dispositivo. No se envían '
            'a otros jugadores ni a soporte. Para producción faltan la cuenta '
            'real, sincronización, borrado de cuenta, retención y políticas '
            'de privacidad aprobadas.',
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DemoPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          PlayerAvatar(
            name: store.playerName,
            photoBase64: store.playerPhotoBase64,
            size: 78,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.playerName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  store.playerBio.isEmpty
                      ? 'Sumá una descripción para tu perfil.'
                      : store.playerBio,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar perfil'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final result = await showModalBottomSheet<_ProfileDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditProfileSheet(store: store),
    );
    if (result == null || !context.mounted) return;
    try {
      await store.updateProfile(
        name: result.name,
        bio: result.bio,
        photoBase64: result.photoBase64,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el perfil: $error')),
        );
      }
    }
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _StatCard(
              value:
                  '${store.posts.where((post) => post.author == store.playerName).length}',
              label: 'Publicaciones',
              icon: Icons.grid_on_outlined,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatCard(
              value: '${store.teams.where((team) => team.isMine).length}',
              label: 'Equipos',
              icon: Icons.groups_outlined,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatCard(
              value: '${store.matches.length}',
              label: 'Partidos',
              icon: Icons.sports_soccer_outlined,
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DemoPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 5),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => DemoPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_outlined),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {store.themeMode},
              onSelectionChanged: (value) => _setTheme(context, value.first),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Música ambiental'),
              subtitle: const Text('Instrumental suave, apagada por defecto.'),
              secondary: const Icon(Icons.music_note_outlined),
              value: store.ambientEnabled,
              onChanged: (enabled) => _setAmbient(context, enabled),
            ),
          ],
        ),
      );

  Future<void> _setTheme(BuildContext context, ThemeMode mode) async {
    try {
      await store.setThemeMode(mode);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el tema: $error')),
        );
      }
    }
  }

  Future<void> _setAmbient(BuildContext context, bool enabled) async {
    try {
      await store.setAmbientEnabled(enabled);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el audio: $error')),
        );
      }
    }
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DemoPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class _ProfileDraft {
  const _ProfileDraft({
    required this.name,
    required this.bio,
    this.photoBase64,
  });

  final String name;
  final String bio;
  final String? photoBase64;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.store});

  final DemoStore store;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.store.playerName);
  late final _bio = TextEditingController(text: widget.store.playerBio);
  String? _photoBase64;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 700,
        imageQuality: 78,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 1024 * 1024) {
        setState(() => _error = 'Elegí una foto de perfil menor a 1 MB.');
        return;
      }
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo elegir la foto: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Text('Editar perfil',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      PlayerAvatar(
                        name: _name.text,
                        photoBase64:
                            _photoBase64 ?? widget.store.playerPhotoBase64,
                        size: 78,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filledTonal(
                          tooltip: 'Elegir foto',
                          onPressed: _loading ? null : _pickPhoto,
                          icon: const Icon(Icons.camera_alt_outlined, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _name,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bio,
                  maxLength: 140,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_name.text.trim().length < 2) {
                            setState(() => _error = 'Escribí tu nombre.');
                            return;
                          }
                          Navigator.pop(
                            context,
                            _ProfileDraft(
                              name: _name.text.trim(),
                              bio: _bio.text.trim(),
                              photoBase64: _photoBase64,
                            ),
                          );
                        },
                  child: Text(_loading ? 'Cargando foto…' : 'Guardar perfil'),
                ),
              ],
            ),
          ),
        ),
      );
}
