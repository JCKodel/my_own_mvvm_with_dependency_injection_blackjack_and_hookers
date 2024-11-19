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
