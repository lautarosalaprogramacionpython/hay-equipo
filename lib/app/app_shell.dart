import 'package:material_ui/material_ui.dart';

import 'chat_screens.dart';
import 'community_screens.dart';
import 'demo_store.dart';
import 'home_screen.dart';
import 'match_screen.dart';
import 'profile_screen.dart';
import 'ui_kit.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.store, super.key});

  final DemoStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _communityTab = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_soccer_outlined),
      selectedIcon: Icon(Icons.sports_soccer),
      label: 'Partidos',
    ),
    NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: 'Comunidad',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chats',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final wide = constraints.maxWidth >= 1200;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const BrandMark(size: 34),
                  const SizedBox(width: 10),
                  const Text('Hay Equipo'),
                  if (constraints.maxWidth >= 480) ...[
                    const SizedBox(width: 10),
                    const LocalDemoBadge(),
                  ],
                ],
              ),
              actions: [
                if (_selectedIndex == 0) ...[
                  IconButton(
                    tooltip: 'Crear publicación',
                    onPressed: () => showPostComposer(context, widget.store),
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  IconButton(
                    tooltip: 'Abrir chats',
                    onPressed: () => _selectDestination(3),
                    icon: const Icon(Icons.send_outlined),
                  ),
                ],
                IconButton(
                  tooltip: 'Ambiente sonoro',
                  onPressed: _openSound,
                  icon: Icon(
                    widget.store.ambientEnabled
                        ? Icons.graphic_eq
                        : Icons.music_off_outlined,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              bottom: compact && constraints.maxWidth < 480
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(38),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 0, 18, 9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: LocalDemoBadge(),
                        ),
                      ),
                    )
                  : null,
            ),
            body: Row(
              children: [
                if (!compact) ...[
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectDestination,
                    extended: wide,
                    labelType: wide ? null : NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Inicio'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.sports_soccer_outlined),
                        selectedIcon: Icon(Icons.sports_soccer),
                        label: Text('Partidos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.groups_outlined),
                        selectedIcon: Icon(Icons.groups),
                        label: Text('Comunidad'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat_bubble_outline),
                        selectedIcon: Icon(Icons.chat_bubble),
                        label: Text('Chats'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Perfil'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey('$_selectedIndex-$_communityTab'),
                      child: _selectedPage(),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.store.ambientEnabled)
                        _MiniMusicBar(
                          store: widget.store,
                        ),
                      NavigationBar(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _selectDestination,
                        destinations: _destinations,
                      ),
                    ],
                  )
                : null,
          );
        },
      );

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          store: widget.store,
          onOpenMatches: () => _selectDestination(1),
          onOpenCommunity: () => _selectDestination(2),
        );
      case 1:
        return MatchScreen(store: widget.store);
      case 2:
        return CommunityScreen(
          store: widget.store,
          selectedTab: _communityTab,
          onTabSelected: (index) => setState(() => _communityTab = index),
        );
      case 3:
        return ChatsScreen(store: widget.store);
      default:
        return ProfileScreen(store: widget.store);
    }
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) {
      if (index == 2 && _communityTab != 0) {
        setState(() => _communityTab = 0);
      }
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _openSound() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ambiente sonoro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Una capa instrumental discreta, pensada para acompañar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Entre partidos'),
                  subtitle:
                      const Text('Música suave · guardada en este equipo'),
                  value: widget.store.ambientEnabled,
                  onChanged: (enabled) async {
                    try {
                      await widget.store.setAmbientEnabled(enabled);
                    } catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content:
                                Text('No se pudo cambiar el audio: $error'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMusicBar extends StatelessWidget {
  const _MiniMusicBar({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        padding: const EdgeInsets.only(left: 18, right: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Row(
          children: [
            Icon(Icons.equalizer,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Entre partidos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              tooltip: 'Pausar música',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                try {
                  await store.setAmbientEnabled(false);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('No se pudo pausar el audio: $error')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.pause, size: 20),
            ),
          ],
        ),
      );
}
