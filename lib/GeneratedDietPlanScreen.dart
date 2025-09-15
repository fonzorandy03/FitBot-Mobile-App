import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DietPlanDao.dart';

class GeneratedDietPlanScreen extends StatefulWidget {
  final int age;
  final double weight;
  final double height;
  final String activityLevel;
  final String goal;
  final List<String> intolerances;
  final String? preferences;

  const GeneratedDietPlanScreen({
    super.key,
    required this.age,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.goal,
    required this.intolerances,
    this.preferences,
  });

  @override
  _GeneratedDietPlanScreenState createState() => _GeneratedDietPlanScreenState();
}

class _GeneratedDietPlanScreenState extends State<GeneratedDietPlanScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic>? _dietPlan;
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
    _generateDietPlan();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateDietPlan() async {
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
  'maxOutputTokens': 6400,
}

        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parsing del piano generato
        setState(() {
          _dietPlan = _parseDietPlan(generatedText);
          _isLoading = false;
        });
        
        // Salva il piano generato
        await _saveDietPlan();
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

  String _buildPrompt() {
    double bmi = widget.weight / ((widget.height / 100) * (widget.height / 100));
    
    String intolerancesText = widget.intolerances.isEmpty 
      ? "Nessuna intolleranza alimentare" 
      : "Intolleranze: ${widget.intolerances.join(', ')}";
    
    String preferencesText = widget.preferences?.isNotEmpty == true 
      ? "Preferenze aggiuntive: ${widget.preferences}" 
      : "";

    return '''
Crea un piano alimentare settimanale personalizzato in formato JSON **ESATTAMENTE** con 7 giorni (Lunedì, Martedì, Mercoledì, Giovedì, Venerdì, Sabato, Domenica). 

DATI UTENTE:
- Età: ${widget.age} anni
- Peso: ${widget.weight} kg
- Altezza: ${widget.height} cm
- Livello di attività: ${widget.activityLevel}
- Obiettivo: ${widget.goal}
- ${intolerancesText}
$preferencesText

REQUISITI IMPORTANTI:
- Il campo "giorni" deve contenere **7 elementi** nell'ordine: Lunedì, Martedì, Mercoledì, Giovedì, Venerdì, Sabato, Domenica.
- Ogni giorno DEVE avere i campi numerici:
  - "calorie_totali" (somma delle calorie dei suoi pasti)
  - "macronutrienti_totali" con { "proteine": g, "carboidrati": g, "grassi": g } (somma dei pasti)
- Ogni giorno deve avere 5 pasti: colazione, spuntino mattina, pranzo, spuntino pomeriggio, cena.
- Liste ingredienti concise (max 7 voci). Testi brevi.
- NIENTE testo fuori dal JSON.

FORMATO JSON RICHIESTO:
{
  "titolo": "Piano Alimentare - [Obiettivo]",
  "obiettivo": "${widget.goal}",
  "calorie_totali_giornaliere": [numero],
  "macronutrienti_giornalieri": {
    "proteine": [grammi],
    "carboidrati": [grammi],
    "grassi": [grammi]
  },
  "giorni": [
    {
      "giorno": "Lunedì",
      "calorie_totali": [numero],
      "macronutrienti_totali": { "proteine": [g], "carboidrati": [g], "grassi": [g] },
      "pasti": [
        {
          "nome": "Nome pasto",
          "tipo": "colazione|spuntino|pranzo|cena",
          "ingredienti": ["..."],
          "calorie": [numero],
          "macronutrienti": { "proteine": [g], "carboidrati": [g], "grassi": [g] },
          "tempo_preparazione_min": [numero],
          "preparazione": "..."
        }
      ]
    }
  ],
  "consigli": ["...", "..."]
}

Rispondi SOLO con il JSON, senza testo aggiuntivo.
''';
  }

 Future<void> _saveDietPlan() async {
  if (_dietPlan == null) return;

  try {
    // --- Cast sicuri dai dati generati dall'AI ---
    // 1) Giorni
    final giorniList = (_dietPlan!['giorni'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((g) => DietDay.fromMap(g))
        .toList();

    // 2) Calorie totali giornaliere (int)
    final calorieTotali = (_dietPlan!['calorie_totali_giornaliere'] as num?)?.toInt() ?? 0;

    // 3) Macronutrienti giornalieri (Map<String, double>)
    final rawMacros = (_dietPlan!['macronutrienti_giornalieri'] as Map<String, dynamic>? ?? {});
    final macrosGiornalieri = rawMacros.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0),
    );

    // 4) Consigli (List<String>)
    final consigliList = (_dietPlan!['consigli'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    // --- Costruzione DietPlan con cast robusti ---
    final dietPlan = DietPlan(
      userId: '', // Il DAO lo sovrascrive con l'utente corrente
      titolo: _dietPlan!['titolo']?.toString() ?? 'Piano Alimentare',
      eta: widget.age,
      peso: widget.weight,
      altezza: widget.height,
      livelloAttivita: widget.activityLevel,
      obiettivo: widget.goal,
      intolleranze: widget.intolerances,
      preferenze: widget.preferences,
      calorieTotaliGiornaliere: calorieTotali,
      macronutrientiGiornalieri: macrosGiornalieri,
      giorni: giorniList,
      consigli: consigliList,
      createdAt: DateTime.now(),
    );

    // --- Salvataggio su Firestore tramite DAO ---
    final dietDAO = DietPlanDAO();
    final result = await dietDAO.saveDietPlan(dietPlan);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(result.success ? Icons.cloud_done : Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                result.success
                    ? 'Piano alimentare salvato'
                    : 'Salvataggio fallito: ${result.error ?? 'errore sconosciuto'}',
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? Color(0xFF4CAF50) : Color(0xFFFF6B35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Errore locale prima del salvataggio: $e'),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
    rethrow; // utile in debug per vedere stack trace in console
  }
}


  Map<String, dynamic> _parseDietPlan(String jsonText) {
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
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Generando il tuo piano alimentare...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'L\'AI sta creando un piano nutrizionale\npersonalizzato per te',
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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

    if (_dietPlan == null) {
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
            _buildNutritionalStats(),
            SizedBox(height: 32),
            _buildDietDays(),
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
              'Non è stato possibile generare il piano alimentare.\nControlla la connessione e riprova.',
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
                _generateDietPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
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
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4CAF50).withOpacity(0.3),
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
            _dietPlan!['titolo'] ?? 'Il tuo piano alimentare',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Personalizzato per: ${_dietPlan!['obiettivo']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalStats() {
    final macros = _dietPlan!['macronutrienti_giornalieri'] as Map<String, dynamic>;
    final calories = _dietPlan!['calorie_totali_giornaliere'];
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutritionalCard(
                icon: Icons.local_fire_department,
                title: 'Calorie',
                value: '$calories kcal',
                color: Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildNutritionalCard(
                icon: Icons.fitness_center,
                title: 'Proteine',
                value: '${macros['proteine']?.round() ?? 0}g',
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNutritionalCard(
                icon: Icons.grain,
                title: 'Carboidrati',
                value: '${macros['carboidrati']?.round() ?? 0}g',
                color: Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildNutritionalCard(
                icon: Icons.opacity,
                title: 'Grassi',
                value: '${macros['grassi']?.round() ?? 0}g',
                color: Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionalCard({
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

  Widget _buildDietDays() {
    final giorni = _dietPlan!['giorni'] as List<dynamic>;
    
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
        ...giorni.map((giorno) => _buildDietDay(giorno)),
      ],
    );
  }

  Widget _buildDietDay(Map<String, dynamic> giorno) {
    final pasti = giorno['pasti'] as List<dynamic>;
    
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
              Icon(Icons.calendar_today, color: Color(0xFF4CAF50), size: 24),
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
                      '${pasti.length} pasti programmati',
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
          ...pasti.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> meal = entry.value;
            return _buildMealCard(meal, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int number) {
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
                  color: _getMealTypeColor(meal['tipo']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getMealTypeIcon(meal['tipo']),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['nome'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      _getMealTypeLabel(meal['tipo']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Ingredienti
          if (meal['ingredienti'] != null && (meal['ingredienti'] as List).isNotEmpty) ...[
            Text(
              'Ingredienti:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
            SizedBox(height: 4),
            Text(
              (meal['ingredienti'] as List).join(', '),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.3,
              ),
            ),
            SizedBox(height: 12),
          ],
          
          // Info nutrizionali e tempo
          Row(
            children: [
              _buildMealDetail(Icons.local_fire_department, 'Calorie', '${meal['calorie']} kcal'),
              SizedBox(width: 16),
              _buildMealDetail(Icons.timer, 'Prep', '${meal['tempo_preparazione_min'] ?? 0} min'),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Macronutrienti
          if (meal['macronutrienti'] != null) ...[
            Row(
              children: [
                _buildMacroDetail('P', '${meal['macronutrienti']['proteine']?.round() ?? 0}g', Color(0xFF4CAF50)),
                SizedBox(width: 12),
                _buildMacroDetail('C', '${meal['macronutrienti']['carboidrati']?.round() ?? 0}g', Color(0xFF2196F3)),
                SizedBox(width: 12),
                _buildMacroDetail('G', '${meal['macronutrienti']['grassi']?.round() ?? 0}g', Color(0xFF9C27B0)),
              ],
            ),
          ],
          
          // Preparazione
          if (meal['preparazione'] != null && meal['preparazione'].toString().isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.restaurant, color: Color(0xFF4CAF50), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal['preparazione'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        height: 1.3,
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

  Widget _buildMealDetail(IconData icon, String title, String value) {
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

  Widget _buildMacroDetail(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            ': $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'colazione':
        return Color(0xFFFFA726);
      case 'spuntino':
        return Color(0xFF66BB6A);
      case 'pranzo':
        return Color(0xFF42A5F5);
      case 'cena':
        return Color(0xFF9575CD);
      default:
        return Color(0xFF4CAF50);
    }
  }

  IconData _getMealTypeIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'colazione':
        return Icons.wb_sunny;
      case 'spuntino':
        return Icons.local_cafe;
      case 'pranzo':
        return Icons.restaurant;
      case 'cena':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant_menu;
    }
  }

  String _getMealTypeLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'colazione':
        return 'COLAZIONE';
      case 'spuntino':
        return 'SPUNTINO';
      case 'pranzo':
        return 'PRANZO';
      case 'cena':
        return 'CENA';
      default:
        return tipo.toUpperCase();
    }
  }

  Widget _buildTipsSection() {
    final consigli = _dietPlan!['consigli'] as List<dynamic>? ?? [];
    
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
            offset:Offset(0, 5),
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