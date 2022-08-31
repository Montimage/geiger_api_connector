import 'package:uuid/uuid.dart';

String getUniqueId() {
  return const Uuid().v4();
}
