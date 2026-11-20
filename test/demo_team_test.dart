import 'package:flutter_test/flutter_test.dart';
import 'package:hay_equipo/app/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo stores team join requests without changing member count',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = DemoStore();
    await store.initialize();
    final team = store.teams.firstWhere((item) => !item.isMine);

    await store.requestToJoin(team.id);

    final updated = store.teams.firstWhere((item) => item.id == team.id);
    expect(updated.requested, isTrue);
    expect(updated.memberCount, team.memberCount);
    store.dispose();
  });

  test('demo team join requests can be cancelled', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DemoStore();
    await store.initialize();
    final team = store.teams.firstWhere((item) => !item.isMine);

    await store.requestToJoin(team.id);
    await store.cancelJoinRequest(team.id);

    final restored = store.teams.firstWhere((item) => item.id == team.id);
    expect(restored.requested, isFalse);
    store.dispose();
  });
}
