import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modello dati per l'esercizio
class Exercise {
  final String nome;
  final int serie;
  final String ripetizioni;
  final int riposoSec;
  final String? note;

  Exercise({
    required this.nome,
    required this.serie,
    required this.ripetizioni,
    required this.riposoSec,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'serie': serie,
      'ripetizioni': ripetizioni,
      'riposo_sec': riposoSec,
      'note': note,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      nome: map['nome']?.toString() ?? '',
      serie: (map['serie'] as num?)?.toInt() ?? 0,
      ripetizioni: map['ripetizioni']?.toString() ?? '',
      riposoSec: (map['riposo_sec'] as num?)?.toInt() ?? 0,
      note: map['note']?.toString(),
    );
  }
}

// Modello dati per il giorno di allenamento
class WorkoutDay {
  final String giorno;
  final String focus;
  final List<Exercise> esercizi;

  WorkoutDay({
    required this.giorno,
    required this.focus,
    required this.esercizi,
  });

  Map<String, dynamic> toMap() {
    return {
      'giorno': giorno,
      'focus': focus,
      'esercizi': esercizi.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    var eserciziList = <Exercise>[];
    if (map['esercizi'] != null) {
      for (var esercizio in map['esercizi']) {
        if (esercizio is Map<String, dynamic>) {
          eserciziList.add(Exercise.fromMap(esercizio));
        }
      }
    }
    
    return WorkoutDay(
      giorno: map['giorno']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      esercizi: eserciziList,
    );
  }
}

// Modello dati per il piano di allenamento completo
class WorkoutPlan {
  final String? id;
  final String userId;
  final String titolo;
  final String obiettivo;
  final String frequenza;
  final String experience;       
  final String? additionalNotes;
  final int duratSettimane;
  final int eta;
  final List<WorkoutDay> giorni;
  final List<String> consigli;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

   WorkoutPlan({
    this.id,
    required this.userId,
    required this.titolo,
    required this.obiettivo,
    required this.frequenza,
    required this.experience,        
    this.additionalNotes,            
    required this.duratSettimane,
    required this.eta,
    required this.giorni,
    required this.consigli,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'titolo': titolo,
      'obiettivo': obiettivo,
      'frequenza': frequenza,
      'experience': experience,           // AGGIUNGI QUESTO
      'additionalNotes': additionalNotes, // AGGIUNGI QUESTO
      'durata_settimane': duratSettimane,
      'eta': eta,
      'giorni': giorni.map((d) => d.toMap()).toList(),
      'consigli': consigli,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map, String documentId) {
    var giorniList = <WorkoutDay>[];
    if (map['giorni'] != null) {
      for (var giorno in map['giorni']) {
        if (giorno is Map<String, dynamic>) {
          giorniList.add(WorkoutDay.fromMap(giorno));
        }
      }
    }

    var consigliList = <String>[];
    if (map['consigli'] != null) {
      for (var consiglio in map['consigli']) {
        consigliList.add(consiglio.toString());
      }
    }

    return WorkoutPlan(
      id: documentId,
      userId: map['userId']?.toString() ?? '',
      titolo: map['titolo']?.toString() ?? '',
      obiettivo: map['obiettivo']?.toString() ?? '',
      frequenza: map['frequenza']?.toString() ?? '',
      experience: map['experience']?.toString() ?? 'Intermedio',     // AGGIUNGI QUESTO
      additionalNotes: map['additionalNotes']?.toString(),           // AGGIUNGI QUESTO
      duratSettimane: (map['durata_settimane'] as num?)?.toInt() ?? 0,
      eta: (map['eta'] as num?)?.toInt() ?? 0,
      giorni: giorniList,
      consigli: consigliList,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] == true,
    );
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? titolo,
    String? obiettivo,
    String? frequenza,
    String? experience,        // AGGIUNGI QUESTO
    String? additionalNotes,   // AGGIUNGI QUESTO
    int? duratSettimane,
    int? eta,
    List<WorkoutDay>? giorni,
    List<String>? consigli,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titolo: titolo ?? this.titolo,
      obiettivo: obiettivo ?? this.obiettivo,
      frequenza: frequenza ?? this.frequenza,
      experience: experience ?? this.experience,                    
      additionalNotes: additionalNotes ?? this.additionalNotes,     
      duratSettimane: duratSettimane ?? this.duratSettimane,
      eta: eta ?? this.eta,
      giorni: giorni ?? this.giorni,
      consigli: consigli ?? this.consigli,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Risultato delle operazioni del DAO
class WorkoutPlanResult {
  final bool success;
  final String? error;
  final WorkoutPlan? workoutPlan;
  final List<WorkoutPlan>? workoutPlans;
  final String? errorCode;

  WorkoutPlanResult({
    required this.success,
    this.error,
    this.workoutPlan,
    this.workoutPlans,
    this.errorCode,
  });

  factory WorkoutPlanResult.success({WorkoutPlan? plan, List<WorkoutPlan>? plans}) {
    return WorkoutPlanResult(
      success: true,
      workoutPlan: plan,
      workoutPlans: plans,
    );
  }

  factory WorkoutPlanResult.failure(String error, [String? errorCode]) {
    return WorkoutPlanResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

class WorkoutPlanDAO {
  static final WorkoutPlanDAO _instance = WorkoutPlanDAO._internal();
  factory WorkoutPlanDAO() => _instance;
  WorkoutPlanDAO._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Nome della collezione
  static const String _collection = 'workout_plans';

  // Getter per l'utente corrente
  String? get _currentUserId => _auth.currentUser?.uid;

  // Verifica se l'utente è autenticato
  bool get _isAuthenticated => _currentUserId != null;

  // Validazione dati prima del salvataggio
  bool _validateWorkoutPlan(WorkoutPlan workoutPlan) {
    if (workoutPlan.titolo.trim().isEmpty) {
      print('Errore validazione: titolo vuoto');
      return false;
    }
    
    if (workoutPlan.userId.trim().isEmpty) {
      print('Errore validazione: userId vuoto');
      return false;
    }
    
    if (workoutPlan.giorni.isEmpty) {
      print('Errore validazione: nessun giorno di allenamento');
      return false;
    }
    
    // Verifica che ogni giorno abbia almeno un esercizio
    for (var giorno in workoutPlan.giorni) {
      if (giorno.esercizi.isEmpty) {
        print('Errore validazione: giorno ${giorno.giorno} senza esercizi');
        return false;
      }
      
      // Verifica che ogni esercizio sia valido
      for (var esercizio in giorno.esercizi) {
        if (esercizio.nome.trim().isEmpty) {
          print('Errore validazione: esercizio senza nome nel giorno ${giorno.giorno}');
          return false;
        }
        if (esercizio.serie <= 0) {
          print('Errore validazione: serie non valide per ${esercizio.nome}');
          return false;
        }
      }
    }
    
    return true;
  }

  // Pulisce i dati prima del salvataggio
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    Map<String, dynamic> cleaned = {};
    
    data.forEach((key, value) {
      if (value != null) {
        if (value is String) {
          cleaned[key] = value.trim();
        } else if (value is List) {
          cleaned[key] = _sanitizeList(value);
        } else if (value is Map<String, dynamic>) {
          cleaned[key] = _sanitizeData(value);
        } else {
          cleaned[key] = value;
        }
      }
    });
    
    return cleaned;
  }

  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return item.trim();
      } else if (item is Map<String, dynamic>) {
        return _sanitizeData(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }

  // Disattiva tutti i piani tranne quello specificato
  Future<void> _deactivateOtherPlans({String? excludeId}) async {
    if (!_isAuthenticated) return;

    try {
      print('Disattivando piani precedenti per utente: $_currentUserId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Usa WriteBatch invece di transaction per evitare conflitti
        final batch = _firestore.batch();
        
        for (final doc in querySnapshot.docs) {
          if (excludeId == null || doc.id != excludeId) {
            print('Disattivando piano: ${doc.id}');
            batch.update(doc.reference, {
              'isActive': false,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          }
        }

        await batch.commit();
        print('${querySnapshot.docs.length} piani precedenti disattivati');
      } else {
        print('Nessun piano attivo da disattivare');
      }
    } catch (e) {
      print('Errore durante la disattivazione dei piani: $e');
      // Non lanciare l'errore per non bloccare il salvataggio principale
    }
  }

  // Salva una nuova scheda di allenamento - VERSIONE CORRETTA
  Future<WorkoutPlanResult> saveWorkoutPlan(WorkoutPlan workoutPlan) async {
    try {
      if (!_isAuthenticated) {
        return WorkoutPlanResult.failure('Utente non autenticato');
      }

      print('Salvando piano di allenamento per utente: $_currentUserId');

      // Assicurati che il piano sia associato all'utente corrente
      final planToSave = workoutPlan.copyWith(
        userId: _currentUserId!,
        createdAt: DateTime.now(),
      );

      // Validazione dati
      if (!_validateWorkoutPlan(planToSave)) {
        return WorkoutPlanResult.failure('Dati del piano non validi');
      }

      // Prepara e pulisce i dati per il salvataggio
      final dataToSave = _sanitizeData(planToSave.toMap());
      
      print('Dati da salvare: ${dataToSave.keys}');
      
      // Salva il documento PRIMA di disattivare gli altri
      final docRef = _firestore.collection(_collection).doc();
      
      await docRef.set(dataToSave);
      print('Piano di allenamento salvato con ID: ${docRef.id}');
      
      // Disattiva eventuali piani precedenti DOPO il salvataggio se questo è attivo
      if (planToSave.isActive) {
        await _deactivateOtherPlans(excludeId: docRef.id);
      }

      final savedPlan = planToSave.copyWith(id: docRef.id);
      
      return WorkoutPlanResult.success(plan: savedPlan);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il salvataggio: ${e.code} - ${e.message}');
      print('Stack trace: ${e.stackTrace}');
      return WorkoutPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e, stackTrace) {
      print('Errore durante il salvataggio del piano: $e');
      print('Stack trace: $stackTrace');
      return WorkoutPlanResult.failure(
        'Errore imprevisto durante il salvataggio: ${e.toString()}'
      );
    }
  }

  // Recupera tutti i piani di allenamento dell'utente corrente
  Future<WorkoutPlanResult> getUserWorkoutPlans({bool activeOnly = false}) async {
    try {
      if (!_isAuthenticated) {
        return WorkoutPlanResult.failure('Utente non autenticato');
      }

      print('Recuperando piani di allenamento per utente: $_currentUserId');

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      
      final plans = <WorkoutPlan>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final plan = WorkoutPlan.fromMap(data, doc.id);
          plans.add(plan);
        } catch (e) {
          print('Errore parsing documento ${doc.id}: $e');
          // Continua con gli altri documenti
        }
      }

      print('Recuperati ${plans.length} piani di allenamento');
      return WorkoutPlanResult.success(plans: plans);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il recupero: ${e.code} - ${e.message}');
      return WorkoutPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante il recupero dei piani: $e');
      return WorkoutPlanResult.failure(
        'Errore imprevisto durante il recupero: ${e.toString()}'
      );
    }
  }

  // Recupera il piano di allenamento attivo
  Future<WorkoutPlanResult> getActiveWorkoutPlan() async {
    try {
      if (!_isAuthenticated) {
        return WorkoutPlanResult.failure('Utente non autenticato');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return WorkoutPlanResult.failure('Nessun piano attivo trovato');
      }

      final doc = querySnapshot.docs.first;
      final plan = WorkoutPlan.fromMap(
        doc.data() as Map<String, dynamic>, 
        doc.id
      );

      print('Piano attivo recuperato: ${plan.id}');
      return WorkoutPlanResult.success(plan: plan);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il recupero piano attivo: ${e.code} - ${e.message}');
      return WorkoutPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante il recupero del piano attivo: $e');
      return WorkoutPlanResult.failure(
        'Errore imprevisto durante il recupero: ${e.toString()}'
      );
    }
  }

  // Aggiorna un piano esistente
  Future<WorkoutPlanResult> updateWorkoutPlan(WorkoutPlan workoutPlan) async {
    try {
      if (!_isAuthenticated) {
        return WorkoutPlanResult.failure('Utente non autenticato');
      }

      if (workoutPlan.id == null) {
        return WorkoutPlanResult.failure('ID del piano non specificato');
      }

      print('Aggiornando piano di allenamento: ${workoutPlan.id}');

      // Assicurati che il piano sia associato all'utente corrente
      final planToUpdate = workoutPlan.copyWith(
        userId: _currentUserId!,
        updatedAt: DateTime.now(),
      );

      // Validazione dati
      if (!_validateWorkoutPlan(planToUpdate)) {
        return WorkoutPlanResult.failure('Dati del piano non validi');
      }

      // Prepara e pulisce i dati per l'aggiornamento
      final dataToUpdate = _sanitizeData(planToUpdate.toMap());
      
      // Aggiorna il documento
      await _firestore
          .collection(_collection)
          .doc(workoutPlan.id!)
          .update(dataToUpdate);

      // Se il piano aggiornato è attivo, disattiva gli altri
      if (planToUpdate.isActive) {
        await _deactivateOtherPlans(excludeId: workoutPlan.id!);
      }

      print('Piano di allenamento aggiornato con successo');
      return WorkoutPlanResult.success(plan: planToUpdate);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante l\'aggiornamento: ${e.code} - ${e.message}');
      return WorkoutPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e, stackTrace) {
      print('Errore durante l\'aggiornamento del piano: $e');
      print('Stack trace: $stackTrace');
      return WorkoutPlanResult.failure(
        'Errore imprevisto durante l\'aggiornamento: ${e.toString()}'
      );
    }
  }

  // Elimina un piano di allenamento
  Future<WorkoutPlanResult> deleteWorkoutPlan(String planId) async {
    try {
      if (!_isAuthenticated) {
        return WorkoutPlanResult.failure('Utente non autenticato');
      }

      print('Eliminando piano di allenamento: $planId');

      // Verifica che il piano appartenga all'utente corrente
      final doc = await _firestore
          .collection(_collection)
          .doc(planId)
          .get();

      if (!doc.exists) {
        return WorkoutPlanResult.failure('Piano non trovato');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        return WorkoutPlanResult.failure('Non autorizzato a eliminare questo piano');
      }

      // Elimina il documento
      await _firestore
          .collection(_collection)
          .doc(planId)
          .delete();

      print('Piano di allenamento eliminato con successo');
      return WorkoutPlanResult.success();

    } on FirebaseException catch (e) {
      print('Errore Firebase durante l\'eliminazione: ${e.code} - ${e.message}');
      return WorkoutPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante l\'eliminazione del piano: $e');
      return WorkoutPlanResult.failure(
        'Errore imprevisto durante l\'eliminazione: ${e.toString()}'
      );
    }
  }

  // Test di connessione a Firestore
  Future<bool> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      
      if (!_isAuthenticated) {
        print('Test fallito: utente non autenticato');
        return false;
      }
      
      // Test semplice di lettura
      final testQuery = await _firestore
          .collection('test')
          .limit(1)
          .get();
      
      print('Test connessione Firestore: OK');
      return true;
    } catch (e) {
      print('Test connessione Firestore fallito: $e');
      return false;
    }
  }

  // Converte gli errori Firebase in messaggi user-friendly
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permesso negato. Verifica di essere autenticato.';
      case 'not-found':
        return 'Piano di allenamento non trovato.';
      case 'already-exists':
        return 'Un piano con questi dati esiste già.';
      case 'resource-exhausted':
        return 'Quota di utilizzo superata. Riprova più tardi.';
      case 'failed-precondition':
        return 'Operazione non consentita nello stato corrente.';
      case 'aborted':
        return 'Operazione annullata a causa di un conflitto.';
      case 'out-of-range':
        return 'Operazione fuori dal range consentito.';
      case 'unimplemented':
        return 'Operazione non implementata.';
      case 'internal':
        return 'Errore interno del server. Riprova più tardi.';
      case 'unavailable':
        return 'Servizio temporaneamente non disponibile.';
      case 'data-loss':
        return 'Perdita di dati irreversibile.';
      case 'unauthenticated':
        return 'Autenticazione richiesta.';
      case 'deadline-exceeded':
        return 'Timeout dell\'operazione.';
      case 'cancelled':
        return 'Operazione annullata.';
      case 'invalid-argument':
        return 'Argomenti non validi forniti.';
      default:
        return e.message ?? 'Errore durante l\'operazione su Firebase.';
    }
  }

  // Debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentUserId': _currentUserId ?? 'Nessuno',
      'isAuthenticated': _isAuthenticated,
      'collection': _collection,
      'firestoreApp': _firestore.app.name,
    };
  }
}