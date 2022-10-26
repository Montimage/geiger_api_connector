// To parse this JSON data, do
//
//     final user = userFromMap(jsonString);

import 'dart:convert';

import 'package:geiger_api_connector/multi_language_value.dart';

Map<String, RecommendationNodeModel> recommendationNodeModelFromMap(
        String str) =>
    Map.from(json.decode(str)).map((k, v) =>
        MapEntry<String, RecommendationNodeModel>(
            k, RecommendationNodeModel.fromMap(v)));

String recommendationNodeModelToMap(
        Map<String, RecommendationNodeModel> data) =>
    json.encode(
        Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toMap())));

class RecommendationNodeModel {
  RecommendationNodeModel({
    required this.sensorId,
    required this.short,
    required this.long,
    required this.action,
    required this.relatedThreatsWeights,
    required this.costs,
    required this.recommendationType,
    required this.os,
    // required this.createdDate,
    // required this.pluginId,
  });

  String sensorId;
  List<MultilingualValues> short;
  List<MultilingualValues> long;
  String action;
  String relatedThreatsWeights;
  String costs;
  String recommendationType;
  String os;
  // String createdDate;
  // String pluginId;

  factory RecommendationNodeModel.fromMap(Map<String, dynamic> json) =>
      RecommendationNodeModel(
        sensorId: json["sensorId"],
        short: json['short'] == null
            ? []
            : List<MultilingualValues>.from(
                (json['short'] as List<dynamic>).map<MultilingualValues>(
                  (dynamic x) =>
                      MultilingualValues.fromMap(x as Map<String, dynamic>),
                ),
              ),
        long: json['long'] == null
            ? []
            : List<MultilingualValues>.from(
                (json['long'] as List<dynamic>).map<MultilingualValues>(
                  (dynamic x) =>
                      MultilingualValues.fromMap(x as Map<String, dynamic>),
                ),
              ),
        action: json["Action"],
        relatedThreatsWeights: json["relatedThreatsWeights"],
        costs: json["costs"],
        recommendationType: json["RecommendationType"],
        os: json["os"],
      );

  Map<String, dynamic> toMap() => {
        "sensorId": sensorId,
        "short": short.isNotEmpty
            ? <Map<String, dynamic>>[]
            : List<MultilingualValues>.from(
                short.map<Map<String, dynamic>>(
                  (MultilingualValues x) => x.toMap(),
                ),
              ),
        "long": long.isNotEmpty
            ? <Map<String, dynamic>>[]
            : List<MultilingualValues>.from(
                short.map<Map<String, dynamic>>(
                  (MultilingualValues x) => x.toMap(),
                ),
              ),
        "action": action,
        "relatedThreatsWeights": relatedThreatsWeights,
        "costs": costs,
        "recommendationType": recommendationType,
        "os": os,
      };
}
