part of '../dependencies.dart';

/// A manager for dependency injection scopes, allowing dependencies to be
/// dynamically registered, accessed, and disposed of within a defined scope.
///
/// The [Dependencies] class supports scoped dependency management, enabling
/// dynamic registration of factories and resource cleanup.
final class Dependencies {
  Dependencies._(this._dependencies);

  static final _scopes = <Dependencies>[];
  static final _logger = Logger("Dependencies");

  /// Pushes a new dependency scope to the stack and initializes it with
  /// the provided factories.
  ///
  /// - [factories]: A list of dependencies to register in the new scope.
  ///
  /// Returns the created [Dependencies] instance, which represents the active
  /// scope.

  static Dependencies pushScope(
    List<Dependency<dynamic>> factories,
  ) {
    _logger.fine("Pushing new scope with ${factories.length} dependencies");

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

    _logger.fine("Popping scope");
    _scopes.removeLast().dispose();
  }

  final List<Dependency<dynamic>> _dependencies;
  final _instances = <String, MapEntry<Dependencies, dynamic>>{};

  /// Registers a new factory in the current scope for creating instances of
  /// type [T].
  ///
  /// The factory will be invoked each time an instance of [T] is required.
  ///
  /// - [factory]: A callback function that creates an instance of type [T].
  ///
  /// If the type is already registered, the factory will be replaced.
  void registerFactory<T>(T Function(Dependencies scope) factory) {
    _logger.info("Registering ${T}");
    _dependencies.add(factory as Dependency<dynamic>);
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
      _logger.info("Disposing ${instance.runtimeType}");
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
    final graph = <String, List<String>>{};
    final inDegrees = <String, int>{};

    for (final dep in _dependencies) {
      final typeName = dep.getTypeName();

      graph[typeName] = [];
      inDegrees[typeName] = 0;
    }

    for (final dep in _dependencies) {
      final typeName = dep.getTypeName();

      for (final dependency in dep.dependsOn) {
        final dependencyName = dependency.toString();

        if (graph.containsKey(dependencyName) == false) {
          throw StateError(
            "Dependency '$dependency' not found for '${typeName}'.",
          );
        }

        graph[dependencyName]!.add(typeName);
        inDegrees[typeName] = (inDegrees[typeName] ?? 0) + 1;
      }
    }

    final queue = Queue<String>();
    final sorted = <Dependency<dynamic>>[];

    for (final entry in inDegrees.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      final currentDep = _dependencies.firstWhere(
        (dep) => dep.getTypeName() == current,
      );

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

    final preInitializers = <Future<void>>[];
    final posInitializers = <Future<void>>[];
    final initializedDependencies = <String>[];

    for (final dependency in sorted) {
      final typeName = dependency.getTypeName();

      _logger.info("Instantiating ${typeName}");

      final instance = dependency.factory(this);

      if (instance is IInitializable) {
        Future<void> initializer() async {
          await instance.initialize();
          _logger.info("${typeName} initialized");
        }

        if (dependency.dependsOn.isEmpty) {
          preInitializers.add(initializer());
          initializedDependencies.add(typeName);
        } else {
          var isPos = false;

          for (final dependency in dependency.dependsOn) {
            if (initializedDependencies.contains(dependency.toString()) ==
                false) {
              isPos = true;
              break;
            }
          }

          if (isPos) {
            posInitializers.add(initializer());
          } else {
            preInitializers.add(initializer());
          }
        }
      }

      _instances[typeName] = MapEntry(this, instance);
    }

    _logger.info("Initializing ${preInitializers.length} pre-dependencies");
    await Future.wait(preInitializers);

    _logger.info("Initializing ${posInitializers.length} pos-dependencies");
    await Future.wait(posInitializers);

    return this;
  }

  T call<T>() => get<T>();

  /// Retrieves an instance of type [T] from the current scope.
  T get<T>() {
    return _get<T>(_scopes.length - 1);
  }

  T _get<T>(int scopeIndex) {
    final scope = _scopes[scopeIndex];
    final instance = scope._instances[T.toString()];

    if (instance != null) {
      return instance.value as T;
    }

    if (scopeIndex == 0) {
      throw Exception("There is no registration of dependency ${T}");
    }

    return _get<T>(scopeIndex - 1);
  }
}
