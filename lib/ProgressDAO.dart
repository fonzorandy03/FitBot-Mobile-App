import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressDAO {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collezione per i progressi
  static const String _progressCollection = 'progress';

  /// Salva o aggiorna un progresso per un esercizio specifico.
  /// NOTE:
  /// - I valori numerici a 0 vengono IGNORATI (non vengono scritti) per evitare
  ///   di sovrascrivere accidentalmente i progressi quando l’utente sta svuotando i campi.
  /// - Per azzerare davvero i campi, usa clearWeekProgress(...).
  Future<void> upsertProgress({
    required String userId,
    required String planId,
    required String dayName,
    required String exerciseName,
    required int week,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) async {
    try {
      if (userId.isEmpty) {
        print('ProgressDAO: userId è vuoto');
        return;
      }

      // ID univoco per questo specifico progresso
      final progressId =
          _generateProgressId(userId, planId, dayName, exerciseName, week);

      final docRef =
          _firestore.collection(_progressCollection).doc(progressId);

      // Dati base sempre aggiornati
      final data = <String, dynamic>{
        'userId': userId,
        'planId': planId,
        'dayName': dayName,
        'exerciseName': exerciseName,
        'week': week,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Helper: salva numeri solo se non null e > 0
      void putNum(String key, num? v) {
        if (v == null) return;
        if (v == 0) return; // ignora zeri per evitare sovrascritture involontarie
        data[key] = v;
      }

      putNum('weight', weight);
      putNum('reps', reps);

      // I booleani si salvano sempre se forniti (anche false)
      if (isCompleted != null) {
        data['isCompleted'] = isCompleted;
      }

      // merge:true -> aggiorna solo i campi passati
      await docRef.set(data, SetOptions(merge: true));

      print(
          'ProgressDAO: Progresso salvato - $exerciseName, week $week, weight: $weight, reps: $reps, done: $isCompleted');
    } catch (e) {
      print('ProgressDAO: Errore nel salvare il progresso: $e');
      rethrow;
    }
  }

  /// Opzionale: azzera davvero i campi della settimana (rimuove weight/reps/isCompleted).
  Future<void> clearWeekProgress({
    required String userId,
    required String planId,
    required String dayName,
    required String exerciseName,
    required int week,
  }) async {
    try {
      final progressId =
          _generateProgressId(userId, planId, dayName, exerciseName, week);
      final docRef =
          _firestore.collection(_progressCollection).doc(progressId);

      await docRef.set({
        'userId': userId,
        'planId': planId,
        'dayName': dayName,
        'exerciseName': exerciseName,
        'week': week,
        'updatedAt': FieldValue.serverTimestamp(),
        'weight': FieldValue.delete(),
        'reps': FieldValue.delete(),
        'isCompleted': FieldValue.delete(),
      }, SetOptions(merge: true));

      print(
          'ProgressDAO: Pulizia completata - $exerciseName, week $week (weight/reps/isCompleted rimossi)');
    } catch (e) {
      print('ProgressDAO: Errore nella pulizia del progresso: $e');
      rethrow;
    }
  }

  /// Stream di tutti i progressi per un piano specifico dell’utente.
  Stream<List<ProgressEntry>> streamPlanProgress({
    required String userId,
    required String planId,
  }) {
    try {
      return _firestore
          .collection(_progressCollection)
          .where('userId', isEqualTo: userId)
          .where('planId', isEqualTo: planId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return ProgressEntry.fromMap(data);
        }).toList();
      });
    } catch (e) {
      print('ProgressDAO: Errore nel caricare i progressi: $e');
      return Stream.value([]);
    }
  }

  /// Genera un ID univoco per il progresso.
  String _generateProgressId(
    String userId,
    String planId,
    String dayName,
    String exerciseName,
    int week,
  ) {
    // Rimuove caratteri non alfanumerici per un ID sicuro
    String clean(String s) =>
        s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    final cleanUserId = clean(userId);
    final cleanPlanId = clean(planId);
    final cleanDayName = clean(dayName);
    final cleanExerciseName = clean(exerciseName);

    return '${cleanUserId}_${cleanPlanId}_${cleanDayName}_${cleanExerciseName}_week$week';
    // Esempio: abc123_planX_Lunedi_PancaPiana_week1
  }
}

/// Modello dati per una voce di progresso.
class ProgressEntry {
  final String userId;
  final String planId;
  final String dayName;
  final String exerciseName;
  final int week;
  final double weight;
  final int reps;
  final bool isCompleted;
  final DateTime? updatedAt;

  ProgressEntry({
    required this.userId,
    required this.planId,
    required this.dayName,
    required this.exerciseName,
    required this.week,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
    this.updatedAt,
  });

  factory ProgressEntry.fromMap(Map<String, dynamic> map) {
    return ProgressEntry(
      userId: (map['userId'] ?? '').toString(),
      planId: (map['planId'] ?? '').toString(),
      dayName: (map['dayName'] ?? '').toString(),
      exerciseName: (map['exerciseName'] ?? '').toString(),
      week: (map['week'] ?? 1) is int
          ? (map['week'] ?? 1) as int
          : int.tryParse(map['week'].toString()) ?? 1,
      weight: (map['weight'] ?? 0.0).toDouble(),
      reps: (map['reps'] ?? 0) is int
          ? (map['reps'] ?? 0) as int
          : int.tryParse(map['reps'].toString()) ?? 0,
      isCompleted: (map['isCompleted'] ?? false) == true,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  String toString() {
    return 'ProgressEntry(userId: $userId, planId: $planId, dayName: $dayName, exerciseName: $exerciseName, week: $week, weight: $weight, reps: $reps, isCompleted: $isCompleted)';
  }
}
