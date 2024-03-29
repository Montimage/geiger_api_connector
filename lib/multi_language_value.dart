// To parse this JSON data, do
//
//     final user = userFromMap(jsonString);

import 'dart:convert';

Map<String, MultilingualValues> multiLanguageValueModelFromMap(String str) =>
    Map.from(json.decode(str)).map((k, v) =>
        MapEntry<String, MultilingualValues>(k, MultilingualValues.fromMap(v)));

String multiLanguageValueModelToMap(Map<String, MultilingualValues> data) =>
    json.encode(
        Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toMap())));

String getValueByLanguage(String language, List<MultilingualValues> values) {
  String? defaultValue; // English
  for (var i = 0; i < values.length; i++) {
    if (values[i].language == language) return values[i].value;
    if (values[i].language == "en") defaultValue = values[i].value;
  }
  return defaultValue ?? "Unknown";
}

class MultilingualValues {
  MultilingualValues({
    required this.language,
    required this.value,
  });

  String language;
  String value;

  factory MultilingualValues.fromMap(Map<String, dynamic> json) =>
      MultilingualValues(
        language: json["language"],
        value: json["value"],
      );

  Map<String, dynamic> toMap() => {
        "language": language,
        "value": value,
      };
}
