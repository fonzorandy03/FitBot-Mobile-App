import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modello dati per il pasto
class Meal {
  final String nome;
  final String tipo; // "colazione", "pranzo", "cena", "spuntino"
  final List<String> ingredienti;
  final int calorie;
  final Map<String, double> macronutrienti; // proteine, carboidrati, grassi in grammi
  final String? preparazione;
  final int tempoPreparazioneMin;

  Meal({
    required this.nome,
    required this.tipo,
    required this.ingredienti,
    required this.calorie,
    required this.macronutrienti,
    this.preparazione,
    required this.tempoPreparazioneMin,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'ingredienti': ingredienti,
      'calorie': calorie,
      'macronutrienti': macronutrienti,
      'preparazione': preparazione,
      'tempo_preparazione_min': tempoPreparazioneMin,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      nome: map['nome']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      ingredienti: List<String>.from(map['ingredienti'] ?? []),
      calorie: (map['calorie'] as num?)?.toInt() ?? 0,
      macronutrienti: Map<String, double>.from(
        (map['macronutrienti'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
        ) ?? {},
      ),
      preparazione: map['preparazione']?.toString(),
      tempoPreparazioneMin: (map['tempo_preparazione_min'] as num?)?.toInt() ?? 0,
    );
  }
}

// Modello dati per il giorno alimentare
class DietDay {
  final String giorno;
  final List<Meal> pasti;
  final int calorieTotali;
  final Map<String, double> macronutrientiTotali;

  DietDay({
    required this.giorno,
    required this.pasti,
    required this.calorieTotali,
    required this.macronutrientiTotali,
  });

  Map<String, dynamic> toMap() {
    return {
      'giorno': giorno,
      'pasti': pasti.map((p) => p.toMap()).toList(),
      'calorie_totali': calorieTotali,
      'macronutrienti_totali': macronutrientiTotali,
    };
  }

  factory DietDay.fromMap(Map<String, dynamic> map) {
    var pastiList = <Meal>[];
    if (map['pasti'] != null) {
      for (var pasto in map['pasti']) {
        if (pasto is Map<String, dynamic>) {
          pastiList.add(Meal.fromMap(pasto));
        }
      }
    }
    
    return DietDay(
      giorno: map['giorno']?.toString() ?? '',
      pasti: pastiList,
      calorieTotali: (map['calorie_totali'] as num?)?.toInt() ?? 0,
      macronutrientiTotali: Map<String, double>.from(
        (map['macronutrienti_totali'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
        ) ?? {},
      ),
    );
  }
}

// Modello dati per il piano alimentare completo
class DietPlan {
  final String? id;
  final String userId;
  final String titolo;
  final int eta;
  final double peso;
  final double altezza;
  final String livelloAttivita;
  final String obiettivo;
  final List<String> intolleranze;
  final String? preferenze;
  final int calorieTotaliGiornaliere;
  final Map<String, double> macronutrientiGiornalieri;
  final List<DietDay> giorni;
  final List<String> consigli;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  DietPlan({
    this.id,
    required this.userId,
    required this.titolo,
    required this.eta,
    required this.peso,
    required this.altezza,
    required this.livelloAttivita,
    required this.obiettivo,
    required this.intolleranze,
    this.preferenze,
    required this.calorieTotaliGiornaliere,
    required this.macronutrientiGiornalieri,
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
      'eta': eta,
      'peso': peso,
      'altezza': altezza,
      'livello_attivita': livelloAttivita,
      'obiettivo': obiettivo,
      'intolleranze': intolleranze,
      'preferenze': preferenze,
      'calorie_totali_giornaliere': calorieTotaliGiornaliere,
      'macronutrienti_giornalieri': macronutrientiGiornalieri,
      'giorni': giorni.map((d) => d.toMap()).toList(),
      'consigli': consigli,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory DietPlan.fromMap(Map<String, dynamic> map, String documentId) {
    var giorniList = <DietDay>[];
    if (map['giorni'] != null) {
      for (var giorno in map['giorni']) {
        if (giorno is Map<String, dynamic>) {
          giorniList.add(DietDay.fromMap(giorno));
        }
      }
    }

    var consigliList = <String>[];
    if (map['consigli'] != null) {
      for (var consiglio in map['consigli']) {
        consigliList.add(consiglio.toString());
      }
    }

    var intolleranzeList = <String>[];
    if (map['intolleranze'] != null) {
      for (var intolleranza in map['intolleranze']) {
        intolleranzeList.add(intolleranza.toString());
      }
    }

    return DietPlan(
      id: documentId,
      userId: map['userId']?.toString() ?? '',
      titolo: map['titolo']?.toString() ?? '',
      eta: (map['eta'] as num?)?.toInt() ?? 0,
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      altezza: (map['altezza'] as num?)?.toDouble() ?? 0.0,
      livelloAttivita: map['livello_attivita']?.toString() ?? '',
      obiettivo: map['obiettivo']?.toString() ?? '',
      intolleranze: intolleranzeList,
      preferenze: map['preferenze']?.toString(),
      calorieTotaliGiornaliere: (map['calorie_totali_giornaliere'] as num?)?.toInt() ?? 0,
      macronutrientiGiornalieri: Map<String, double>.from(
        (map['macronutrienti_giornalieri'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
        ) ?? {},
      ),
      giorni: giorniList,
      consigli: consigliList,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] == true,
    );
  }

  DietPlan copyWith({
    String? id,
    String? userId,
    String? titolo,
    int? eta,
    double? peso,
    double? altezza,
    String? livelloAttivita,
    String? obiettivo,
    List<String>? intolleranze,
    String? preferenze,
    int? calorieTotaliGiornaliere,
    Map<String, double>? macronutrientiGiornalieri,
    List<DietDay>? giorni,
    List<String>? consigli,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return DietPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titolo: titolo ?? this.titolo,
      eta: eta ?? this.eta,
      peso: peso ?? this.peso,
      altezza: altezza ?? this.altezza,
      livelloAttivita: livelloAttivita ?? this.livelloAttivita,
      obiettivo: obiettivo ?? this.obiettivo,
      intolleranze: intolleranze ?? this.intolleranze,
      preferenze: preferenze ?? this.preferenze,
      calorieTotaliGiornaliere: calorieTotaliGiornaliere ?? this.calorieTotaliGiornaliere,
      macronutrientiGiornalieri: macronutrientiGiornalieri ?? this.macronutrientiGiornalieri,
      giorni: giorni ?? this.giorni,
      consigli: consigli ?? this.consigli,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Risultato delle operazioni del DAO
class DietPlanResult {
  final bool success;
  final String? error;
  final DietPlan? dietPlan;
  final List<DietPlan>? dietPlans;
  final String? errorCode;

  DietPlanResult({
    required this.success,
    this.error,
    this.dietPlan,
    this.dietPlans,
    this.errorCode,
  });

  factory DietPlanResult.success({DietPlan? plan, List<DietPlan>? plans}) {
    return DietPlanResult(
      success: true,
      dietPlan: plan,
      dietPlans: plans,
    );
  }

  factory DietPlanResult.failure(String error, [String? errorCode]) {
    return DietPlanResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

class DietPlanDAO {
  static final DietPlanDAO _instance = DietPlanDAO._internal();
  factory DietPlanDAO() => _instance;
  DietPlanDAO._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Nome della collezione
  static const String _collection = 'diet_plans';

  // Getter per l'utente corrente
  String? get _currentUserId => _auth.currentUser?.uid;

  // Verifica se l'utente è autenticato
  bool get _isAuthenticated => _currentUserId != null;

  // Validazione dati prima del salvataggio
  bool _validateDietPlan(DietPlan dietPlan) {
    if (dietPlan.titolo.trim().isEmpty) {
      print('Errore validazione: titolo vuoto');
      return false;
    }
    
    if (dietPlan.userId.trim().isEmpty) {
      print('Errore validazione: userId vuoto');
      return false;
    }
    
    if (dietPlan.eta <= 0 || dietPlan.eta > 150) {
      print('Errore validazione: età non valida');
      return false;
    }
    
    if (dietPlan.peso <= 0 || dietPlan.peso > 500) {
      print('Errore validazione: peso non valido');
      return false;
    }
    
    if (dietPlan.altezza <= 0 || dietPlan.altezza > 300) {
      print('Errore validazione: altezza non valida');
      return false;
    }
    
    if (dietPlan.giorni.isEmpty) {
      print('Errore validazione: nessun giorno nel piano alimentare');
      return false;
    }
    
    // Verifica che ogni giorno abbia almeno un pasto
    for (var giorno in dietPlan.giorni) {
      if (giorno.pasti.isEmpty) {
        print('Errore validazione: giorno ${giorno.giorno} senza pasti');
        return false;
      }
      
      // Verifica che ogni pasto sia valido
      for (var pasto in giorno.pasti) {
        if (pasto.nome.trim().isEmpty) {
          print('Errore validazione: pasto senza nome nel giorno ${giorno.giorno}');
          return false;
        }
        if (pasto.calorie < 0) {
          print('Errore validazione: calorie negative per ${pasto.nome}');
          return false;
        }
        if (pasto.ingredienti.isEmpty) {
          print('Errore validazione: pasto ${pasto.nome} senza ingredienti');
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
      print('Disattivando piani alimentari precedenti per utente: $_currentUserId');
      
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
            print('Disattivando piano alimentare: ${doc.id}');
            batch.update(doc.reference, {
              'isActive': false,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          }
        }

        await batch.commit();
        print('${querySnapshot.docs.length} piani alimentari precedenti disattivati');
      } else {
        print('Nessun piano alimentare attivo da disattivare');
      }
    } catch (e) {
      print('Errore durante la disattivazione dei piani alimentari: $e');
      // Non lanciare l'errore per non bloccare il salvataggio principale
    }
  }

  // Salva un nuovo piano alimentare
  Future<DietPlanResult> saveDietPlan(DietPlan dietPlan) async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      print('Salvando piano alimentare per utente: $_currentUserId');

      // Assicurati che il piano sia associato all'utente corrente
      final planToSave = dietPlan.copyWith(
        userId: _currentUserId!,
        createdAt: DateTime.now(),
      );

      // Validazione dati
      if (!_validateDietPlan(planToSave)) {
        return DietPlanResult.failure('Dati del piano alimentare non validi');
      }

      // Prepara e pulisce i dati per il salvataggio
      final dataToSave = _sanitizeData(planToSave.toMap());
      
      print('Dati da salvare: ${dataToSave.keys}');
      
      // Salva il documento PRIMA di disattivare gli altri
      final docRef = _firestore.collection(_collection).doc();
      
      await docRef.set(dataToSave);
      print('Piano alimentare salvato con ID: ${docRef.id}');
      
      // Disattiva eventuali piani precedenti DOPO il salvataggio se questo è attivo
      if (planToSave.isActive) {
        await _deactivateOtherPlans(excludeId: docRef.id);
      }

      final savedPlan = planToSave.copyWith(id: docRef.id);
      
      return DietPlanResult.success(plan: savedPlan);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il salvataggio: ${e.code} - ${e.message}');
      print('Stack trace: ${e.stackTrace}');
      return DietPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e, stackTrace) {
      print('Errore durante il salvataggio del piano alimentare: $e');
      print('Stack trace: $stackTrace');
      return DietPlanResult.failure(
        'Errore imprevisto durante il salvataggio: ${e.toString()}'
      );
    }
  }

  // Recupera tutti i piani alimentari dell'utente corrente
  Future<DietPlanResult> getUserDietPlans({bool activeOnly = false}) async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      print('Recuperando piani alimentari per utente: $_currentUserId');

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      
      final plans = <DietPlan>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final plan = DietPlan.fromMap(data, doc.id);
          plans.add(plan);
        } catch (e) {
          print('Errore parsing documento ${doc.id}: $e');
          // Continua con gli altri documenti
        }
      }

      print('Recuperati ${plans.length} piani alimentari');
      return DietPlanResult.success(plans: plans);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il recupero: ${e.code} - ${e.message}');
      return DietPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante il recupero dei piani alimentari: $e');
      return DietPlanResult.failure(
        'Errore imprevisto durante il recupero: ${e.toString()}'
      );
    }
  }

  // Recupera il piano alimentare attivo
  Future<DietPlanResult> getActiveDietPlan() async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return DietPlanResult.failure('Nessun piano alimentare attivo trovato');
      }

      final doc = querySnapshot.docs.first;
      final plan = DietPlan.fromMap(
        doc.data() as Map<String, dynamic>, 
        doc.id
      );

      print('Piano alimentare attivo recuperato: ${plan.id}');
      return DietPlanResult.success(plan: plan);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante il recupero piano attivo: ${e.code} - ${e.message}');
      return DietPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante il recupero del piano alimentare attivo: $e');
      return DietPlanResult.failure(
        'Errore imprevisto durante il recupero: ${e.toString()}'
      );
    }
  }

  // Aggiorna un piano esistente
  Future<DietPlanResult> updateDietPlan(DietPlan dietPlan) async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      if (dietPlan.id == null) {
        return DietPlanResult.failure('ID del piano non specificato');
      }

      print('Aggiornando piano alimentare: ${dietPlan.id}');

      // Assicurati che il piano sia associato all'utente corrente
      final planToUpdate = dietPlan.copyWith(
        userId: _currentUserId!,
        updatedAt: DateTime.now(),
      );

      // Validazione dati
      if (!_validateDietPlan(planToUpdate)) {
        return DietPlanResult.failure('Dati del piano alimentare non validi');
      }

      // Prepara e pulisce i dati per l'aggiornamento
      final dataToUpdate = _sanitizeData(planToUpdate.toMap());
      
      // Aggiorna il documento
      await _firestore
          .collection(_collection)
          .doc(dietPlan.id!)
          .update(dataToUpdate);

      // Se il piano aggiornato è attivo, disattiva gli altri
      if (planToUpdate.isActive) {
        await _deactivateOtherPlans(excludeId: dietPlan.id!);
      }

      print('Piano alimentare aggiornato con successo');
      return DietPlanResult.success(plan: planToUpdate);

    } on FirebaseException catch (e) {
      print('Errore Firebase durante l\'aggiornamento: ${e.code} - ${e.message}');
      return DietPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e, stackTrace) {
      print('Errore durante l\'aggiornamento del piano alimentare: $e');
      print('Stack trace: $stackTrace');
      return DietPlanResult.failure(
        'Errore imprevisto durante l\'aggiornamento: ${e.toString()}'
      );
    }
  }

  // Elimina un piano alimentare
  Future<DietPlanResult> deleteDietPlan(String planId) async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      print('Eliminando piano alimentare: $planId');

      // Verifica che il piano appartenga all'utente corrente
      final doc = await _firestore
          .collection(_collection)
          .doc(planId)
          .get();

      if (!doc.exists) {
        return DietPlanResult.failure('Piano alimentare non trovato');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        return DietPlanResult.failure('Non autorizzato a eliminare questo piano alimentare');
      }

      // Elimina il documento
      await _firestore
          .collection(_collection)
          .doc(planId)
          .delete();

      print('Piano alimentare eliminato con successo');
      return DietPlanResult.success();

    } on FirebaseException catch (e) {
      print('Errore Firebase durante l\'eliminazione: ${e.code} - ${e.message}');
      return DietPlanResult.failure(
        _getFirebaseErrorMessage(e), 
        e.code
      );
    } catch (e) {
      print('Errore durante l\'eliminazione del piano alimentare: $e');
      return DietPlanResult.failure(
        'Errore imprevisto durante l\'eliminazione: ${e.toString()}'
      );
    }
  }

  // Crea un piano alimentare di base da DietScreen
  Future<DietPlanResult> createDietPlanFromForm({
    required int eta,
    required double peso,
    required double altezza,
    required String livelloAttivita,
    required String obiettivo,
    required List<String> intolleranze,
    String? preferenze,
  }) async {
    try {
      if (!_isAuthenticated) {
        return DietPlanResult.failure('Utente non autenticato');
      }

      print('Creando piano alimentare da form per utente: $_currentUserId');

      // Calcolo BMR usando la formula di Mifflin-St Jeor (semplificata, assumendo sesso maschile)
      double bmr = 10 * peso + 6.25 * altezza - 5 * eta + 5;
      
      // Fattori di attività
      double activityFactor = _getActivityFactor(livelloAttivita);
      double tdee = bmr * activityFactor;
      
      // Aggiustamenti per obiettivo
      int calorieTotali = _adjustCaloriesForGoal(tdee, obiettivo);
      
      // Distribuzione macronutrienti di base
      Map<String, double> macros = _calculateMacronutrients(calorieTotali, obiettivo);

      // Crea un titolo automatico
      String titolo = 'Piano Alimentare - ${_formatGoal(obiettivo)}';
      
      // Crea giorni di esempio (da implementare con AI in futuro)
      List<DietDay> giorni = _createBasicDietDays(calorieTotali, macros, intolleranze);
      
      // Consigli generali
      List<String> consigli = _generateBasicAdvice(obiettivo, intolleranze);

      final dietPlan = DietPlan(
        userId: _currentUserId!,
        titolo: titolo,
        eta: eta,
        peso: peso,
        altezza: altezza,
        livelloAttivita: livelloAttivita,
        obiettivo: obiettivo,
        intolleranze: intolleranze,
        preferenze: preferenze,
        calorieTotaliGiornaliere: calorieTotali,
        macronutrientiGiornalieri: macros,
        giorni: giorni,
        consigli: consigli,
        createdAt: DateTime.now(),
      );

      return await saveDietPlan(dietPlan);

    } catch (e, stackTrace) {
      print('Errore durante la creazione del piano da form: $e');
      print('Stack trace: $stackTrace');
      return DietPlanResult.failure(
        'Errore durante la creazione del piano alimentare: ${e.toString()}'
      );
    }
  }

  // Helper methods per calcoli nutrizionali
  double _getActivityFactor(String livelloAttivita) {
    switch (livelloAttivita.toLowerCase()) {
      case 'sedentario':
        return 1.2;
      case 'leggero':
        return 1.375;
      case 'moderato':
        return 1.55;
      case 'attivo':
        return 1.725;
      case 'molto attivo':
        return 1.9;
      default:
        return 1.55; // Default moderato
    }
  }

  int _adjustCaloriesForGoal(double tdee, String obiettivo) {
    switch (obiettivo.toLowerCase()) {
      case 'perdere peso':
        return (tdee * 0.8).round(); // Deficit del 20%
      case 'aumentare massa':
        return (tdee * 1.15).round(); // Surplus del 15%
      case 'mantenere il peso':
      default:
        return tdee.round();
    }
  }

  Map<String, double> _calculateMacronutrients(int calorie, String obiettivo) {
    double proteine, carboidrati, grassi;
    
    switch (obiettivo.toLowerCase()) {
      case 'perdere peso':
        // Alte proteine, bassi carboidrati
        proteine = calorie * 0.35 / 4; // 35% proteine
        carboidrati = calorie * 0.35 / 4; // 35% carboidrati  
        grassi = calorie * 0.30 / 9; // 30% grassi
        break;
      case 'aumentare massa':
        // Moderate proteine, alti carboidrati
        proteine = calorie * 0.25 / 4; // 25% proteine
        carboidrati = calorie * 0.50 / 4; // 50% carboidrati
        grassi = calorie * 0.25 / 9; // 25% grassi
        break;
      case 'mantenere il peso':
      default:
        // Distribuzione bilanciata
        proteine = calorie * 0.25 / 4; // 25% proteine
        carboidrati = calorie * 0.45 / 4; // 45% carboidrati
        grassi = calorie * 0.30 / 9; // 30% grassi
        break;
    }
    
    return {
      'proteine': proteine,
      'carboidrati': carboidrati,
      'grassi': grassi,
    };
  }

  String _formatGoal(String obiettivo) {
    switch (obiettivo.toLowerCase()) {
      case 'perdere peso':
        return 'Dimagrimento';
      case 'aumentare massa':
        return 'Aumento Massa';
      case 'mantenere il peso':
        return 'Mantenimento';
      default:
        return 'Personalizzato';
    }
  }

  List<DietDay> _createBasicDietDays(int calorie, Map<String, double> macros, List<String> intolleranze) {
    // Questo è un esempio di base - in una vera implementazione useresti AI per generare i pasti
    List<DietDay> giorni = [];
    
    List<String> giorniSettimana = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
    ];
    
    for (String giorno in giorniSettimana) {
      List<Meal> pasti = _createBasicMeals(calorie, macros, intolleranze);
      
      int calorieTotaliGiorno = pasti.fold(0, (sum, pasto) => sum + pasto.calorie);
      
      Map<String, double> macrosTotali = {
        'proteine': pasti.fold(0.0, (sum, pasto) => sum + (pasto.macronutrienti['proteine'] ?? 0)),
        'carboidrati': pasti.fold(0.0, (sum, pasto) => sum + (pasto.macronutrienti['carboidrati'] ?? 0)),
        'grassi': pasti.fold(0.0, (sum, pasto) => sum + (pasto.macronutrienti['grassi'] ?? 0)),
      };
      
      giorni.add(DietDay(
        giorno: giorno,
        pasti: pasti,
        calorieTotali: calorieTotaliGiorno,
        macronutrientiTotali: macrosTotali,
      ));
    }
    
    return giorni;
  }

  List<Meal> _createBasicMeals(int calorie, Map<String, double> macros, List<String> intolleranze) {
    // Distribuisci le calorie tra i pasti
    int calorieColazione = (calorie * 0.25).round();
    int caloriePranzo = (calorie * 0.35).round();
    int calorieCena = (calorie * 0.30).round();
    int calorieSpuntini = calorie - calorieColazione - caloriePranzo - calorieCena;
    
    List<Meal> pasti = [];
    
    // Colazione
    pasti.add(Meal(
      nome: _getBreakfastMeal(intolleranze),
      tipo: 'colazione',
      ingredienti: _getBreakfastIngredients(intolleranze),
      calorie: calorieColazione,
      macronutrienti: _distributeMacros(calorieColazione, macros),
      tempoPreparazioneMin: 10,
      preparazione: 'Mescola tutti gli ingredienti e servi',
    ));
    
    // Spuntino mattutino
    pasti.add(Meal(
      nome: 'Spuntino Mattutino',
      tipo: 'spuntino',
      ingredienti: ['Frutta di stagione', 'Frutta secca (se tollerata)'],
      calorie: (calorieSpuntini * 0.4).round(),
      macronutrienti: _distributeMacros((calorieSpuntini * 0.4).round(), macros),
      tempoPreparazioneMin: 5,
    ));
    
    // Pranzo
    pasti.add(Meal(
      nome: 'Pranzo Bilanciato',
      tipo: 'pranzo',
      ingredienti: ['Proteine magre', 'Carboidrati complessi', 'Verdure', 'Olio EVO'],
      calorie: caloriePranzo,
      macronutrienti: _distributeMacros(caloriePranzo, macros),
      tempoPreparazioneMin: 25,
      preparazione: 'Cucina le proteine, prepara i carboidrati e condisci le verdure',
    ));
    
    // Spuntino pomeridiano
    pasti.add(Meal(
      nome: 'Spuntino Pomeridiano',
      tipo: 'spuntino',
      ingredienti: ['Yogurt (se tollerato)', 'Frutta', 'Semi'],
      calorie: (calorieSpuntini * 0.6).round(),
      macronutrienti: _distributeMacros((calorieSpuntini * 0.6).round(), macros),
      tempoPreparazioneMin: 5,
    ));
    
    // Cena
    pasti.add(Meal(
      nome: 'Cena Leggera',
      tipo: 'cena',
      ingredienti: ['Proteine magre', 'Verdure', 'Grassi buoni'],
      calorie: calorieCena,
      macronutrienti: _distributeMacros(calorieCena, macros),
      tempoPreparazioneMin: 20,
      preparazione: 'Prepara una cena leggera ma nutriente',
    ));
    
    return pasti;
  }

  String _getBreakfastMeal(List<String> intolleranze) {
    if (intolleranze.contains('Glutine')) {
      return 'Colazione Senza Glutine';
    } else if (intolleranze.contains('Lattosio')) {
      return 'Colazione Senza Lattosio';
    } else {
      return 'Colazione Classica';
    }
  }

  List<String> _getBreakfastIngredients(List<String> intolleranze) {
    List<String> base = ['Avena', 'Frutta fresca', 'Semi di chia'];
    
    if (!intolleranze.contains('Lattosio')) {
      base.add('Latte o yogurt');
    } else {
      base.add('Latte vegetale');
    }
    
    if (!intolleranze.contains('Frutta secca')) {
      base.add('Mandorle');
    }
    
    return base;
  }

  Map<String, double> _distributeMacros(int calorie, Map<String, double> targetMacros) {
    double factor = calorie / 2000; // Normalizza su base 2000 calorie
    
    return {
      'proteine': (targetMacros['proteine']! * factor),
      'carboidrati': (targetMacros['carboidrati']! * factor),
      'grassi': (targetMacros['grassi']! * factor),
    };
  }

  List<String> _generateBasicAdvice(String obiettivo, List<String> intolleranze) {
    List<String> consigli = [
      'Bevi almeno 2 litri di acqua al giorno',
      'Mangia lentamente e mastica bene',
      'Cerca di rispettare gli orari dei pasti',
    ];
    
    switch (obiettivo.toLowerCase()) {
      case 'perdere peso':
        consigli.addAll([
          'Controlla le porzioni attentamente',
          'Evita bevande zuccherate',
          'Incrementa il consumo di verdure',
        ]);
        break;
      case 'aumentare massa':
        consigli.addAll([
          'Non saltare mai i pasti',
          'Aggiungi spuntini proteici tra i pasti',
          'Assumi proteine entro 30 min dall\'allenamento',
        ]);
        break;
      case 'mantenere il peso':
        consigli.addAll([
          'Mantieni un equilibrio tra tutti i macronutrienti',
          'Varia spesso i cibi per evitare carenze',
        ]);
        break;
    }
    
    if (intolleranze.isNotEmpty) {
      consigli.add('Leggi sempre le etichette per evitare gli alimenti che non tolleri');
    }
    
    return consigli;
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
        return 'Piano alimentare non trovato.';
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