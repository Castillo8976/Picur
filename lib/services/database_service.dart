import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../config.dart';
import '../models/reading.dart';

class DatabaseService {
  Stream<List<Reading>> get readings {
    return FirebaseDatabase.instance.ref(databasePath).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <Reading>[];
      final output = <Reading>[];
      for (final entry in value.entries) {
        try {
          if (entry.value is Map) {
            output.add(Reading.fromMap(
              entry.key.toString(),
              Map<Object?, Object?>.from(entry.value as Map),
            ));
          }
        } on FormatException {
          // A malformed sensor record is ignored; valid records remain visible.
        }
      }
      output.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return output;
    });
  }

  void dispose() {}
}
