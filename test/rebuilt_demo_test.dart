ta de github import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hay_equipo/app/app_shell.dart';
import 'package:hay_equipo/app/app_theme.dart';
import 'package:hay_equipo/app/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DemoStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = DemoStore();
    await store.initialize();
  });

  tearDown(() {
    store.dispose();
  });

  test('demo state persists new posts, teams, matches and messages', () async {
    await store.addPost(caption: 'Nos vemos el jueves.');
    await store.createTeam(
      name: 'Barrio Unido',
      description: 'Una banda para jugar.',
      courtSize: 7,
      zone: 'Almagro',
    );
    await store.createMatch(
      homeTeam: 'Los del Sur',
      awayTeam: 'Fieras FC',
      courtSize: 5,
      zone: 'Palermo',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
    );
    await store.createTournament(
      name: 'Copa del Barrio',
      zone: 'Boedo',
      courtSize: 5,
      startDate: DateTime.now().add(const Duration(days: 14)),
      teamLimit: 8,
    );
    final chatId =
        await store.openConversation('Sofía Martínez', 'Jugador · Arquera');
    await store.sendMessage(
      chatId,
      '',
      attachmentType: 'image',
      attachmentBase64: 'ZGVtbw==',
      mimeType: 'image/jpeg',
    );

    final restored = DemoStore();
    await restored.initialize();

    expect(restored.posts.first.caption, 'Nos vemos el jueves.');
    expect(restored.teams.first.name, 'Barrio Unido');
    expect(
      restored.matches
          .singleWhere((match) => match.awayTeam == 'Fieras FC')
          .awayTeam,
      'Fieras FC',
    );
    expect(
      restored.tournaments
          .singleWhere((tournament) => tournament.name == 'Copa del Barrio')
          .name,
      'Copa del Barrio',
    );
    expect(restored.conversations.first.messages.last.attachmentType, 'image');
    expect(restored.conversations.first.messages.last.attachmentBase64,
        'ZGVtbw==');
    expect(restored.ambientEnabled, isFalse);
    restored.dispose();
  });

  test('demo rejects invalid or duplicate teams and past match times',
      () async {
    await expectLater(
      store.createTeam(
        name: 'HE',
        description: '',
        courtSize: 5,
        zone: 'Palermo',
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createTeam(
        name: 'Fieras FC',
        description: '',
        courtSize: 5,
        zone: 'Palermo',
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createMatch(
        homeTeam: 'Los del Sur',
        awayTeam: 'Fieras FC',
        courtSize: 5,
        zone: 'Palermo',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createTournament(
        name: 'Bad',
        zone: 'Boedo',
        courtSize: 5,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        teamLimit: 8,
      ),
      throwsArgumentError,
    );
  });

  test('creating a team with a player opening adds a discoverable post',
      () async {
    await store.createTeam(
      name: 'Barrio Unido',
      description: 'Equipo mixto',
      courtSize: 5,
      zone: 'Almagro',
      lookingForPlayers: true,
      positionNeeded: 'Arquera',
    );

    expect(store.teams.first.lookingForPlayers, isTrue);
    expect(store.teams.first.positionNeeded, 'Arquera');
    expect(store.posts.first.teamId, store.teams.first.id);
    expect(store.posts.first.caption, contains('Arquera'));
  });

  testWidgets('new demo opens the redesigned inline post composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        home: AppShell(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Historias'), findsOneWidget);

    await tester.tap(find.text('¿Qué querés compartir?'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir una jugada'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'Un lindo partido con amigos.',
    );
    await tester.tap(find.text('Compartir en mi muro'));
    await tester.pumpAndSettle();

    expect(find.text('Un lindo partido con amigos.'), findsOneWidget);
  });
}
