import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:my_own_mvvm_with_dependency_injection_blackjack_and_hookers/dependencies.dart';

void main() {
  test("Dependencies ordered correctly", _dependenciesOrderedCorrectly);
  test("Dependencies initialization", _dependenciesInitialization);
  test("Type inference works correctly", _typeInferenceWorksCorrectly);
}

Future<void> _dependenciesOrderedCorrectly() async {
  final scope = Dependencies.pushScope(
    [
      Dependency<String>(
        (scope) => "Hello ${scope.get<int>()}",
        dependsOn: [int],
      ),
      Dependency<double>(
        (scope) => scope.get<String>().length.toDouble(),
        dependsOn: [String],
      ),
      Dependency<int>((scope) => 3),
    ],
  );

  final initializedScope = await scope.build();

  expect(initializedScope.get<String>(), "Hello 3");
  expect(initializedScope.get<int>(), 3);
  expect(initializedScope.get<double>(), 7);
}

Future<void> _dependenciesInitialization() async {
  final log = <String>[];

  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record) {
    log.add(record.message);
  });

  await Dependencies.pushScope(
    [
      Dependency(
        (scope) => FirebaseApp(),
      ),
      Dependency(
        (scope) => FirebaseAnalytics(
          scope.get<FirebaseApp>(),
        ),
        dependsOn: [FirebaseApp],
      ),
      Dependency(
        (scope) => FirebaseAuth(
          scope.get<FirebaseApp>(),
          scope.get<FirebaseAnalytics>(),
        ),
        dependsOn: [FirebaseApp, FirebaseAnalytics],
      ),
      Dependency(
        (scope) => NoDependencies(),
      ),
      Dependency(
        (scope) => DependOnAnalytics(
          scope.get<FirebaseAnalytics>(),
        ),
        dependsOn: [FirebaseAnalytics],
      ),
    ],
  ).build();

  expect(
    log,
    <String>[
      'Pushing new scope with 5 dependencies',
      'Instantiating FirebaseApp',
      'Instantiating NoDependencies',
      'Instantiating FirebaseAnalytics',
      'Instantiating FirebaseAuth',
      'Instantiating DependOnAnalytics',
      'Initializing FirebaseApp, NoDependencies',
      'Initializing FirebaseAnalytics',
      'Initializing FirebaseAnalytics',
      'FirebaseAnalytics initialized',
      'FirebaseAuth initialized',
      'DependOnAnalytics initialized',
    ],
  );
}

abstract base class BaseInitializable implements IInitializable {
  BaseInitializable();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    await Future<void>.delayed(
      Duration(milliseconds: Random().nextInt(50)),
    );

    _isInitialized = true;
  }
}

final class FirebaseApp extends BaseInitializable {
  FirebaseApp();
}

final class FirebaseAnalytics extends BaseInitializable {
  FirebaseAnalytics(this.firebaseApp);

  final FirebaseApp firebaseApp;

  @override
  Future<void> initialize() async {
    if (firebaseApp.isInitialized == false) {
      throw StateError(
        "FirebaseApp must be initialized before FirebaseAnalytics",
      );
    }

    await super.initialize();
  }
}

final class FirebaseAuth extends BaseInitializable {
  FirebaseAuth(this.firebaseApp, this.firebaseAnalytics);

  final FirebaseApp firebaseApp;
  final FirebaseAnalytics firebaseAnalytics;

  @override
  Future<void> initialize() async {
    if (firebaseApp.isInitialized == false) {
      throw StateError(
        "FirebaseApp must be initialized before FirebaseAuth",
      );
    }

    if (firebaseAnalytics.isInitialized == false) {
      throw StateError(
        "FirebaseAnalytics must be initialized before FirebaseAuth",
      );
    }

    await super.initialize();
  }
}

final class NoDependencies extends BaseInitializable {
  NoDependencies();
}

final class DependOnAnalytics extends BaseInitializable {
  DependOnAnalytics(this.firebaseAnalytics);

  final FirebaseAnalytics firebaseAnalytics;

  @override
  Future<void> initialize() async {
    if (firebaseAnalytics.isInitialized == false) {
      throw StateError(
        "FirebaseAnalytics must be initialized before DependOnAnalytics",
      );
    }

    await super.initialize();
  }
}

Future<void> _typeInferenceWorksCorrectly() async {
  final scope = Dependencies.pushScope(
    [
      Dependency(
        (scope) => "Hello ${scope.get<int>()}",
        dependsOn: [int],
      ),
      Dependency(
        (scope) => scope.get<String>().length.toDouble(),
        dependsOn: [String],
      ),
      Dependency((scope) => 3),
    ],
  );

  final initializedScope = await scope.build();

  expect(initializedScope.get<String>(), "Hello 3");
  expect(initializedScope.get<int>(), 3);
  expect(initializedScope.get<double>(), 7);
}
