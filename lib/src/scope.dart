part of '../dependencies.dart';

/// A widget that provides a [Dependencies] instance to its descendant widgets.
///
/// The [Scope] widget is used to pass a [Dependencies] instance to its
/// descendant widgets. It is typically used to provide a scoped dependency
/// injection system to a widget tree. The [Dependencies] instance is available
/// to all descendant widgets via the [Scope.of] method.
final class Scope extends InheritedWidget {
  /// Creates a [Scope] widget.
  ///
  /// - [child]: The widget that will be provided with the [Dependencies]
  /// instance.
  /// - [scope]: The [Dependencies] instance to be provided to the descendant
  /// widgets.
  /// - [key]: (Optional) A key that uniquely identifies the widget.
  const Scope({
    required super.child,
    required this.scope,
    super.key,
  });

  /// The [Dependencies] instance provided to the descendant widgets.
  final Dependencies scope;

  @override
  bool updateShouldNotify(Scope oldWidget) {
    return scope != oldWidget.scope;
  }

  /// Retrieves the [Dependencies] instance from the current build context.
  ///
  /// - [context]: The current build context.
  ///
  /// Returns the [Dependencies] instance provided by the [Scope] widget,
  /// which is created automatically by the [DependenciesBuilder] widget and
  /// the [ViewModelStatelessWidget<T>].
  static Dependencies of(BuildContext context) {
    final dependencies = context.dependOnInheritedWidgetOfExactType<Scope>();

    return dependencies!.scope;
  }
}
