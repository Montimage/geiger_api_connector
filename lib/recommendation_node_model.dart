// To parse this JSON data, do
//
//     final user = userFromMap(jsonString);

import 'dart:convert';

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
    required this.recommendationId,
    required this.short,
    required this.long,
    required this.action,
    required this.relatedThreatsWeights,
    required this.costs,
    required this.recommendationType,
    // required this.pluginId,
  });

  String recommendationId;
  String short;
  String long;
  String action;
  String relatedThreatsWeights;
  String costs;
  String recommendationType;
  // String pluginId;

  factory RecommendationNodeModel.fromMap(Map<String, dynamic> json) =>
      RecommendationNodeModel(
        recommendationId: json["recommendationId"],
        short: json["short"],
        long: json["long"],
        action: json["Action"],
        relatedThreatsWeights: json["relatedThreatsWeights"],
        costs: json["costs"],
        recommendationType: json["RecommendationType"],
        // pluginId: json["pluginId"],
      );

  Map<String, dynamic> toMap() => {
        "recommendationId": recommendationId,
        "short": short,
        "long": long,
        "action": action,
        "relatedThreatsWeights": relatedThreatsWeights,
        "costs": costs,
        "recommendationType": recommendationType,
        // "pluginId": pluginId,
      };
}
