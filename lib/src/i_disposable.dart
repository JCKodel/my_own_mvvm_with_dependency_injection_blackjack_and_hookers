part of '../dependencies.dart';

/// An interface that defines a disposable resource.
///
/// A disposable resource is an object that implements this interface and
/// provides a method to dispose of its resources.
///
/// The [IDisposable] interface is typically used to implement the dispose
/// method in a class that manages resources, such as a database connection
/// or a file reader. The dispose method is called automatically when the
/// object is no longer needed, allowing the resources to be released and
/// cleaned up.
abstract interface class IDisposable {
  void dispose();
}
