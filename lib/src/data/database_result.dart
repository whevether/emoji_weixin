import 'package:tostore/tostore.dart';

/// Throws when a database operation reports failure without throwing itself.
void requireDatabaseSuccess(DbResult result, String operation) {
  if (result.hasErrors) {
    throw StateError('$operation failed: ${result.message}');
  }
}
