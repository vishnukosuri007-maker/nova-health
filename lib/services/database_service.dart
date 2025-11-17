import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../models/hydration_model.dart';
import '../models/health_metric_model.dart';
import '../models/symptom_model.dart';
import '../models/period_cycle_model.dart';
import '../models/food_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/meditation_session_model.dart';
import '../models/meal_plan_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _initialized = false;

  // Initialize Hive and register adapters
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(WorkoutModelAdapter());
    Hive.registerAdapter(HydrationModelAdapter());
    Hive.registerAdapter(HealthMetricModelAdapter());
    Hive.registerAdapter(SymptomModelAdapter());
    Hive.registerAdapter(PeriodCycleModelAdapter());
    Hive.registerAdapter(FoodLogModelAdapter());
    Hive.registerAdapter(MoodLogModelAdapter());
    Hive.registerAdapter(MeditationSessionModelAdapter());
    Hive.registerAdapter(RecipeModelAdapter());

    // Open boxes
    await Hive.openBox<UserModel>(AppConstants.userBox);
    await Hive.openBox<WorkoutModel>(AppConstants.workoutBox);
    await Hive.openBox<HydrationModel>('hydration_box');
    await Hive.openBox<HealthMetricModel>(AppConstants.healthBox);
    await Hive.openBox<SymptomModel>('symptom_box');
    await Hive.openBox<PeriodCycleModel>('period_box');
    await Hive.openBox<FoodLogModel>('food_log_box');
    await Hive.openBox<MoodLogModel>('mood_box');
    await Hive.openBox<MeditationSessionModel>('meditation_box');
    await Hive.openBox<RecipeModel>('recipe_box');
    await Hive.openBox(AppConstants.settingsBox);

    _initialized = true;
  }

  // User operations
  Box<UserModel> get userBox => Hive.box<UserModel>(AppConstants.userBox);

  Future<void> saveUser(UserModel user) async {
    await userBox.put(user.id, user);
  }

  UserModel? getUser(String userId) {
    return userBox.get(userId);
  }

  Future<void> deleteUser(String userId) async {
    await userBox.delete(userId);
  }

  List<UserModel> getAllUsers() {
    return userBox.values.toList();
  }

  // Workout operations
  Box<WorkoutModel> get workoutBox => Hive.box<WorkoutModel>(AppConstants.workoutBox);

  Future<void> saveWorkout(WorkoutModel workout) async {
    await workoutBox.put(workout.id, workout);
  }

  WorkoutModel? getWorkout(String id) {
    return workoutBox.get(id);
  }

  Future<void> deleteWorkout(String id) async {
    await workoutBox.delete(id);
  }

  List<WorkoutModel> getUserWorkouts(String userId) {
    return workoutBox.values.where((w) => w.userId == userId).toList();
  }

  List<WorkoutModel> getUserWorkoutsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return workoutBox.values
        .where((w) =>
            w.userId == userId &&
            w.date.isAfter(start.subtract(const Duration(days: 1))) &&
            w.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // Hydration operations
  Box<HydrationModel> get hydrationBox => Hive.box<HydrationModel>('hydration_box');

  Future<void> saveHydration(HydrationModel hydration) async {
    await hydrationBox.put(hydration.id, hydration);
  }

  Future<void> deleteHydration(String id) async {
    await hydrationBox.delete(id);
  }

  List<HydrationModel> getUserHydrationLogs(String userId) {
    return hydrationBox.values.where((h) => h.userId == userId).toList();
  }

  List<HydrationModel> getUserHydrationByDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return hydrationBox.values
        .where((h) =>
            h.userId == userId &&
            h.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            h.timestamp.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList();
  }

  int getTotalHydrationForDay(String userId, DateTime date) {
    final logs = getUserHydrationByDate(userId, date);
    return logs.fold(0, (sum, log) => sum + log.amountMl);
  }

  // Health metrics operations
  Box<HealthMetricModel> get healthBox =>
      Hive.box<HealthMetricModel>(AppConstants.healthBox);

  Future<void> saveHealthMetric(HealthMetricModel metric) async {
    await healthBox.put(metric.id, metric);
  }

  Future<void> deleteHealthMetric(String id) async {
    await healthBox.delete(id);
  }

  List<HealthMetricModel> getUserHealthMetrics(String userId) {
    return healthBox.values.where((m) => m.userId == userId).toList();
  }

  HealthMetricModel? getHealthMetricByDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return healthBox.values.firstWhere(
      (m) =>
          m.userId == userId &&
          m.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          m.date.isBefore(endOfDay.add(const Duration(seconds: 1))),
      orElse: () => HealthMetricModel(
        id: '',
        userId: userId,
        date: date,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Settings operations
  Box get settingsBox => Hive.box(AppConstants.settingsBox);

  Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  // Symptom operations
  Box<SymptomModel> get symptomBox => Hive.box<SymptomModel>('symptom_box');

  Future<void> saveSymptom(SymptomModel symptom) async {
    await symptomBox.put(symptom.id, symptom);
  }

  Future<void> deleteSymptom(String id) async {
    await symptomBox.delete(id);
  }

  List<SymptomModel> getUserSymptoms(String userId) {
    return symptomBox.values.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Period cycle operations
  Box<PeriodCycleModel> get periodBox => Hive.box<PeriodCycleModel>('period_box');

  Future<void> savePeriodCycle(PeriodCycleModel cycle) async {
    await periodBox.put(cycle.id, cycle);
  }

  Future<void> deletePeriodCycle(String id) async {
    await periodBox.delete(id);
  }

  List<PeriodCycleModel> getUserPeriodCycles(String userId) {
    return periodBox.values.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  PeriodCycleModel? getActivePeriodCycle(String userId) {
    try {
      return periodBox.values.firstWhere(
        (p) => p.userId == userId && p.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  // Food log operations
  Box<FoodLogModel> get foodLogBox => Hive.box<FoodLogModel>('food_log_box');

  Future<void> saveFoodLog(FoodLogModel foodLog) async {
    await foodLogBox.put(foodLog.id, foodLog);
  }

  Future<void> deleteFoodLog(String id) async {
    await foodLogBox.delete(id);
  }

  List<FoodLogModel> getUserFoodLogs(String userId) {
    return foodLogBox.values.where((f) => f.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<FoodLogModel> getUserFoodLogsByDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return foodLogBox.values
        .where((f) =>
            f.userId == userId &&
            f.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            f.timestamp.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Mood log operations
  Box<MoodLogModel> get moodBox => Hive.box<MoodLogModel>('mood_box');

  Future<void> saveMoodLog(MoodLogModel moodLog) async {
    await moodBox.put(moodLog.id, moodLog);
  }

  Future<void> deleteMoodLog(String id) async {
    await moodBox.delete(id);
  }

  List<MoodLogModel> getUserMoodLogs(String userId) {
    return moodBox.values.where((m) => m.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<MoodLogModel> getUserMoodLogsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return moodBox.values
        .where((m) =>
            m.userId == userId &&
            m.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
            m.timestamp.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Meditation session operations
  Box<MeditationSessionModel> get meditationBox =>
      Hive.box<MeditationSessionModel>('meditation_box');

  Future<void> saveMeditationSession(MeditationSessionModel session) async {
    await meditationBox.put(session.id, session);
  }

  Future<void> deleteMeditationSession(String id) async {
    await meditationBox.delete(id);
  }

  List<MeditationSessionModel> getUserMeditationSessions(String userId) {
    return meditationBox.values.where((m) => m.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getMeditationStreak(String userId) {
    final sessions = getUserMeditationSessions(userId);
    if (sessions.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final startOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final endOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day, 23, 59, 59);

      final hasSession = sessions.any((s) =>
          s.timestamp.isAfter(startOfDay) && s.timestamp.isBefore(endOfDay));

      if (hasSession) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }

      if (streak > 365) break; // Safety limit
    }

    return streak;
  }

  // Recipe operations
  Box<RecipeModel> get recipeBox => Hive.box<RecipeModel>('recipe_box');

  Future<void> saveRecipe(RecipeModel recipe) async {
    await recipeBox.put(recipe.id, recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await recipeBox.delete(id);
  }

  List<RecipeModel> getAllRecipes() {
    return recipeBox.values.toList();
  }

  List<RecipeModel> getRecipesByCategory(String category) {
    return recipeBox.values.where((r) => r.category == category).toList();
  }

  // Clear all data
  Future<void> clearAllData() async {
    await userBox.clear();
    await workoutBox.clear();
    await hydrationBox.clear();
    await healthBox.clear();
    await symptomBox.clear();
    await periodBox.clear();
    await foodLogBox.clear();
    await moodBox.clear();
    await meditationBox.clear();
    await recipeBox.clear();
    await settingsBox.clear();
  }

  // Close all boxes
  Future<void> close() async {
    await Hive.close();
  }
}
