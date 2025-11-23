import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'WorkoutPlanDao.dart';

class GeneratedWorkoutPlanScreen extends StatefulWidget {
  final int age;
  final String frequency;
  final String goal;
  final String experience;
  final String additionalNotes;

  const GeneratedWorkoutPlanScreen({
    super.key,
    required this.age,
    required this.frequency,
    required this.goal,
    required this.experience,
    required this.additionalNotes,
  });

  @override
  _GeneratedWorkoutPlanScreenState createState() => _GeneratedWorkoutPlanScreenState();
}

class _GeneratedWorkoutPlanScreenState extends State<GeneratedWorkoutPlanScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic>? _workoutPlan;
  String? _errorMessage;
  
  // Sostituisci con la tua API key di Google AI Studio
  static const String API_KEY = 'AIzaSyBVgybJ6nWOHZ9VbiI6-efhzGFUF7HVEIg';
  static const String API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  @override
  void initState() {
    super.initState();
    
    _loadingController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_loadingController);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadingController.repeat();
    _generateWorkoutPlan();
    
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
    
  }

  Future<void> _generateWorkoutPlan() async {
    try {
      final prompt = _buildPrompt();
      
      final response = await http.post(
        Uri.parse('$API_URL?key=$API_KEY'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parsing del piano generato
        setState(() {
          _workoutPlan = _parseWorkoutPlan(generatedText);
          _isLoading = false;
        });
        
        // Salva il piano generato
        await _saveWorkoutPlan();
        _fadeController.forward();
      } else {
        throw Exception('Errore API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

Future<void> _saveWorkoutPlan() async {
  if (_workoutPlan == null) return;
  
  try {
    final workoutPlan = WorkoutPlan(
      userId: '', // Sarà impostato automaticamente dal DAO
      titolo: _workoutPlan!['titolo'],
      obiettivo: _workoutPlan!['obiettivo'],
      frequenza: _workoutPlan!['frequenza'],
      experience: widget.experience,           // AGGIUNGI QUESTO
      additionalNotes: widget.additionalNotes.isEmpty ? null : widget.additionalNotes, // AGGIUNGI QUESTO
      duratSettimane: _workoutPlan!['durata_settimane'],
      eta: widget.age,
      giorni: (_workoutPlan!['giorni'] as List).map((g) => 
        WorkoutDay.fromMap(g)
      ).toList(),
      consigli: List<String>.from(_workoutPlan!['consigli']),
      createdAt: DateTime.now(),
    );

    final workoutDAO = WorkoutPlanDAO();
    final result = await workoutDAO.saveWorkoutPlan(workoutPlan);

    if (result.success) {
      print('Piano salvato con successo!');
    } else {
      print('Errore nel salvataggio: ${result.error}');
    }
  } catch (e) {
    print('Errore durante il salvataggio: $e');
  }
}
String _buildPrompt() {
  final notesLine = widget.additionalNotes.isNotEmpty 
      ? '- LIMITAZIONI/INFORTUNI: ${widget.additionalNotes}\n'
      : '';
   
  return '''
Agisci come un personal trainer certificato ACSM/NASM con esperienza evidence-based. Utilizza i principi della programmazione scientifica moderna per creare un piano personalizzato.

=== DATI CLIENTE ===
- Età: ${widget.age} anni
- Frequenza: ${widget.frequency}
- Obiettivo: ${widget.goal}
- Esperienza: ${widget.experience}
$notesLine

=== PRINCIPI SCIENCE-BASED DA APPLICARE ===

GESTIONE INFORTUNI/LIMITAZIONI (PRIORITÀ MASSIMA):
${widget.additionalNotes.isNotEmpty ? '''
ANALISI LIMITAZIONI: "${widget.additionalNotes}"
- Se schiena: EVITA stacchi, squat con bilanciere, military press, rowing bent-over
- Se polpaccio: EVITA affondi, salti, calf raises, esercizi in piedi prolungati
- Se spalle: EVITA overhead press, dips, pull-up dietro nuca
- SOLO in presenza di limitazioni specifiche: preferisci macchine guidate, esercizi da seduto, ROM parziali
- SOSTITUZIONI SEMPRE obbligatorie per zone problematiche
- Se NON ci sono limitazioni specifiche: usa esercizi tradizionali (panca piana, rematore in piedi, etc.)''' : 'NESSUNA LIMITAZIONE: Usa esercizi tradizionali nella loro forma standard (panca piana, rematore in piedi, military press, etc.)'}

VOLUME TRAINING (Schoenfeld et al., 2024):
- Neofita: 8-12 serie/muscolo/settimana, 2x frequenza
- Intermedio: 12-18 serie/muscolo/settimana, 2-3x frequenza  
- Avanzato: 16-24 serie/muscolo/settimana, 2-3x frequenza

INTENSITÀ E RANGE REPS (Helms et al., 2024):
- Forza: 1-5 reps all'85-95% 1RM
- Ipertrofia: 5-30 reps (sweet spot 8-15), RPE 7-9
- Resistenza: 15-25+ reps al 50-70% 1RM
- Failure training: non necessario, RPE 8-9 sufficiente

FREQUENZA OTTIMALE (Grgic et al., 2024):
- Volume equated: 1x vs 2x vs 3x/settimana = risultati simili
- Distribuzione preferita: 2x/settimana per muscolo per recupero ottimale
- Frequenza alta giustificata solo per volumi elevati (20+ serie/muscolo)

RECUPERO TRA SERIE:
- Compound movements: 2-3 minuti
- Isolation movements: 1-2 minuti
- Se obiettivo forza: 3-5 minuti
- Non abbreviare per "conditioning" se obiettivo è ipertrofia

SELEZIONE ESERCIZI EVIDENCE-BASED:
- 70% compound (squat, deadlift, press, pull patterns)
- 30% isolation per target specifici
- Progressione: padronanza movimento → carico → volume → complessità

=== PROGRAMMAZIONE PER LIVELLO ===

NEOFITA (0-6 mesi):
- Focus: imparare movimenti base e costruire abitudine
- Linguaggio: SOLO parole semplici - NO termini tecnici (RPE, ROM, eccentrico, concentrico)
- Volume: 6-9 serie totali/seduta, massimo 3-4 esercizi
- Esercizi: SOLO macchine guidate e manubri leggeri per sicurezza
- Ripetizioni: 12-15 reps
- Recupero: 90-120 secondi
- Note: "vai piano", "fermati se fa male", "senti lavorare il muscolo"
- Progressione: aumenta peso solo quando riesci a fare tutte le ripetizioni facilmente

INTERMEDIO (6-24 mesi):
- Focus: ipertrofia e forza bilanciata
- Volume: 12-16 serie totali/seduta
- Intensità: 70-85% 1RM, RPE 7-8
- Ripetizioni: 8-12 reps principalmente
- Recupero: 120-150 secondi
- Mix: 60% liberi, 40% macchine
- Periodizzazione: linear progression con deload ogni 4-6 settimane
- Tecniche base: drop set leggeri, pause rest occasionali

AVANZATO (2+ anni):
- Focus: specializzazione e tecniche avanzate
- Volume: 16-20 serie totali/seduta
- Intensità: auto-regolazione RPE, tecniche intensity
- Ripetizioni: SOLO "6-9" reps per forza O "8-12" reps per ipertrofia (OBBLIGATORIO RISPETTARE)
- Recupero compound: 150-180 secondi (2,30-3 minuti) OBBLIGATORIO
- Recupero isolation: 120-150 secondi OBBLIGATORIO  
- Cedimento: ogni serie deve arrivare a cedimento tecnico (OBBLIGATORIO)
- Periodizzazione: DUP o block periodization
- Linguaggio: terminologia tecnica completa
- Tecniche avanzate: rest-pause, drop set, cluster set, eccentriche lente

=== ADATTAMENTI PER OBIETTIVO ===

IPERTROFIA:
- Range: 8-15 reps primario, 6-8 e 15-20 accessori
- Volume: tendere al limite superiore per livello
- TUT: 2-4 sec eccentrica, 1-2 sec concentrica
- Frequency: 2x/settimana per muscolo minimo

FORZA:
- Range: 1-6 reps, focus 3-5 reps
- Volume: moderato, intensità alta
- Specificità: pattern motori competition lifts
- Frequency: 3-4x/settimana per lifts principali

PERDITA PESO:
- Range: 8-15 reps per preservare massa
- Circuit training accettabile se volume mantenuto
- Deficit: non oltre 500-750 kcal/die
- Cardio: HIIT 10-15min post-workout opzionale

=== CONSIDERAZIONI ETÀ ===

UNDER 25:
- Tolleranza volume alta
- Recupero veloce
- Progressioni aggressive accettabili

OVER 40:
- Warm-up esteso (10-15 min)
- Enfasi mobilità articolare
- Progressioni conservative
- Recovery extra 24-48h se necessario

=== REGOLE SPECIFICHE PER ESERCIZI ===

POSIZIONI STANDARD (se non ci sono limitazioni):
- Panca piana: SEMPRE sdraiato su panca, MAI seduto
- Rematore: SEMPRE in piedi o piegato in avanti, MAI seduto (eccetto se problemi schiena)
- Military press: SEMPRE in piedi, MAI seduto (eccetto se problemi schiena)
- Squat: SEMPRE in piedi
- Stacchi: SEMPRE in piedi

USA "SEDUTO" SOLO SE:
- C'è una limitazione specifica alla schiena nelle note
- È un esercizio che richiede naturalmente la posizione seduta (leg extension, seated row machine)
- È specificatamente una variante da seduto per sicurezza (es: shoulder press da seduto per neofiti)

=== OUTPUT RICHIESTO ===
Restituisci SOLO JSON valido senza testo extra:

ESEMPI LINGUAGGIO PER LIVELLO:

NEOFITA - Note negli esercizi:
- "Vai piano, conta fino a 2 quando abbassi il peso"
- "Fermati se senti dolore"  
- "Senti lavorare il muscolo del petto"
- "Piedi ben piantati a terra"
- "Respira normalmente, non trattenere il fiato"

INTERMEDIO - Note negli esercizi:
- "Focus sul controllo del movimento"
- "Range di movimento completo"
- "Arriva quasi a cedimento"
- "Respirazione controllata"
- "Occasionalmente usa drop set leggeri"

AVANZATO - Note negli esercizi (OBBLIGATORIO SEGUIRE):
- "Recupero 2,30-3 minuti tra le serie"  
- "Cedimento tecnico ogni serie"
- "Range 6-9 reps per forza, 8-12 per ipertrofia"
- "ROM completo, controllo eccentrico"
- "Applica tecniche di intensità quando indicato (rest-pause, drop set, cluster)"

{
  "titolo": "Piano Evidence-Based Personalizzato",
  "obiettivo": "${widget.goal}",
  "frequenza": "${widget.frequency}",
  "durata_settimane": 8,
  "giorni": [
    {
      "giorno": "Lunedì",
      "focus": "Petto e Braccia",
      "esercizi": [
        {
          "nome": "Riscaldamento braccia e spalle",
          "serie": 1,
          "ripetizioni": "10",
          "riposo_sec": 60,
          "note": "Movimenti lenti e controllati per scaldare"
        },
        {
          "nome": "Panca piana con bilanciere",
          "serie": 4,
          "ripetizioni": "8-12",
          "riposo_sec": 180,
          "note": "Cedimento tecnico ogni serie, recupero completo 3 minuti"
        }
      ]
    }
  ],
  "consigli": [
    "Per livello AVANZATO: il recupero di 2,30-3 minuti è fondamentale per performance ottimali",
    "Cedimento tecnico significa fermarsi quando la forma inizia a deteriorarsi",
    "Range 6-9 reps per guadagni di forza, 8-12 per ipertrofia muscolare",
    "Le tecniche di intensità (rest-pause, drop set) vanno usate solo negli ultimi esercizi della sessione"
  ]
}

REGOLE CRITICHE DA RISPETTARE OBBLIGATORIAMENTE:

1. LIVELLO AVANZATO (se esperienza = "Avanzato"):
   - riposo_sec: SEMPRE 150-180 secondi per esercizi compound
   - riposo_sec: SEMPRE 120-150 secondi per esercizi isolation
   - ripetizioni: SEMPRE "6-9" per forza O "8-12" per ipertrofia (MAI 10-15 o altri range)
   - note: SEMPRE includere "cedimento tecnico ogni serie" e "recupero completo"

2.  LIMITAZIONI FISICHE:
   - Se dolore ginocchio, una parte della gamba oppure gluteo: MAI leg extension, squat profondi, affondi. OBBLIGATORIO E IMPORTANTISSIMO
   - Se dolore schiena o una sua parte: USA varianti sedute/supportate OBBLIGATORIO E IMPORTANTISSIMO
   - Se dolore spalla o una sua parte: EVITA overhead movements OBBLIGATORIO E IMPORTANTISSIMO

3. POSIZIONI ESERCIZI:
   - Panca piana: SEMPRE sdraiato, MAI seduto
   - Rematore: SEMPRE in piedi/piegato, MAI seduto (salvo limitazioni schiena)
   - Military press: SEMPRE in piedi (salvo limitazioni)

4. COERENZA PARAMETRI:
   - Se un esercizio è compound (panca, rematore, shoulder press): riposo_sec = 150-180
   - Se un esercizio è isolation (curl, alzate): riposo_sec = 120-150
   - Range reps per avanzato: solo "6-9" o "8-12", NIENTE ALTRO IMPORTANTISSIMO VA NELLA SCHEDA NO NEI CONSIGLI.

ESEMPIO CORRETTO per AVANZATO:
{
  "nome": "Panca piana con bilanciere",
  "serie": 4,
  "ripetizioni": "8-12" "ad esempio",
  "riposo_sec": 180 "ad esempio",
  "note": "Cedimento tecnico ogni serie, recupero completo 3 minuti, ROM completo"
}

IMPORTANTE:
- Rispetta SEMPRE i parametri specifici per ogni livello
- Le regole per il livello AVANZATO sono OBBLIGATORIE, non opzionali
- Spiega sempre le tecniche avanzate nei consigli finali
- Nessun testo fuori dal JSON
''';
}

 Map<String, dynamic> _parseWorkoutPlan(String jsonText) {
  // 1) Rimuove eventuali fence ``` e ripulisce
  String clean = jsonText.trim();
  clean = clean.replaceAll('```json', '').replaceAll('```', '').trim();

  // 2) Se il modello ha scritto testo prima/dopo, estrai solo il primo blocco JSON
  final start = clean.indexOf('{');
  final end = clean.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw FormatException('Risposta non in formato JSON.');
  }
  final onlyJson = clean.substring(start, end + 1);

  // 3) Prova a decodificare
  final decoded = json.decode(onlyJson);

  // 4) Validazione minima (campi chiave)
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('JSON non valido (mappa assente).');
  }
  if (!decoded.containsKey('giorni') || decoded['giorni'] is! List) {
    throw FormatException('JSON non valido: campo "giorni" mancante o non lista.');
  }

  return decoded;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Piano Generato',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildPlanWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _rotationAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFE85A30),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE85A30).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Generando il tuo piano...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'L\'AI sta creando un piano personalizzato\nbasato sui tuoi dati',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE85A30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanWidget() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_workoutPlan == null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanHeader(),
            SizedBox(height: 24),
            _buildPlanStats(),
            SizedBox(height: 32),
            _buildWorkoutDays(),
            SizedBox(height: 32),
            _buildTipsSection(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 35,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Errore di connessione',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Non è stato possibile generare il piano.\nControlla la connessione e riprova.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadingController.repeat();
                _generateWorkoutPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE85A30),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Riprova',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE85A30), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE85A30).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Generato con AI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _workoutPlan!['titolo'] ?? 'Il tuo piano di allenamento',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Personalizzato per: ${_workoutPlan!['obiettivo']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            title: 'Durata',
            value: '${_workoutPlan!['durata_settimane'] ?? 8} settimane',
            color: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            title: 'Frequenza',
            value: _workoutPlan!['frequenza'] ?? widget.frequency,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDays() {
    final giorni = _workoutPlan!['giorni'] as List<dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piano settimanale',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2C2C),
          ),
        ),
        SizedBox(height: 16),
        ...giorni.map((giorno) => _buildWorkoutDay(giorno)),
      ],
    );
  }
Widget _buildWorkoutDay(Map<String, dynamic> giorno) {
  final esercizi = giorno['esercizi'] as List<dynamic>;
  
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center, color: Color(0xFFE85A30), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    giorno['giorno'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  Text(
                    giorno['focus'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        ...esercizi.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> exercise = entry.value;
          return _buildExerciseCard(exercise, index + 1);
        }),
      ],
    ),
  );
}

 Widget _buildExerciseCard(Map<String, dynamic> exercise, int number) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFE0E0E0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFE85A30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                exercise['nome'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildExerciseDetailNew(Icons.repeat, 'Serie', '${exercise['serie']}'),
            SizedBox(width: 20),
            _buildExerciseDetailNew(Icons.fitness_center, 'Reps', exercise['ripetizioni']),
            SizedBox(width: 20),
            _buildExerciseDetailNew(Icons.timer, 'Riposo', '${exercise['riposo_sec']}s'),
          ],
        ),
        if (exercise['note'] != null && exercise['note'].toString().isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise['note'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
Widget _buildExerciseDetailNew(IconData icon, String title, String value) {
  return Row(
    children: [
      Icon(icon, color: Color(0xFF666666), size: 16),
      SizedBox(width: 4),
      Text(
        '$title: ',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2C),
        ),
      ),
    ],
  );
}
  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Color(0xFF666666), size: 16),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final consigli = _workoutPlan!['consigli'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tips_and_updates,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Consigli per il successo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...consigli.map<Widget>((consiglio) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        consiglio.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2C2C2C),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}