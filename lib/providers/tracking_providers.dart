import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/symptom_model.dart';
import '../models/period_cycle_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

const uuid = Uuid();

// Symptoms provider
final symptomsProvider = StateNotifierProvider<SymptomsNotifier, List<SymptomModel>>((ref) {
  return SymptomsNotifier(ref);
});

class SymptomsNotifier extends StateNotifier<List<SymptomModel>> {
  SymptomsNotifier(this.ref) : super([]) {
    _loadSymptoms();
  }

  final Ref ref;

  void _loadSymptoms() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final db = DatabaseService();
      state = db.getUserSymptoms(user.id);
    }
  }

  Future<void> addSymptom(SymptomModel symptom) async {
    final db = DatabaseService();
    await db.saveSymptom(symptom);
    _loadSymptoms();
  }

  Future<void> deleteSymptom(String id) async {
    final db = DatabaseService();
    await db.deleteSymptom(id);
    _loadSymptoms();
  }

  void refresh() {
    _loadSymptoms();
  }
}

// Period cycles provider
final periodCyclesProvider = StateNotifierProvider<PeriodCyclesNotifier, List<PeriodCycleModel>>((ref) {
  return PeriodCyclesNotifier(ref);
});

class PeriodCyclesNotifier extends StateNotifier<List<PeriodCycleModel>> {
  PeriodCyclesNotifier(this.ref) : super([]) {
    _loadCycles();
  }

  final Ref ref;

  void _loadCycles() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final db = DatabaseService();
      state = db.getUserPeriodCycles(user.id);
    }
  }

  Future<void> addCycle(PeriodCycleModel cycle) async {
    final db = DatabaseService();
    await db.savePeriodCycle(cycle);
    _loadCycles();
  }

  Future<void> updateCycle(PeriodCycleModel cycle) async {
    final db = DatabaseService();
    await db.savePeriodCycle(cycle);
    _loadCycles();
  }

  Future<void> deleteCycle(String id) async {
    final db = DatabaseService();
    await db.deletePeriodCycle(id);
    _loadCycles();
  }

  PeriodCycleModel? getActiveCycle() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final db = DatabaseService();
      return db.getActivePeriodCycle(user.id);
    }
    return null;
  }

  // Calculate average cycle length
  int? getAverageCycleLength() {
    if (state.length < 2) return null;

    final completedCycles = state.where((c) => c.cycleLength != null).toList();
    if (completedCycles.isEmpty) return null;

    final total = completedCycles.fold<int>(0, (sum, c) => sum + (c.cycleLength ?? 0));
    return (total / completedCycles.length).round();
  }

  // Predict next period
  DateTime? predictNextPeriod() {
    final avgLength = getAverageCycleLength();
    if (avgLength == null || state.isEmpty) return null;

    final lastCycle = state.first;
    return lastCycle.startDate.add(Duration(days: avgLength));
  }

  void refresh() {
    _loadCycles();
  }
}

// Active period cycle provider
final activePeriodCycleProvider = Provider<PeriodCycleModel?>((ref) {
  final cycles = ref.watch(periodCyclesProvider);
  try {
    return cycles.firstWhere((c) => c.isActive);
  } catch (e) {
    return null;
  }
});
