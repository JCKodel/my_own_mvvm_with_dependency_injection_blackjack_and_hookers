# My own MVVM with Dependency Injection, Blackjack and Hookers

![image](https://kagi.com/proxy/3p1j1.jpg?c=kPRFzVRYJ3F-DHkv6vwSyo6yJrOaaUPxu7I4t2jBzblNnBvB47WswF8oshEqx9xq0EvIDpvq587ecyBv1JFODA%3D%3D)

# Dependency Injection Framework for Flutter: Clean Architecture Made Simple

## Why Separation of Concerns Matters

Separation of Concerns (SoC) is a fundamental design principle that transforms complex software development into a manageable, scalable process. By breaking down your application into distinct, focused modules, you achieve:

- **Modularity**: Each component has a single, well-defined responsibility
- **Maintainability**: Changes in one module minimally impact others
- **Testability**: Individual components can be tested in isolation
- **Scalability**: New features can be added with minimal friction

## ViewModel: The Business Logic Coordinator

The ViewModel acts as a **pure business logic coordinator** that:
- Transforms data for UI presentation
- Manages UI state
- Delegates I/O operations to specialized providers
- Communicates only through interfaces

**Key Principles:**
- All dependencies are singletons within its own scope
- You can have multiple scopes that will be disposed when the widget tree is disposed, along with all dependencies that belongs to the current scope (that's why your dependencies can implement `IDisposable`)
- Never performs direct I/O operations
- Depends on abstractions, not concrete implementations
- Maintains a clean separation between business logic and data sources

**What goes in the ViewModel?**
- You should be able to create and test the ViewModel in Dart alone, without any Flutter classes, widgets or contexts.
- It has a `BuildContext`, some Flutter class, such as Material, Widget, Cupertino, etc.? It goes in the View.
- You can build a class with business logic that is used by multiple view models, if you have such shared logic (think of `signOut` for example: it can be used by multiple view models). Let's call those classes `Service`. In this case, the golden rule is:  Services have `const` constructors (so they cannot have any state in it). ViewModels are always non-const (because they inherit `ChangeNotifier`).

## Dependency Injection: Decoupling Your Application

**Dependencies** are external services your application requires:
- Authentication services
- Database connections
- File system access
- Network APIs
- Platform-specific plugins

Our dependency injection framework allows you to:
- Inject dependencies at runtime
- Swap implementations easily
- Create modular, testable code

## Simple Authentication Example

```dart
// Providers are like operating system drivers: they implement
// something, like API access, authentication (through, for 
// instance, FirebaseAuth), storage, etc.
//
// Any ViewModel or dependency that implements `IInitializable`
// will be initialized when the dependencies are built.
//
// The ViewModel only have a contract, the interface to communicate
// with those providers:
abstract interface class IAuthenticationProvider
  implements IInitializable {
  Future<bool> authenticate(String username, String password);
}

// The view model is the business logic that uses your providers
// It is made for one view
//
// If you have common logic that you want to share between view
// models, such as `signOut`, you can create a class that is
// responsible to hold the business logic and binding the
// providers with the view model.
final class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authProvider);

  final AuthenticationProvider _authProvider;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String username, String password) async {
    _isAuthenticated = await _authProvider.authenticate(username, password);
    notifyListeners();
  }
}

// A widget that creates and manages the ViewModel. It contains
// some nice methods, such as initState or dispose.
final class AuthenticationView extends ViewWidget<AuthViewModel> {
  const AuthenticationView({super.key});

  @override
  AuthViewModel viewModelFactory(Dependencies scope) {
    return AuthViewModel(scope.get<IAuthenticationProvider>());
  }

  @override
  Widget build(BuildContext context, AuthViewModel viewModel) {
    return Text(
      viewModel.isAuthenticated 
        ? "Is Authenticated" 
        : "Is Not Authenticated"
    );
  }
}

// Your root widget should be a Dependencies widget:

runApp(
  // Builds the dependency injection scope from here on,
  // initializing all `IInitializable` dependencies.
  //
  // The order of dependencies is NOT important, since the
  // package will automatically sort them by dependency
  DependenciesBuilder(
    dependencies: [
      // Whenever someone needs an IAuthenticationProvider,
      // a FirebaseAuthenticationProvider will be provided.
      Dependency<IAuthenticationProvider>(
        (scope) => FirebaseAuthenticationProvider(),
      ),
      Dependency<ISomeOtherProvider>(
        (scope) => SomeOtherProvider(
          authenticationProvider:
            // This is how you get a dependency from the scope.
            scope.get<IAuthenticationProvider>(),
        ),
        // This is important when one dependency depends on
        // another to ensure the correct order of instantiation
        // and initialization of the dependencies.
        dependsOn: [IAuthenticationProvider],
      ),
    ],
    builder: (context, scope) => const MainApp(),
  );
);
```


## Why Choose Our Dependency Injection Framework?

- **Clean Architecture**: Enforces separation of concerns
- **Flexible**: Easy dependency management
- **Testable**: Mock dependencies effortlessly
- **Runtime Configuration**: Change dependencies dynamically
- **Minimal Boilerplate**: Simple, intuitive API

**Read the source code to discover the full power of this package!**

> Separation of Concerns (SoC) - GeeksforGeeks https://www.geeksforgeeks.org/separation-of-concerns-soc/

> how do you handle Business Logic? : r/FlutterDev - Reddit https://www.reddit.com/r/FlutterDev/comments/drwruf/people_who_use_provider_for_state_management_how/

> A quick intro to Dependency Injection: what it is, and when to use it https://www.freecodecamp.org/news/a-quick-intro-to-dependency-injection-what-it-is-and-when-to-use-it-7578c84fa88f/

> Separation of concerns - Wikipedia https://en.wikipedia.org/wiki/Separation_of_concerns

> Guide to app architecture - Flutter Documentation https://docs.flutter.dev/app-architecture/guide

> Dependency injection - Wikipedia https://en.wikipedia.org/wiki/Dependency_injection
