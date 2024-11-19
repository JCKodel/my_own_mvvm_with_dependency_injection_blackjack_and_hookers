# My own MVVM with Dependency Injection, Blackjack and Hookers

![image](https://kagi.com/proxy/3p1j1.jpg?c=kPRFzVRYJ3F-DHkv6vwSyo6yJrOaaUPxu7I4t2jBzblNnBvB47WswF8oshEqx9xq0EvIDpvq587ecyBv1JFODA%3D%3D)

1) Divide your classes into business logic and infrastructure (for instance: FirebaseAuth is infrastructure).

2) Whenever appropriate in the widget tree, use the [DependenciesBuilder] widget to initialize the infrastructure and provide it to the widget tree:

```dart
DependenciesBuilder(
  dependencies: [
    Dependency<IAuthProvider>(
      (scope) => FirebaseAuthProvider(),
    ),
    Dependency<PowersyncDatabase>(
      (scope) => PowersyncDatabase(
        scope<IAuthProvider>(),
        scope<IHttpClientProvider>(),
      ),
      dependsOn: [IAuthProvider, IHttpClientProvider],
    ),
    Dependency<IHttpClientProvider>(
      (scope) => NativeHttpClientProvider(),
    ),
    Dependency<IAuthDatabaseProvider>(
      (scope) => PowersyncAuthDatabaseProvider(scope<PowersyncDatabase>()),
      dependsOn: [PowersyncDatabase],
    ),
    Dependency<AuthModel>(
      (scope) => AuthModel(
        scope<IAuthDatabaseProvider>(),
        scope<IAuthProvider>(),
        scope<IDeviceInfoProvider>(),
        scope<IBlurHashProvider>(),
      ),
      dependsOn: [
        IAuthDatabaseProvider,
        IAuthProvider,
        IDeviceInfoProvider,
        IBlurHashProvider,
      ],
    ),
    Dependency<IDeviceInfoProvider>(
      (scope) => DeviceInfoProvider(),
    ),
    Dependency<IBlurHashProvider>(
      (scope) => FFIBlurHashProvider(),
    ),
  ],
  builder: (context, scope) => const MainApp(),
);
```

Notice that each dependency can depend on other dependencies. There is no need to worry about registration order, as the [DependenciesBuilder] will automatically resolve the dependencies in the correct order.

Dependencies that implement [IInitializable] will be initialized automatically when the [DependenciesBuilder] is built (which happens when the widget tree is built).

When a [DependencyBuilder] gets out of scope, it will be disposed automatically, 
along with any dependencies that implement [IDisposable]. [ChangeNotifier.dispose] will also be called on dispose.

3) Use the [ViewModelStatelessWidget] class to create a stateless widget that requires a view model:

```dart
final class MainApp extends ViewModelStatelessWidget<MainAppViewModel> {
  const MainApp({super.key});

  @override
  MainAppViewModel Function(Dependencies scope) get factory =>
      (scope) => MainAppViewModel(scope<AuthModel>());

  @override
  Widget buildView(BuildContext context, MainAppViewModel viewModel) {
    return MaterialApp(
      home: viewModel.isAuthenticated ? const HomeView() : const LoginView(),
    );
  }
}
```

In this class, you will have access to the [MainAppViewModel] instance, that was
created using the dependencies registered in the [DependenciesBuilder].

The ViewModel is just a simple [ChangeNotifier] class that uses models (business logic):

```dart
final class MainAppViewModel extends ChangeNotifier
    implements IInitializable, IDisposable {
  MainAppViewModel(AuthModel authModel) : _authModel = authModel;

  final AuthModel _authModel;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  StreamSubscription<bool>? _isAuthenticatedStreamSubscription;

  @override
  Future<void> initialize() async {
    _isAuthenticatedStreamSubscription =
        _authModel.isAuthenticatedStream.listen(_onAuthChanged);

    _isAuthenticated = _authModel.isAuthenticated;
    logDebug("IsAuthenticated = ${isAuthenticated}");
  }

  @override
  void dispose() {
    super.dispose();
    _isAuthenticatedStreamSubscription?.cancel();
  }

  void _onAuthChanged(bool isAuthenticated) {
    if (_isAuthenticated == isAuthenticated) {
      return;
    }

    logDebug("AuthChanging to ${isAuthenticated}");
    _isAuthenticated = isAuthenticated;
    notifyListeners();
  }

  void signOut() {
    logDebug("Signing out");
    _authModel.signOut();
  }
}

```

4) Business logic is just a simple class that uses the infrastructure required
by its contracts (so it is testable and you can easily change a dependency if 
you need so (for instance, change FirebaseAuth to Auth-0)): 

```dart
final class AuthModel {
  AuthModel(
    IAuthDatabaseProvider authRepository,
    IAuthProvider authProviderModel,
    IDeviceInfoProvider deviceInfoModel,
    IBlurHashProvider blurHashModel,
  )   : _authRepository = authRepository,
        _authProviderModel = authProviderModel,
        _deviceInfoModel = deviceInfoModel,
        _blurHashModel = blurHashModel;

  final IAuthDatabaseProvider _authRepository;
  final IAuthProvider _authProviderModel;
  final IDeviceInfoProvider _deviceInfoModel;
  final IBlurHashProvider _blurHashModel;

  bool get isAuthenticated => _authProviderModel.isAuthenticated;

  Stream<bool> get isAuthenticatedStream =>
      _authProviderModel.isAuthenticatedStream;

  Future<void> initialize() async {
    if (isAuthenticated == false) {
      return;
    }

    final token = await _authProviderModel.getUserToken();

    switch (token) {
      case None<UserToken>():
        signOut();
      case Some<UserToken>():
        await _getPrincipalFromRepository(token.value.userId);
    }
  }

  Future<SignInResult> signInWithApple() async {
    return _signIn(_authProviderModel.signInWithApple);
  }

  Future<SignInResult> signInWithGoogle() async {
    return _signIn(_authProviderModel.signInWithGoogle);
  }

  Future<SignInResult> _signIn(
    Future<SignInResult> Function() signInHandler,
  ) async {
    final signInResult = await signInHandler();

    logInfo("Sign in result: ${signInResult}");

    if (signInResult is! SuccessSignInResult) {
      return signInResult;
    }

    return _getPrincipalFromRepository(signInResult.userId);
  }

  Future<SignInResult> _getPrincipalFromRepository(String userId) async {
    final result =
        await _authRepository.initializePreviouslyAuthenticatedPrincipal(
      userId,
    );

    return switch (result) {
      OpenRepositoryFailureQueryResult<Principal>() =>
        ExceptionSignInResult(result.failure, StackTrace.current),
      ExceptionQueryResult<Principal>() => ExceptionSignInResult(
          result.exception,
          result.stackTrace,
        ),
      EmptyQueryResult<Principal>() => _getPrincipalFromAuthProvider(),
      SuccessQueryResult<Principal>() => _sanitizePrincipal(result.data),
    };
  }

  Future<SignInResult> _getPrincipalFromAuthProvider() async {
    final result = await _authProviderModel.createPrincipalFromCurrentUser();

    return switch (result) {
      Some<Principal>() => _sanitizePrincipal(result.value),
      None<Principal>() => ExceptionSignInResult(
          StateError("User is unauthenticated in auth provider"),
          StackTrace.current,
        ),
    };
  }

  Future<SignInResult> _sanitizePrincipal(Principal principal) async {
    logInfo("Sanitizing principal");

    if (principal.email.isEmpty) {
      logError(
        "No e-mail provided",
        ArgumentError.notNull("email"),
        StackTrace.current,
      );

      return const EmptyEmailSignInResult();
    }

    if (principal.name.isEmpty) {
      principal = principal.copyWith(
        name: principal.email.split("@").first.split("+").first,
      );
    }

    return _generateAvatarBlurHash(principal);
  }

  Future<SignInResult> _generateAvatarBlurHash(Principal principal) async {
    if (principal.avatarUrl.isEmpty) {
      return _getDeviceInfo(principal.copyWith(avatarBlurHash: ""));
    }

    final result = await _blurHashModel.generateRemoteImageHash(
      principal.avatarUrl,
    );

    switch (result) {
      case Some():
        return _getDeviceInfo(
          principal.copyWith(avatarBlurHash: result.value),
        );
      case None():
        return _getDeviceInfo(principal);
    }
  }

  Future<SignInResult> _getDeviceInfo(Principal principal) async {
    final result = await _deviceInfoModel.getDeviceInfo();

    return switch (result) {
      Some() => _persistSignInData(principal, result.value),
      None() => ExceptionSignInResult(
          ArgumentError.notNull("deviceInfo"),
          StackTrace.current,
        ),
    };
  }

  Future<SignInResult> _persistSignInData(
    Principal principal,
    DeviceInfo deviceInfo,
  ) async {
    final repositoryResult = await _authRepository.persistSignInData(
      principal,
      deviceInfo,
    );

    if (repositoryResult is! SuccessMutationResult) {
      return ExceptionSignInResult(repositoryResult, StackTrace.current);
    }

    final providerResult = await _authProviderModel.persistSignInData(
      principal,
    );

    if (providerResult is! SuccessMutationResult) {
      return ExceptionSignInResult(providerResult, StackTrace.current);
    }

    return SuccessSignInResult(principal.id);
  }

  Future<Option<UserToken>> getUserToken() => _authProviderModel.getUserToken();

  void signOut() {
    _authProviderModel.signOut();
    _authRepository.close();
  }
}
```

5) Done. Other then [DependenciesBuilder] and [ViewModelStatelessWidget], there is no framework dependency here, you can ditch us whenever you want. No need to learn a new framework. You are versed in  BLoC but your frenemy is versed in Riverpod? You both can be fired together by someone who keeps the things simpler.