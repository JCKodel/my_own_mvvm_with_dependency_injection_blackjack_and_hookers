part of '../dependencies.dart';

/// A widget that initializes and manages a list of [Dependency] objects,
/// and provides them to its descendant widgets.
///
/// The [DependenciesBuilder] ensures that the given dependencies are loaded
/// before rendering its child widgets. It offers a way to build a widget tree
/// once all dependencies are ready, and optionally display a placeholder while
/// waiting for the dependencies to load.
final class DependenciesBuilder extends StatefulWidget {
  /// Creates a [DependenciesBuilder].
  ///
  /// - [dependencies]: A list of dependencies to be managed and provided
  ///   to descendant widgets.
  /// - [builder]: A callback to build the widget tree when all dependencies
  ///   are loaded.
  /// - [waitingBuilder]: (Optional) A callback to build a widget tree
  ///   displayed while waiting for dependencies to load.
  const DependenciesBuilder({
    required this.dependencies,
    required this.builder,
    this.waitingBuilder,
    super.key,
  });

  /// The list of dependencies that need to be loaded.
  final List<Dependency<Object>> dependencies;

  /// A callback that builds the widget tree after all dependencies are loaded.
  ///
  /// - [context]: The current build context.
  /// - [scope]: Provides access to the resolved dependencies.
  final Widget Function(BuildContext context, Dependencies scope) builder;

  /// (Optional) A callback that builds the widget tree while dependencies are
  /// loading.
  ///
  /// If null, nothing is displayed during the loading phase.
  ///
  /// - [context]: The current build context.
  final Widget Function(BuildContext context)? waitingBuilder;

  @override
  State<DependenciesBuilder> createState() => _DependenciesBuilderState();
}

final class _DependenciesBuilderState extends State<DependenciesBuilder> {
  Future<Dependencies>? _initializer;
  Dependencies? _dependencies;

  @override
  void initState() {
    super.initState();

    final newScope = Dependencies.pushScope(widget.dependencies);

    _initializer = newScope.build();
  }

  @override
  void dispose() {
    super.dispose();
    _dependencies?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dependencies>(
      future: _initializer,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.waitingBuilder != null
              ? widget.waitingBuilder!(context)
              : const SizedBox.shrink();
        }

        _dependencies = snapshot.data;

        return Scope(
          scope: _dependencies!,
          child: widget.builder(context, _dependencies!),
        );
      },
    );
  }
}
