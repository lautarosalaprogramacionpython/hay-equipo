import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'demo_store.dart';
import 'ui_kit.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({required this.store, super.key});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageBody(
          children: [
            Text(
              'El próximo partido',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Encontrá rival, elegí cancha y pongan fecha.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _MatchHero(store: store),
            const SizedBox(height: 22),
            _TournamentSection(
              tournaments: store.tournaments,
              onCreate: () => _createTournament(context),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _createMatch(context),
              icon: const Icon(Icons.add),
              label: const Text('Proponer un partido'),
            ),
            const SizedBox(height: 22),
            SectionHeading(
              title: 'Partidos y propuestas',
              subtitle: '${store.matches.length} en esta demo',
            ),
            const SizedBox(height: 12),
            if (store.matches.isEmpty)
              EmptyState(
                icon: Icons.sports_soccer_outlined,
                title: 'Todavía no hay cruces',
                message:
                    'Armá una propuesta para ordenar el próximo encuentro.',
                action: OutlinedButton.icon(
                  onPressed: () => _createMatch(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear propuesta'),
                ),
              )
            else
              for (final match in store.matches) ...[
                _MatchCard(match: match, store: store),
                const SizedBox(height: 12),
              ],
          ],
        ),
      );

  Future<void> _createTournament(BuildContext context) async {
    final draft = await showModalBottomSheet<_TournamentDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateTournamentSheet(),
    );
    if (draft == null || !context.mounted) return;
    try {
      await store.createTournament(
        name: draft.name,
        zone: draft.zone,
        courtSize: draft.courtSize,
        startDate: draft.startDate,
        teamLimit: draft.teamLimit,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Torneo creado en esta demo.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el torneo: $error')),
        );
      }
    }
  }

  Future<void> _createMatch(BuildContext context) async {
    final draft = await showModalBottomSheet<_MatchDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreateMatchSheet(store: store),
    );
    if (draft == null || !context.mounted) return;
    try {
      await store.createMatch(
        homeTeam: draft.homeTeam,
        awayTeam: draft.awayTeam,
        courtSize: draft.courtSize,
        zone: draft.zone,
        scheduledAt: draft.scheduledAt,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta guardada en la demo.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el partido: $error')),
        );
      }
    }
  }
}

class _TournamentSection extends StatelessWidget {
  const _TournamentSection({
    required this.tournaments,
    required this.onCreate,
  });

  final List<DemoTournament> tournaments;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(
            title: 'Torneos',
            subtitle: 'Armá una competencia para tu zona.',
            actionLabel: 'Crear torneo',
            onAction: onCreate,
          ),
          const SizedBox(height: 10),
          if (tournaments.isEmpty)
            DemoPanel(
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Todavía no hay torneos.')),
                  TextButton(onPressed: onCreate, child: const Text('Crear')),
                ],
              ),
            )
          else
            for (final tournament in tournaments.take(3)) ...[
              _TournamentCard(tournament: tournament),
              const SizedBox(height: 9),
            ],
        ],
      );
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament});

  final DemoTournament tournament;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DemoPanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.emoji_events_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(tournament.startDate)} · ${tournament.zone} · Fútbol ${tournament.courtSize}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${tournament.registeredTeams}/${tournament.teamLimit} equipos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentDraft {
  const _TournamentDraft({
    required this.name,
    required this.zone,
    required this.courtSize,
    required this.startDate,
    required this.teamLimit,
  });

  final String name;
  final String zone;
  final int courtSize;
  final DateTime startDate;
  final int teamLimit;
}

class _CreateTournamentSheet extends StatefulWidget {
  const _CreateTournamentSheet();

  @override
  State<_CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<_CreateTournamentSheet> {
  final _name = TextEditingController();
  final _zone = TextEditingController(text: 'Palermo');
  int _courtSize = 5;
  int _teamLimit = 8;
  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (chosen != null) setState(() => _startDate = chosen);
  }

  void _submit() {
    if (_name.text.trim().length < 4) {
      setState(() => _error = 'El torneo necesita un nombre de 4 letras o más.');
      return;
    }
    if (_zone.text.trim().isEmpty) {
      setState(() => _error = 'Indicá dónde se juega el torneo.');
      return;
    }
    Navigator.pop(
      context,
      _TournamentDraft(
        name: _name.text.trim(),
        zone: _zone.text.trim(),
        courtSize: _courtSize,
        startDate: _startDate,
        teamLimit: _teamLimit,
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
                Text('Crear torneo',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                const Text('Definí lo básico; los detalles se coordinan después.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  maxLength: 48,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del torneo',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _zone,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    prefixIcon: Icon(Icons.place_outlined),
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
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Fecha: ${formatDate(_startDate)}'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _teamLimit,
                  decoration: const InputDecoration(
                    labelText: 'Cupo de equipos',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: const [4, 8, 12, 16, 24, 32]
                      .map(
                        (count) => DropdownMenuItem(
                          value: count,
                          child: Text('$count equipos'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _teamLimit = value);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                const LocalDemoBadge(
                  label: 'Torneo de prueba, guardado en este dispositivo',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear torneo'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MatchHero extends StatelessWidget {
  const _MatchHero({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nextMatch = store.matches
        .where((match) => match.status != DemoMatchStatus.declined)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final match = nextMatch.isEmpty ? null : nextMatch.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.sports_soccer, color: scheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match == null ? 'La cancha está abierta' : 'Ya hay un cruce',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  match == null
                      ? 'Elegí equipo, zona y horario para empezar.'
                      : '${match.homeTeam} vs. ${match.awayTeam} · ${formatDate(match.scheduledAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (match != null)
            Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.store});

  final DemoMatch match;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (match.status) {
      DemoMatchStatus.proposed =>
        Theme.of(context).extension<BrandColors>()!.warning,
      DemoMatchStatus.accepted =>
        Theme.of(context).extension<BrandColors>()!.success,
      DemoMatchStatus.declined => scheme.error,
    };
    return DemoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fútbol ${match.courtSize}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  matchStatusLabel(match.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones del partido',
                onSelected: (value) => _updateStatus(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'accept',
                    child: Text('Marcar como confirmado'),
                  ),
                  PopupMenuItem(
                    value: 'decline',
                    child: Text('Rechazar propuesta'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.secondary,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  match.awayTeam,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MatchDetail(
                icon: Icons.calendar_month_outlined,
                label:
                    '${formatDate(match.scheduledAt)} · ${formatTime(match.scheduledAt)}',
              ),
              _MatchDetail(
                icon: Icons.place_outlined,
                label: match.zone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LocalDemoBadge(
            label: 'Propuesta local; nadie más fue notificado',
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String value) async {
    final status =
        value == 'accept' ? DemoMatchStatus.accepted : DemoMatchStatus.declined;
    try {
      await store.respondToMatch(match.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == DemoMatchStatus.accepted
                ? 'Partido marcado como confirmado en esta demo.'
                : 'Propuesta rechazada en esta demo.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    }
  }
}

class _MatchDetail extends StatelessWidget {
  const _MatchDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _MatchDraft {
  const _MatchDraft({
    required this.homeTeam,
    required this.awayTeam,
    required this.courtSize,
    required this.zone,
    required this.scheduledAt,
  });

  final String homeTeam;
  final String awayTeam;
  final int courtSize;
  final String zone;
  final DateTime scheduledAt;
}

class _CreateMatchSheet extends StatefulWidget {
  const _CreateMatchSheet({required this.store});

  final DemoStore store;

  @override
  State<_CreateMatchSheet> createState() => _CreateMatchSheetState();
}

class _CreateMatchSheetState extends State<_CreateMatchSheet> {
  late String _homeTeam;
  String? _awayTeam;
  int _courtSize = 5;
  final _zone = TextEditingController(text: 'Palermo');
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  String? _error;

  @override
  void initState() {
    super.initState();
    final ownTeams = widget.store.teams.where((team) => team.isMine);
    _homeTeam = ownTeams.isNotEmpty
        ? ownTeams.first.name
        : widget.store.teams.first.name;
    _courtSize = widget.store.teams
        .firstWhere((team) => team.name == _homeTeam)
        .courtSize;
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownTeams = widget.store.teams.where((team) => team.isMine).toList();
    final opponentTeams = widget.store.teams
        .where((team) => team.name != _homeTeam && team.courtSize == _courtSize)
        .toList();
    final validOpponent =
        opponentTeams.any((team) => team.name == _awayTeam) ? _awayTeam : null;
    return SafeArea(
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
              Text('Proponer partido',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              const Text(
                  'Coordiná un cruce. La invitación es local a la demo.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ownTeams.any((team) => team.name == _homeTeam)
                    ? _homeTeam
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Tu equipo',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: ownTeams
                    .map((team) => DropdownMenuItem(
                          value: team.name,
                          child: Text(team.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _homeTeam = value;
                    _awayTeam = null;
                    _courtSize = widget.store.teams
                        .firstWhere((team) => team.name == value)
                        .courtSize;
                  });
                },
              ),
              if (ownTeams.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'No hay equipo propio. Creá uno primero en Comunidad.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: validOpponent,
                decoration: const InputDecoration(
                  labelText: 'Equipo rival',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: opponentTeams
                    .map((team) => DropdownMenuItem(
                          value: team.name,
                          child: Text(team.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _awayTeam = value),
              ),
              if (opponentTeams.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'No hay rivales disponibles para cancha $_courtSize.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 14),
              Text('Modalidad', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 7),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 5, label: Text('Cancha 5')),
                  ButtonSegment(value: 7, label: Text('Cancha 7')),
                ],
                selected: {_courtSize},
                onSelectionChanged: (value) => setState(() {
                  _courtSize = value.first;
                  _awayTeam = null;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _zone,
                decoration: const InputDecoration(
                  labelText: 'Zona o cancha',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(formatDate(_scheduledAt)),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chooseTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(formatTime(_scheduledAt)),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed:
                    ownTeams.isEmpty || opponentTeams.isEmpty ? null : _submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Guardar propuesta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(now) ? now : _scheduledAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          _scheduledAt.hour,
          _scheduledAt.minute,
        );
      });
    }
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time != null) {
      setState(() {
        _scheduledAt = DateTime(
          _scheduledAt.year,
          _scheduledAt.month,
          _scheduledAt.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _submit() {
    if (_awayTeam == null) {
      setState(() => _error = 'Elegí un equipo rival.');
      return;
    }
    if (_zone.text.trim().isEmpty) {
      setState(() => _error = 'Escribí la zona o cancha.');
      return;
    }
    if (_scheduledAt.isBefore(DateTime.now())) {
      setState(() => _error = 'Elegí un horario futuro.');
      return;
    }
    Navigator.pop(
      context,
      _MatchDraft(
        homeTeam: _homeTeam,
        awayTeam: _awayTeam!,
        courtSize: _courtSize,
        zone: _zone.text.trim(),
        scheduledAt: _scheduledAt,
      ),
    );
  }
}
