part of '../dependencies.dart';

abstract base class ViewWidget<TViewModel extends ChangeNotifier>
    extends StatefulWidget {
  const ViewWidget({super.key});

  /// Creates and returns the ViewModel for this view.
  ///
  /// This factory method is responsible for instantiating the specific
  /// ViewModel associated with the current view. Developers must override this
  /// method to provide the appropriate ViewModel implementation for their
  /// specific use case.
  ///
  /// Returns:
  /// The [ViewModel] instance to be used in this view.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ViewModel viewModelFactory(Dependencies scope) {
  ///   final userRepository = scope.get<UserRepository>();
  ///
  ///   return UserProfileViewModel(userRepository);
  /// }
  /// ```
  @protected
  TViewModel viewModelFactory(Dependencies scope);

  /// Performs initial setup before the first frame is rendered. If the
  /// ViewModel is [IInitializable], this method will be triggered only
  /// AFTER the [IInitializable.initialize()] method is called (and it is
  /// async, so, in the  [buildWaiter] method, the view model is NOT yet
  /// initialized!).
  ///
  /// This method is called during the widget's `initState()` lifecycle stage,
  /// before the first frame is drawn. Use this method for early initialization
  /// tasks that do not require the widget to be fully rendered.
  ///
  /// Typical use cases include:
  /// - Basic configuration of widget properties
  /// - Initial state setup
  /// - Preliminary data preparation
  ///
  /// Note: Avoid complex or time-consuming operations in this method to
  /// prevent delaying the first frame rendering.
  @protected
  void initState(BuildContext context, TViewModel viewModel) {}

  /// Performs initialization after the first frame is rendered. If the
  /// ViewModel is `IInitializable`, it will be initialized at this point.
  ///
  /// This method is called using `addPostFrameCallback`, ensuring it runs
  /// after the first frame is completely drawn. Use this method for
  /// initialization tasks that require the widget to be fully laid out
  /// and rendered.
  ///
  /// Typical use cases include:
  /// - Complete ViewModel initialization
  /// - Loading data that might affect widget layout
  /// - Performing animations or interactions that need full widget context
  /// - Triggering complex data fetching or initialization processes
  ///
  /// Warning: This method runs after the initial render, so any changes
  /// made here will trigger a potential rebuild.
  @protected
  void initializeAfterFirstFrame(BuildContext context, TViewModel viewModel) {}

  /// Called when a dependency of this [State] object changes.
  ///
  /// For example, if the previous call to [build] referenced an
  /// [InheritedWidget] that later changed, the framework would call this
  /// method to notify this object about the change.
  ///
  /// This method is also called immediately after [initState]. It
  /// is safe to call [BuildContext.dependOnInheritedWidgetOfExactType] from
  /// this method.
  ///
  /// Subclasses rarely override this method because the framework always
  /// calls [build] after a dependency changes. Some subclasses do override
  /// this method because they need to do some expensive work (e.g., network
  /// fetches) when their dependencies change, and that work would be too
  /// expensive to do for every build.
  @protected
  void didChangeDependencies(BuildContext context, TViewModel viewModel) {}

  /// Called when this object is removed from the tree permanently.
  ///
  /// NOTE: YOU DO NOT NEED TO DISPOSE VIEWMODEL HERE!
  ///
  /// The framework calls this method when this [State] object will never
  /// build again.
  ///
  /// Subclasses should override this method to release any resources retained
  /// by this object (e.g., stop any active animations).
  ///
  /// {@macro flutter.widgets.State.initState}
  ///
  /// Implementations of this method should end with a call to the inherited
  /// method, as in `super.dispose()`.
  ///
  /// ## Caveats
  ///
  /// This method is _not_ invoked at times where a developer might otherwise
  /// expect it, such as application shutdown or dismissal via platform
  /// native methods.
  ///
  /// ### Application shutdown
  ///
  /// There is no way to predict when application shutdown will happen. For
  /// example, a user's battery could catch fire, or the user could drop the
  /// device into a swimming pool, or the operating system could unilaterally
  /// terminate the application process due to memory pressure.
  ///
  /// Applications are responsible for ensuring that they are well-behaved
  /// even in the face of a rapid unscheduled termination.
  ///
  /// To artificially cause the entire widget tree to be disposed, consider
  /// calling [runApp] with a widget such as [SizedBox.shrink].
  ///
  /// To listen for platform shutdown messages (and other lifecycle changes),
  /// consider the [AppLifecycleListener] API.
  ///
  /// {@macro flutter.widgets.runApp.dismissal}
  ///
  /// See the method used to bootstrap the app (e.g. [runApp] or [runWidget])
  /// for suggestions on how to release resources more eagerly.
  @protected
  void dispose(BuildContext context, TViewModel viewModel) {}

  /// Builds a waiting or loading state widget for the view.
  ///
  /// IMPORTANT: When the ViewModel is [IInitializable], the async
  /// initalization() method is being run while this widget is being
  /// displayed, to the ViewModel is **NOT** yet initialized at this moment!
  /// This widget is built ONLY when the ViewModel is [IInitializable], so
  /// the ViewModel here is NEVER initialized.
  ///
  /// This method is responsible for rendering the UI when the view is in a
  /// loading or waiting state. It provides a consistent and customizable
  /// loading experience across the application.
  ///
  /// Parameters:
  /// - [context]: The current BuildContext for widget rendering
  /// - [viewModel]: The ViewModel associated with this view, providing
  ///   access to loading state and potential additional configuration
  ///
  /// Returns:
  /// A [Widget] representing the loading/waiting state of the view
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildWaiter(BuildContext context, UserViewModel viewModel) {
  ///   return Center(
  ///     child: CircularProgressIndicator(),
  ///   );
  /// }
  /// ```
  ///
  /// Recommended Practices:
  /// - Keep the loading state simple and non-blocking
  /// - Provide visual feedback about ongoing processes
  /// - Optionally display progress or additional context
  @protected
  Widget buildWaiter(BuildContext context, TViewModel viewModel) {
    return const SizedBox.shrink();
  }

  /// Builds an error state widget when an exception occurs in the view.
  ///
  /// This method is crucial for gracefully handling and displaying
  /// errors that occur during view initialization or data loading.
  ///
  /// Parameters:
  /// - [context]: The current BuildContext for widget rendering
  /// - [error]: The specific error object that was thrown
  /// - [stackTrace]: The stack trace providing detailed error information
  /// - [viewModel]: The ViewModel associated with this view, allowing
  ///   for potential error-specific configurations
  ///
  /// Returns:
  /// A [Widget] representing the error state of the view
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildError(
  ///   BuildContext context,
  ///   Object error,
  ///   StackTrace stackTrace,
  ///   UserViewModel viewModel
  /// ) {
  ///   return Center(
  ///     child: Column(
  ///       mainAxisAlignment: MainAxisAlignment.center,
  ///       children: [
  ///         Text('An error occurred'),
  ///         Text(error.toString()),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// Recommended Practices:
  /// - Provide clear, user-friendly error messages
  /// - Log detailed error information for debugging
  /// - Offer potential recovery actions or retry mechanisms
  @protected
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    TViewModel viewModel,
  ) {
    return ErrorWidget(error);
  }

  /// Builds the primary content widget for the view.
  ///
  /// This method is the core rendering method for the view, responsible
  /// for creating the main UI when data is successfully loaded and
  /// the view is in a ready state.
  ///
  /// Parameters:
  /// - [context]: The current BuildContext for widget rendering
  /// - [viewModel]: The ViewModel associated with this view, providing
  ///   data and state for rendering
  ///
  /// Returns:
  /// A [Widget] representing the primary content of the view
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context, UserViewModel viewModel) {
  ///   return Scaffold(
  ///     appBar: AppBar(title: Text('User Profile')),
  ///     body: ListView(
  ///       children: [
  ///         Text(viewModel.userName),
  ///         Text(viewModel.userEmail),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// Recommended Practices:
  /// - Keep the method focused on rendering
  /// - Delegate complex logic to the ViewModel
  /// - Ensure the widget is responsive and adapts to different screen sizes
  @protected
  Widget build(BuildContext context, TViewModel viewModel);

  @override
  State<ViewWidget<TViewModel>> createState() => _ViewWidgetState<TViewModel>();
}

final class _ViewWidgetState<TViewModel extends ChangeNotifier>
    extends State<ViewWidget<TViewModel>> {
  final _logger = Logger("${TViewModel}");
  late final TViewModel _viewModel;
  Future<void>? _initializer;

  Future<void> _initialize(
    BuildContext context,
    IInitializable initializable,
  ) async {
    await initializable.initialize();

    if (context.mounted) {
      widget.initState(context, _viewModel);
    }
  }

  @override
  void initState() {
    _logger.log(Level.FINE, "Initializing");

    _viewModel = widget.viewModelFactory(Dependencies.currentScope);

    if (_viewModel case final IInitializable initializable) {
      _initializer = _initialize(context, initializable);
    } else {
      widget.initState(context, _viewModel);
    }

    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (delta) {
        _logger.log(
          Level.FINE,
          "Post initializing (delta: ${delta.inMilliseconds})",
        );

        widget.initializeAfterFirstFrame(context, _viewModel);
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
    final viewModelWidget = ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ViewModel<TViewModel>(
        viewModel: _viewModel,
        child: Builder(
          builder: (context) => widget.build(context, _viewModel),
        ),
      ),
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
