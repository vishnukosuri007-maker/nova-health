import 'package:hive/hive.dart';

part 'health_metric_model.g.dart';

@HiveType(typeId: 3)
class HealthMetricModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double? weight; // in kg

  @HiveField(4)
  int? steps;

  @HiveField(5)
  int? sleepMinutes;

  @HiveField(6)
  String? mood; // happy, sad, anxious, calm, stressed

  @HiveField(7)
  int? stressLevel; // 1-10

  @HiveField(8)
  int? energyLevel; // 1-10

  @HiveField(9)
  String? notes;

  @HiveField(10)
  DateTime createdAt;

  HealthMetricModel({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.steps,
    this.sleepMinutes,
    this.mood,
    this.stressLevel,
    this.energyLevel,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'steps': steps,
      'sleepMinutes': sleepMinutes,
      'mood': mood,
      'stressLevel': stressLevel,
      'energyLevel': energyLevel,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) {
    return HealthMetricModel(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      weight: json['weight']?.toDouble(),
      steps: json['steps'],
      sleepMinutes: json['sleepMinutes'],
      mood: json['mood'],
      stressLevel: json['stressLevel'],
      energyLevel: json['energyLevel'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
