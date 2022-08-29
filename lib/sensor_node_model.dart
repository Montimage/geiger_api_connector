// To parse this JSON data, do
//
//     final user = userFromMap(jsonString);

import 'dart:convert';

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
  String description;
  String minValue;
  String maxValue;
  String valueType;
  String flag;
  String threatsImpact;
  String urgency;

  factory SensorDataModel.fromMap(Map<String, dynamic> json) => SensorDataModel(
        sensorId: json["sensorId"],
        name: json["name"],
        description: json["description"],
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
        "description": description,
        "minValue": minValue,
        "maxValue": maxValue,
        "valueType": valueType,
        "flag": flag,
        "threatsImpact": threatsImpact,
        "urgency": urgency,
      };
}
