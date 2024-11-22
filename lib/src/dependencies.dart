part of '../dependencies.dart';

/// A manager for dependency injection scopes, allowing dependencies to be
/// dynamically registered, accessed, and disposed of within a defined scope.
///
/// The [Dependencies] class supports scoped dependency management, enabling
/// dynamic registration of factories and resource cleanup.
final class Dependencies {
  Dependencies._(this._dependencies);

  static final _scopes = <Dependencies>[];

  /// Pushes a new dependency scope to the stack and initializes it with
  /// the provided factories.
  ///
  /// - [factories]: A list of dependencies to register in the new scope.
  ///
  /// Returns the created [Dependencies] instance, which represents the active
  /// scope.

  static Dependencies pushScope(
    List<Dependency<Object>> factories,
  ) {
    final scope = Dependencies._(factories);

    _scopes.add(scope);

    return scope;
  }

  /// Retrieves the current active dependency scope.
  ///
  /// Throws an [StateError] if no scopes are currently active.
  static Dependencies get currentScope => _scopes.last;

  /// Removes the current dependency scope from the stack.
  ///
  /// Throws an [StateError] if there is no active scope to remove.
  static void popScope() {
    if (_scopes.isEmpty) {
      throw StateError("There is no scope to pop");
    }

    _scopes.removeLast().dispose();
  }

  final List<Dependency<Object>> _dependencies;
  final _instances = <Type, MapEntry<Dependencies, Object>>{};

  /// Registers a new factory in the current scope for creating instances of
  /// type [T].
  ///
  /// The factory will be invoked each time an instance of [T] is required.
  ///
  /// - [factory]: A callback function that creates an instance of type [T].
  ///
  /// If the type is already registered, the factory will be replaced.
  void registerFactory<T>(T Function(Dependencies scope) factory) {
    log("Registering", name: "${T}");
    _dependencies.add(factory as Dependency<Object>);
  }

  /// Disposes of all dependencies in the current scope.
  ///
  /// This method should be called when the scope is no longer needed to ensure
  /// proper resource cleanup.
  ///
  /// All registered factories that implements [IDisposable] will be disposed
  /// as well.
  void dispose() {
    void writeLog(Object instance) {
      log("Disposing", name: "${instance.runtimeType}");
    }

    for (final entry in _instances.values) {
      if (entry.key != this) {
        continue;
      }

      final instance = entry.value;

      if (instance is IDisposable) {
        writeLog(instance);
        instance.dispose();
      } else if (instance is ChangeNotifier) {
        writeLog(instance);
        instance.dispose();
      }
    }
  }

  /// Builds and returns an instance of type [T] from the registered factories,
  /// initializing all types that implements [IInitializable].
  ///
  /// Factories are ordered in a topological order, ensuring that dependencies
  /// are resolved before the instance is created.
  ///
  /// - [T]: The type of the instance to build.
  ///
  /// Throws an [StateError] if no factory is registered for the type [T] or
  /// if a cyclic dependency is detected.
  Future<Dependencies> build() async {
    final graph = <Type, List<Type>>{};
    final inDegrees = <Type, int>{};

    for (final dep in _dependencies) {
      graph[dep.type] = [];
      inDegrees[dep.type] = 0;
    }

    for (final dep in _dependencies) {
      for (final dependency in dep.dependsOn) {
        if (graph.containsKey(dependency) == false) {
          throw StateError(
            "Dependency '$dependency' not found for '${dep.type}'.",
          );
        }

        graph[dependency]!.add(dep.type);
        inDegrees[dep.type] = (inDegrees[dep.type] ?? 0) + 1;
      }
    }

    final queue = Queue<Type>();
    final sorted = <Dependency<Object>>[];

    for (final entry in inDegrees.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentDep = _dependencies.firstWhere((dep) => dep.type == current);

      sorted.add(currentDep);

      for (final neighbor in graph[current]!) {
        inDegrees[neighbor] = inDegrees[neighbor]! - 1;

        if (inDegrees[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    if (sorted.length != _dependencies.length) {
      throw StateError("Cyclic dependency detected!");
    }

    for (final dependency in sorted) {
      log("Instantiating", name: "${dependency.type}");

      final instance = dependency.factory(this);

      if (instance is IInitializable) {
        log("Initializing", name: "${dependency.type}");
        await instance.initialize();
      }

      _instances[dependency.type] = MapEntry(this, instance);
    }

    return this;
  }

  T call<T>() => get<T>();

  /// Retrieves an instance of type [T] from the current scope.
  T get<T>() {
    return _get<T>(_scopes.length - 1);
  }

  T _get<T>(int scopeIndex) {
    final scope = _scopes[scopeIndex];
    final instance = scope._instances[T];

    if (instance != null) {
      return instance as T;
    }

    if (scopeIndex == 0) {
      throw Exception("There is no registration of dependency ${T}");
    }

    return _get<T>(scopeIndex - 1);
  }
}
