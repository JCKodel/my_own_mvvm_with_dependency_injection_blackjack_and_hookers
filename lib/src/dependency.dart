part of '../dependencies.dart';

/// A class that represents a dependency in the dependency injection system.
final class Dependency<T> {
  /// Creates a [Dependency] with the given factory and dependencies.
  ///
  /// - [factory]: A callback function that creates an instance of type [T].
  /// - [dependsOn]: (Optional) A list of types that the factory depends on.
  const Dependency(this.factory, {this.dependsOn = const []});

  /// The factory callback that creates an instance of type [T].
  final T Function(Dependencies scope) factory;

  /// (Optional) A list of types that the factory depends on.
  final List<Type> dependsOn;

  /// The type of the dependency.
  Type get type => T;
}
