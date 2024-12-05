## 0.0.1

* Initial release.

## 0.0.1+1

* Adding some extra information on read me.

## 0.0.1+2

* Reverting a bit of 0.0.1+1 because Dart is sooooo lame. No `T.new()` for you >.< Dart, sometimes I really hate you.

## 0.0.2

* Now `DependenciesBuilder` will render an `ErrorWidget` with the exception thrown by some nasty dependency. 

## 0.0.3

* Bug fix from https://forum.itsallwidgets.com/t/flutter-and-idx/429/22

## 0.0.3+1

* Bug fix from bug fix

## 1.0.0

* Production ready
* Added `logging` for logging (you should configure logging in your app)
* Added some hooks for widgets initialization
* Fix a bug when registering the same dependency twice would trigger the circular dependency error (now it will throw an exception)
* Improved initialization (parallel initialization, when it is possible)
* Added some tests

## 1.0.0+1

* My tests are perfect, but the Dart Test SDK failed (seriously: I used `test` and that has some nasty issues with version while using Flutter, so changed it to use `flutter_test` from sdk, nobody uses Dart alone anyway...)

## 1.0.1

* Dependencies are now registered as String, so if you miss the `T` in `Dependencies<T>`, it will still find the right type (infered from the closure signature). Notice that if your dependency is an interface, you still need to specify the generic type

## 1.0.1+1

* Fix a bug in the parallel initialization

## 1.0.1+2

* Fix a bug in the parallel initialization, again

## 1.0.2

* Simplified `ViewWidget`

## 1.0.2+1

* Fix ViewWidget  initialization

## 1.0.2+2

* Removed logger dependency

## 1.1.0

* Changed some names and adding some documentation

# 1.1.0+1

* Minor fixes

# 1.1.0+2

* Minor fixes
* Docs update

# 1.1.0 + 3

* ViewWidget was not triggering rebuilds when the view model was changed
