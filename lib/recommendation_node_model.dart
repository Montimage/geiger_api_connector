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
    required this.Action,
    required this.relatedThreatsWeights,
    required this.costs,
    required this.RecommendationType,
    // required this.pluginId,
  });

  String recommendationId;
  String short;
  String long;
  String Action;
  String relatedThreatsWeights;
  String costs;
  String RecommendationType;
  // String pluginId;

  factory RecommendationNodeModel.fromMap(Map<String, dynamic> json) =>
      RecommendationNodeModel(
        recommendationId: json["recommendationId"],
        short: json["short"],
        long: json["long"],
        Action: json["Action"],
        relatedThreatsWeights: json["relatedThreatsWeights"],
        costs: json["costs"],
        RecommendationType: json["RecommendationType"],
        // pluginId: json["pluginId"],
      );

  Map<String, dynamic> toMap() => {
        "recommendationId": recommendationId,
        "short": short,
        "long": long,
        "Action": Action,
        "relatedThreatsWeights": relatedThreatsWeights,
        "costs": costs,
        "RecommendationType": RecommendationType,
        // "pluginId": pluginId,
      };
}
