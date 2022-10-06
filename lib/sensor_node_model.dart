// To parse this JSON data, do
//
//     final user = userFromMap(jsonString);

import 'dart:convert';

import 'package:geiger_api_connector/multi_language_value.dart';

Map<String, SensorDataModel> sensorDataModelFromMap(String str) =>
    Map.from(json.decode(str)).map((k, v) =>
        MapEntry<String, SensorDataModel>(k, SensorDataModel.fromMap(v)));

String sensorDataModelToMap(Map<String, SensorDataModel> data) => json.encode(
    Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toMap())));

class SensorDataModel {
  SensorDataModel({
    required this.sensorId,
    required this.name,
    required this.description,
    required this.minValue,
    required this.maxValue,
    required this.valueType,
    required this.flag,
    required this.threatsImpact,
    required this.urgency,
  });

  String sensorId;
  String name;
  List<MultilingualValues> description;
  String minValue;
  String maxValue;
  String valueType;
  String flag;
  String threatsImpact;
  String urgency;

  factory SensorDataModel.fromMap(Map<String, dynamic> json) => SensorDataModel(
        sensorId: json["sensorId"],
        name: json["name"],
        description: json['description'] == null
            ? []
            : List<MultilingualValues>.from(
                (json['description'] as List<dynamic>).map<MultilingualValues>(
                  (dynamic x) =>
                      MultilingualValues.fromMap(x as Map<String, dynamic>),
                ),
              ),
        minValue: json["minValue"],
        maxValue: json["maxValue"],
        valueType: json["valueType"],
        flag: json["flag"],
        threatsImpact: json["threatsImpact"],
        urgency: json["urgency"],
      );

  Map<String, dynamic> toMap() => {
        "sensorId": sensorId,
        "name": name,
        "description": description.isNotEmpty
            ? <Map<String, dynamic>>[]
            : List<MultilingualValues>.from(
                description.map<Map<String, dynamic>>(
                  (MultilingualValues x) => x.toMap(),
                ),
              ),
        "minValue": minValue,
        "maxValue": maxValue,
        "valueType": valueType,
        "flag": flag,
        "threatsImpact": threatsImpact,
        "urgency": urgency,
      };
}
