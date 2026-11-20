import 'package:material_ui/material_ui.dart';

import 'chat_screens.dart';
import 'app_theme.dart';
import 'demo_store.dart';
import 'ui_kit.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    required this.store,
    required this.selectedTab,
    required this.onTabSelected,
    super.key,
  });

  final DemoStore store;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => PageBody(
          children: [
            Text(
              'Comunidad',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Equipos y jugadores para que el próximo partido salga.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.groups_outlined),
                  label: Text('Equipos'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.person_search_outlined),
                  label: Text('Jugadores'),
                ),
              ],
              selected: {widget.selectedTab},
              onSelectionChanged: (value) => widget.onTabSelected(value.first),
            ),
            const SizedBox(height: 18),
            if (widget.selectedTab == 0)
              _TeamDirectory(store: widget.store)
            else
              _PlayersDirectory(store: widget.store),
          ],
        ),
      );
}

class _TeamDirectory extends StatelessWidget {
  const _TeamDirectory({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _createTeam(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear equipo'),
          ),
          const SizedBox(height: 18),
          const SectionHeading(
            title: 'Equipos cerca tuyo',
            subtitle: 'Encontrá una banda compatible con tu cancha.',
          ),
          const SizedBox(height: 11),
          for (final team in store.teams) ...[
            _TeamTile(
              team: team,
              onTap: () => _openTeam(context, team),
            ),
            const SizedBox(height: 10),
          ],
          const LocalDemoBadge(
            label: 'Solicitudes y equipos son locales a esta demo',
          ),
        ],
      );

  Future<void> _createTeam(BuildContext context) async {
    final result = await showModalBottomSheet<_TeamDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateTeamSheet(),
    );
    if (result == null || !context.mounted) return;
    try {
      await store.createTeam(
        name: result.name,
        description: result.description,
        courtSize: result.courtSize,
        zone: result.zone,
        lookingForPlayers: result.lookingForPlayers,
        positionNeeded: result.positionNeeded,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el equipo: $error')),
        );
      }
    }
  }

  void _openTeam(BuildContext context, DemoTeam team) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(store: store, teamId: team.id),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team, required this.onTap});

  final DemoTeam team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DemoPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.shield_outlined,
                    color: scheme.onPrimaryContainer, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (team.isMine)
                          const LocalDemoBadge(
                            label: 'Mi equipo',
                            icon: Icons.star_outline,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      team.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (team.lookingForPlayers) ...[
                      const SizedBox(height: 7),
                      _RecruitmentBadge(position: team.positionNeeded),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      children: [
                        _MetaLabel(
                          icon: Icons.sports_soccer,
                          label: 'Cancha ${team.courtSize}',
                        ),
                        _MetaLabel(
                          icon: Icons.place_outlined,
                          label: team.zone,
                        ),
                        _MetaLabel(
                          icon: Icons.group_outlined,
                          label: '${team.memberCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({
    required this.store,
    required this.teamId,
    super.key,
  });

  final DemoStore store;
  final String teamId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final matches = store.teams.where((team) => team.id == teamId);
          if (matches.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Este equipo ya no está disponible.')),
            );
          }
          final team = matches.first;
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(title: Text(team.name)),
            body: PageBody(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.shield_outlined,
                                size: 34, color: scheme.onPrimary),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              team.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontSize: 36,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        team.description,
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(label: 'Fútbol ${team.courtSize}'),
                          _DetailChip(label: team.zone),
                          _DetailChip(label: '${team.memberCount} integrantes'),
                          if (team.lookingForPlayers)
                            _DetailChip(
                              label:
                                  'Busca ${team.positionNeeded.isEmpty ? 'jugador/a' : team.positionNeeded}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!team.isMine)
                  FilledButton.icon(
                    onPressed: () => team.requested
                        ? _cancelJoinRequest(context, team)
                        : _requestToJoin(context, team),
                    icon: Icon(team.requested
                        ? Icons.close
                        : Icons.group_add_outlined),
                    label: Text(team.requested
                        ? 'Cancelar solicitud local'
                        : 'Pedir un lugar en el equipo'),
                  ),
                if (!team.isMine && team.lookingForPlayers)
                  OutlinedButton.icon(
                    onPressed: () => _offerToJoin(context, team),
                    icon: const Icon(Icons.sports_outlined),
                    label: Text(
                      'Ofrecerme para ${team.positionNeeded.isEmpty ? 'jugar' : team.positionNeeded}',
                    ),
                  ),
                if (team.isMine)
                  FilledButton.icon(
                    onPressed: () => _openTeamChat(context, team),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Abrir chat del equipo'),
                  ),
                if (team.isMine)
                  OutlinedButton.icon(
                    onPressed: () => _findPlayers(context, team),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Buscar jugador disponible'),
                  ),
                const SizedBox(height: 22),
                SectionHeading(
                  title: 'Plantel',
                  subtitle: 'Capitán · ${team.captain}',
                ),
                const SizedBox(height: 11),
                DemoPanel(
                  child: Row(
                    children: [
                      PlayerAvatar(name: team.captain, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team.captain,
                                style: Theme.of(context).textTheme.titleSmall),
                            Text('Capitán · ${team.zone}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const LocalDemoBadge(
                  label: 'Perfil de equipo de muestra',
                  icon: Icons.phone_android_outlined,
                ),
              ],
            ),
          );
        },
      );

  Future<void> _requestToJoin(BuildContext context, DemoTeam team) async {
    try {
      await store.requestToJoin(team.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud local guardada en la demo.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar la solicitud: $error')),
        );
      }
    }
  }

  Future<void> _cancelJoinRequest(
    BuildContext context,
    DemoTeam team,
  ) async {
    try {
      await store.cancelJoinRequest(team.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud local cancelada.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cancelar: $error')),
        );
      }
    }
  }

  Future<void> _openTeamChat(BuildContext context, DemoTeam team) async {
    try {
      final id = await store.openConversation(
        team.name,
        'Equipo · Cancha ${team.courtSize}',
      );
      if (context.mounted) {
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(store: store, chatId: id),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el chat: $error')),
        );
      }
    }
  }

  Future<void> _offerToJoin(BuildContext context, DemoTeam team) async {
    try {
      final chatId = await store.openConversation(
        team.name,
        'Equipo · Busca ${team.positionNeeded.isEmpty ? 'jugador/a' : team.positionNeeded}',
      );
      await store.sendMessage(
        chatId,
        'Hola, vi que buscan ${team.positionNeeded.isEmpty ? 'jugador/a' : team.positionNeeded}. ¿Tienen lugar?',
      );
      if (context.mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(store: store, chatId: chatId),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo contactar al equipo: $error')),
        );
      }
    }
  }

  Future<void> _findPlayers(BuildContext context, DemoTeam team) async {
    final player = await showModalBottomSheet<DemoPlayer>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jugadores disponibles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final player
                  in DemoStore.players.where((player) => player.available))
                ListTile(
                  leading: PlayerAvatar(name: player.name, size: 42),
                  title: Text(player.name),
                  subtitle: Text('${player.position} · ${player.zone}'),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () => Navigator.pop(sheetContext, player),
                ),
              const LocalDemoBadge(
                label: 'Disponibilidad de jugadores ficticios',
              ),
            ],
          ),
        ),
      ),
    );
    if (player == null || !context.mounted) return;
    try {
      final chatId = await store.openConversation(
        player.name,
        'Jugador · ${player.position}',
      );
      await store.sendMessage(
        chatId,
        'Hola ${player.name.split(' ').first}, somos ${team.name} y buscamos ${team.positionNeeded.isEmpty ? 'un jugador/a' : team.positionNeeded}. ¿Te interesa sumarte?',
      );
      if (context.mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(store: store, chatId: chatId),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo contactar al jugador: $error')),
        );
      }
    }
  }
}

class _RecruitmentBadge extends StatelessWidget {
  const _RecruitmentBadge({required this.position});

  final String position;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Busca ${position.isEmpty ? 'jugador/a' : position}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      );
}

class _PlayersDirectory extends StatefulWidget {
  const _PlayersDirectory({required this.store});

  final DemoStore store;

  @override
  State<_PlayersDirectory> createState() => _PlayersDirectoryState();
}

class _PlayersDirectoryState extends State<_PlayersDirectory> {
  final _search = TextEditingController();
  String _zone = 'Todas';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = DemoStore.players.where((player) {
      final query = _search.text.trim().toLowerCase();
      return (query.isEmpty ||
              player.name.toLowerCase().contains(query) ||
              player.position.toLowerCase().contains(query) ||
              player.team.toLowerCase().contains(query)) &&
          (_zone == 'Todas' || player.zone == _zone);
    }).toList();
    final zones = [
      'Todas',
      ...DemoStore.players.map((player) => player.zone).toSet()
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Nombre, posición o equipo',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(zones[index]),
              selected: _zone == zones[index],
              onSelected: (_) => setState(() => _zone = zones[index]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No encontramos jugadores',
            message: 'Probá otra búsqueda o zona.',
          )
        else
          for (final player in filtered) ...[
            _PlayerTile(
              player: player,
              store: widget.store,
            ),
            const SizedBox(height: 10),
          ],
        const LocalDemoBadge(
          label: 'Jugadores ficticios para recorrer la demo',
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.store});

  final DemoPlayer player;
  final DemoStore store;

  @override
  Widget build(BuildContext context) => DemoPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                PlayerAvatar(name: player.name, size: 48),
                if (player.available)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).extension<BrandColors>()!.success,
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
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: () => _showPlayer(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${player.position} · ${player.team}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${player.zone}  ·  ★ ${player.rating.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Escribirle',
              onPressed: () => _openChat(context),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ],
        ),
      );

  Future<void> _showPlayer(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(name: player.name, size: 70),
              const SizedBox(height: 10),
              Text(player.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${player.position} · ${player.zone} · ${player.team}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openChat(context);
                },
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Escribir mensaje'),
              ),
              TextButton.icon(
                onPressed: () => _report(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Reportar perfil'),
              ),
              const LocalDemoBadge(
                label: 'Perfil de muestra',
                icon: Icons.info_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final chatId = await store.openConversation(
        player.name,
        'Jugador · ${player.position}',
      );
      if (context.mounted) {
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(store: store, chatId: chatId),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el chat: $error')),
        );
      }
    }
  }

  Future<void> _report(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Motivo del reporte'),
        children: [
          for (final item in [
            'Conducta antideportiva',
            'Acoso o amenazas',
            'Perfil falso',
            'Otro',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Text(item),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    try {
      await store.addReport(player.name, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Reporte guardado localmente; no fue enviado a soporte.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el reporte: $error')),
        );
      }
    }
  }
}

class _TeamDraft {
  const _TeamDraft({
    required this.name,
    required this.description,
    required this.courtSize,
    required this.zone,
    required this.lookingForPlayers,
    required this.positionNeeded,
  });

  final String name;
  final String description;
  final int courtSize;
  final String zone;
  final bool lookingForPlayers;
  final String positionNeeded;
}

class _CreateTeamSheet extends StatefulWidget {
  const _CreateTeamSheet();

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _zone = TextEditingController(text: 'Palermo');
  final _positionNeeded = TextEditingController();
  int _courtSize = 5;
  bool _lookingForPlayers = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _zone.dispose();
    _positionNeeded.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().length < 3) {
      setState(
          () => _error = 'El equipo necesita un nombre de 3 letras o más.');
      return;
    }
    if (_zone.text.trim().isEmpty) {
      setState(() => _error = 'Escribí la zona donde suelen jugar.');
      return;
    }
    if (_lookingForPlayers && _positionNeeded.text.trim().isEmpty) {
      setState(() => _error = 'Indicá qué posición les falta.');
      return;
    }
    Navigator.pop(
      context,
      _TeamDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        courtSize: _courtSize,
        zone: _zone.text.trim(),
        lookingForPlayers: _lookingForPlayers,
        positionNeeded: _positionNeeded.text.trim(),
      ),
    );
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
                Text('Armar un equipo',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                const Text('Después podés invitar a la banda.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _description,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Qué los hace un equipo',
                  ),
                ),
                const SizedBox(height: 14),
                Text('Tipo de cancha',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 7),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('Fútbol 5')),
                    ButtonSegment(value: 7, label: Text('Fútbol 7')),
                  ],
                  selected: {_courtSize},
                  onSelectionChanged: (value) =>
                      setState(() => _courtSize = value.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _zone,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _lookingForPlayers,
                  title: const Text('Nos falta un jugador o una jugadora'),
                  subtitle: const Text(
                    'Publicar una búsqueda en el muro de la demo.',
                  ),
                  onChanged: (value) =>
                      setState(() => _lookingForPlayers = value),
                ),
                if (_lookingForPlayers) ...[
                  const SizedBox(height: 5),
                  TextField(
                    controller: _positionNeeded,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Posición o perfil que buscan',
                      hintText: 'Ej. arquera, defensor/a',
                      prefixIcon: Icon(Icons.person_search_outlined),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear equipo'),
                ),
              ],
            ),
          ),
        ),
      );
}
