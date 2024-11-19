part of '../dependencies.dart';

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
