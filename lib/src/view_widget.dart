import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:logging/logging.dart';

import '../dependencies.dart';

abstract base class ViewWidget<TViewModel extends ChangeNotifier>
    extends StatefulWidget {
  const ViewWidget({super.key});

  @protected
  TViewModel buildViewModel(Dependencies scope, Logger logger);

  @protected
  void initState(BuildContext context, TViewModel viewModel) {}

  @protected
  void postInitState(BuildContext context, TViewModel viewModel) {}

  @protected
  void didChangeDependencies(BuildContext context, TViewModel viewModel) {}

  @protected
  void dispose(BuildContext context, TViewModel viewModel) {}

  @protected
  Widget buildWaiter(BuildContext context, TViewModel viewModel) {
    return const SizedBox.shrink();
  }

  @protected
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    TViewModel viewModel,
  ) {
    return ErrorWidget(error);
  }

  @protected
  Widget build(BuildContext context, TViewModel viewModel);

  @override
  State<ViewWidget<TViewModel>> createState() => _ViewWidgetState<TViewModel>();
}

final class _ViewWidgetState<TViewModel extends ChangeNotifier>
    extends State<ViewWidget<TViewModel>> {
  final _logger = Logger("${TViewModel}");
  late final TViewModel _viewModel;
  late final Future<void>? _initializer;

  @override
  void initState() {
    _logger.log(Level.FINE, "Initializing");

    _viewModel = widget.buildViewModel(Dependencies.currentScope, _logger);

    if (_viewModel case final IInitializable initializable) {
      _initializer = initializable.initialize();
    }

    super.initState();
    widget.initState(context, _viewModel);

    SchedulerBinding.instance.addPostFrameCallback(
      (delta) {
        _logger.log(
          Level.FINE,
          "Post initializing (delta: ${delta.inMilliseconds})",
        );

        widget.postInitState(context, _viewModel);
      },
    );
  }

  @override
  void didChangeDependencies() {
    _logger.log(Level.FINE, "Dependencies changed");
    super.didChangeDependencies();
    widget.didChangeDependencies(context, _viewModel);
  }

  @override
  void dispose() {
    _logger.log(Level.FINE, "Disposing");
    super.dispose();
    widget.dispose(context, _viewModel);
  }

  @override
  Widget build(BuildContext context) {
    final viewModelWidget = ViewModel<TViewModel>(
      viewModel: _viewModel,
      child: widget.build(context, _viewModel),
    );

    if (_initializer == null) {
      return viewModelWidget;
    }

    return FutureBuilder<void>(
      future: _initializer,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.log(
            Level.SEVERE,
            "StreamBuilder error",
            snapshot.error,
            snapshot.stackTrace,
          );

          return widget.buildError(
            context,
            snapshot.error!,
            snapshot.stackTrace!,
            _viewModel,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          _logger.log(Level.FINE, "Waiting");
          return widget.buildWaiter(context, _viewModel);
        }

        return viewModelWidget;
      },
    );
  }
}

final class ViewModel<TViewModel extends ChangeNotifier>
    extends InheritedWidget {
  const ViewModel({
    required this.viewModel,
    required super.child,
    super.key,
  });

  final TViewModel viewModel;

  @override
  bool updateShouldNotify(ViewModel<TViewModel> oldWidget) =>
      oldWidget.viewModel != viewModel;

  static TViewModel read<TViewModel extends ChangeNotifier>(
    BuildContext context,
  ) {
    final viewModel =
        context.findAncestorWidgetOfExactType<ViewModel<TViewModel>>();

    return viewModel!.viewModel;
  }
}
