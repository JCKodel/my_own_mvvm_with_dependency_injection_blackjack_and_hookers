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

  Logger.root.onRecord.listen((record) {
    log.add(record.message);
  });

  final scope = await Dependencies.pushScope(
    [
      Dependency<DependsOnNoDependenciesB>(
        (scope) => DependsOnNoDependenciesB(
          scope.get<NoDependenciesA>(),
          scope.get<NoDependenciesB>(),
        ),
        dependsOn: [NoDependenciesA, NoDependenciesB],
      ),
      Dependency<DependsOnDependsOnNoDependenciesAB>(
        (scope) => DependsOnDependsOnNoDependenciesAB(
          scope.get<DependsOnNoDependenciesA>(),
          scope.get<DependsOnNoDependenciesB>(),
        ),
        dependsOn: [DependsOnNoDependenciesA, DependsOnNoDependenciesB],
      ),
      Dependency<DependsOnNoDependenciesA>(
        (scope) => DependsOnNoDependenciesA(scope.get<NoDependenciesA>()),
        dependsOn: [NoDependenciesA],
      ),
      Dependency<NoDependenciesB>(
        (scope) => NoDependenciesB(),
      ),
      Dependency<NoDependenciesA>(
        (scope) => NoDependenciesA(),
      ),
    ],
  ).build();

  expect(scope.get<DependsOnNoDependenciesA>().order, 4);
  expect(scope.get<DependsOnNoDependenciesB>().order, 3);
  expect(scope.get<DependsOnDependsOnNoDependenciesAB>().order, 5);
  expect(
    log,
    <String>[
      'Instantiating NoDependenciesB',
      'Instantiating NoDependenciesA',
      'Instantiating DependsOnNoDependenciesB',
      'Instantiating DependsOnNoDependenciesA',
      'Instantiating DependsOnDependsOnNoDependenciesAB',
      'Initializing 4 pre-dependencies',
      'NoDependenciesB initialized',
      'NoDependenciesA initialized',
      'DependsOnNoDependenciesB initialized',
      'DependsOnNoDependenciesA initialized',
      'Initializing 1 pos-dependencies',
      'DependsOnDependsOnNoDependenciesAB initialized',
    ],
  );
}

int _order = 0;

final class NoDependenciesA implements IInitializable {
  NoDependenciesA();

  @override
  Future<void> initialize() async {
    order = ++_order;
  }

  int order = 0;
}

final class NoDependenciesB implements IInitializable {
  NoDependenciesB();

  @override
  Future<void> initialize() async {
    order = ++_order;
  }

  int order = 0;
}

final class DependsOnNoDependenciesA implements IInitializable {
  DependsOnNoDependenciesA(this.noDependenciesA);

  final NoDependenciesA noDependenciesA;
  int order = 0;

  @override
  Future<void> initialize() async {
    order = ++_order;
  }
}

final class DependsOnNoDependenciesB implements IInitializable {
  DependsOnNoDependenciesB(this.noDependenciesA, this.noDependenciesB);

  final NoDependenciesA noDependenciesA;
  final NoDependenciesB noDependenciesB;
  int order = 0;

  @override
  Future<void> initialize() async {
    order = ++_order;
  }
}

final class DependsOnDependsOnNoDependenciesAB implements IInitializable {
  DependsOnDependsOnNoDependenciesAB(
    this.dependsOnNoDependenciesA,
    this.dependsOnNoDependenciesB,
  );

  final DependsOnNoDependenciesA dependsOnNoDependenciesA;
  final DependsOnNoDependenciesB dependsOnNoDependenciesB;
  int order = 0;

  @override
  Future<void> initialize() async {
    order = ++_order;
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
