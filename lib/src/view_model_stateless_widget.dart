part of '../dependencies.dart';

/// A base class for stateless widgets that require a view model.
///
/// The [ViewModelStatelessWidget] class is a base class for stateless widgets
/// that require a view model. It provides a factory method to create the view
/// model, and a waiting builder to display a placeholder while the view model
/// is being initialized.
///
/// The [ViewModelStatelessWidget] class is typically used as a base class for
/// stateless widgets that require a view model. The factory method is used to
/// create the view model, and the waiting builder is used to display a
/// placeholder while the view model is being initialized.
abstract base class ViewModelStatelessWidget<T extends ChangeNotifier>
    extends StatelessWidget {
  /// Creates a [ViewModelStatelessWidget].
  ///
  /// - [key]: (Optional) A key that uniquely identifies the widget.
  const ViewModelStatelessWidget({super.key});

  /// The factory method that creates the view model.
  ///
  /// - [scope]: The [Dependencies] instance provided by the [Scope] widget.
  ///
  /// Returns the view model instance.
  T Function(Dependencies scope) get factory;

  /// (Optional) A callback that builds the widget tree while the view model is
  /// being initialized.
  ///
  /// If null, nothing is displayed during the loading phase.
  ///
  /// - [context]: The current build context.
  Widget Function(BuildContext context) get waitingBuilder =>
      (context) => const SizedBox.shrink();

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return _ViewModel(
      factory: factory,
      waitingBuilder: waitingBuilder,
      builder: buildView,
    );
  }

  /// This method replaces the [build] method in the [ViewModelStatelessWidget]
  /// class. It is called when the view model is ready to be used.
  ///
  /// - [context]: The current build context.
  /// - [viewModel]: The view model instance.
  Widget buildView(BuildContext context, T viewModel);
}

final class _ViewModel<T extends ChangeNotifier> extends StatelessWidget {
  const _ViewModel({
    required this.factory,
    required this.builder,
    this.waitingBuilder,
    super.key,
  });

  final T Function(Dependencies scope) factory;
  final Widget Function(BuildContext context, T viewModel) builder;
  final Widget Function(BuildContext context)? waitingBuilder;

  @override
  Widget build(BuildContext context) {
    return DependenciesBuilder(
      dependencies: [Dependency<T>(factory)],
      waitingBuilder: waitingBuilder,
      builder: (context, dependencies) {
        final instance = dependencies.get<T>();

        return ListenableBuilder(
          listenable: instance,
          builder: (context, child) => builder(context, instance),
        );
      },
    );
  }
}
