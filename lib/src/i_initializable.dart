part of '../dependencies.dart';

/// An interface that defines an object that can be initialized.
///
/// An object that implements this interface is expected to provide a method
/// that initializes its resources, such as initializing a database connection
/// or opening a file reader. The initialize method is automatically called
/// when the object is created, allowing the resources to be initialized and
/// ready for use.
abstract interface class IInitializable {
  Future<void> initialize();
}
