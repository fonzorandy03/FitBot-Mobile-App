import 'package:flutter/material.dart';
import 'DietPlanDao.dart';

class DietPlanDetailScreen extends StatefulWidget {
  final DietPlan dietPlan;

  const DietPlanDetailScreen({
    super.key,
    required this.dietPlan,
  });

  @override
  _DietPlanDetailScreenState createState() => _DietPlanDetailScreenState();
}

class _DietPlanDetailScreenState extends State<DietPlanDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Selettore giorni: sempre 7 voci, in ordine fisso
  static const List<String> _weekDays = <String>[
    'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
  ];
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // --------- Helpers robusti ---------
  String _norm(String s) {
    var n = s.toLowerCase().trim();
    n = n
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u');
    return n;
  }

  // Mappa giorno -> DietDay (lookup case/diacritics-insensitive)
  Map<String, DietDay> get _daysByName {
    final map = <String, DietDay>{};
    for (final d in widget.dietPlan.giorni) {
      map[_norm(d.giorno)] = d;
    }
    return map;
  }

  int _mealCalories(Meal m) {
    final v = m.calorie;
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  int _dayCalories(DietDay? day) {
    if (day == null) return 0;
    // Se il modello ha già un totale > 0 usalo, altrimenti somma i pasti
    final totField = (() {
      try {
        return (day.calorieTotali is num) ? (day.calorieTotali as num).round() : 0;
      } catch (_) {
        return 0;
      }
    })();
    if (totField > 0) return totField;
    return day.pasti.fold<int>(0, (sum, m) => sum + _mealCalories(m));
  }

  String _g(dynamic v) {
    if (v == null) return '0';
    if (v is num) return v.round().toString();
    return (double.tryParse(v.toString()) ?? 0).round().toString();
  }

  DietDay? _dayForIndex(int idx) {
    final wanted = _weekDays[idx];
    return _daysByName[_norm(wanted)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.dietPlan.titolo,
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanHeader(),
              const SizedBox(height: 24),
              _buildPlanInfo(),
              const SizedBox(height: 24),
              _buildDaySelector(),
              const SizedBox(height: 16),
              _buildMealsList(),
              const SizedBox(height: 24),
              if (widget.dietPlan.consigli.isNotEmpty) _buildAdviceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.dietPlan.isActive ? Icons.check_circle : Icons.restaurant_menu,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                widget.dietPlan.isActive ? 'Piano Attivo' : 'Piano Salvato',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.dietPlan.titolo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.dietPlan.obiettivo,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfo() {
    final macros = widget.dietPlan.macronutrientiGiornalieri;
    final p = _g(macros['proteine']);
    final c = _g(macros['carboidrati']);
    final g = _g(macros['grassi']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informazioni del Piano',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.local_fire_department,
                  title: 'Calorie/die',
                  value: '${widget.dietPlan.calorieTotaliGiornaliere} kcal',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.directions_walk,
                  title: 'Attività',
                  value: widget.dietPlan.livelloAttivita,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  title: 'Età',
                  value: '${widget.dietPlan.eta} anni',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.monitor_weight,
                  title: 'Peso',
                  value: '${widget.dietPlan.peso.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.straighten,
                  title: 'Altezza',
                  value: '${widget.dietPlan.altezza.toStringAsFixed(0)} cm',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.bubble_chart, color: Color(0xFF4CAF50), size: 24),
                    const SizedBox(height: 8),
                    const Text(
                      'Macronutrienti/die',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMacroChip('Proteine', '$p g', Colors.green),
                        _buildMacroChip('Carbo', '$c g', Colors.blue),
                        _buildMacroChip('Grassi', '$g g', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Creato: ${_formatDate(widget.dietPlan.createdAt)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final daysMap = _daysByName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleziona il giorno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final label = _weekDays[index];
                final day = daysMap[_norm(label)];
                final isSelected = _selectedDayIndex == index;
                final dayKcal = _dayCalories(day);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDayIndex = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : (day != null ? const Color(0xFFF8F9FA) : const Color(0xFFF3F3F3)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : (day != null ? const Color(0xFFE0E0E0) : const Color(0xFFE6E6E6)),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (day != null ? const Color(0xFF2C2C2C) : const Color(0xFF9E9E9E)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayKcal} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : (day != null ? const Color(0xFF666666) : const Color(0xFFB0B0B0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    final selectedDay = _dayForIndex(_selectedDayIndex);
    final label = _weekDays[_selectedDayIndex];
    final totalKcal = _dayCalories(selectedDay);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2C2C),
                        )),
                    Text('Totale: $totalKcal kcal',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (selectedDay == null || selectedDay.pasti.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text(
                'Nessun pasto previsto per questo giorno.',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            )
          else
            ...selectedDay.pasti.asMap().entries.map((entry) {
              final idx = entry.key;
              final meal = entry.value;
              return _buildMealCard(meal, idx + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal, int number) {
    final p = _g(meal.macronutrienti['proteine']);
    final c = _g(meal.macronutrienti['carboidrati']);
    final g = _g(meal.macronutrienti['grassi']);
    final kcal = _mealCalories(meal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // intestazione
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  meal.nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '$kcal kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildMealDetail(Icons.label_rounded, 'Tipo', meal.tipo),
              const SizedBox(width: 20),
              _buildMealDetail(Icons.timer, 'Tempo', '${meal.tempoPreparazioneMin} min'),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroPill('Proteine', '$p g', Colors.green),
              _buildMacroPill('Carbo', '$c g', Colors.blue),
              _buildMacroPill('Grassi', '$g g', Colors.orange),
            ],
          ),

          if (meal.ingredienti.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.ingredienti.join(', '),
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],

         if (meal.preparazione != null && meal.preparazione!.isNotEmpty) ...[
  const SizedBox(height: 12),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.restaurant_outlined, color: Color(0xFFFFC107), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            meal.preparazione!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
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
        Icon(icon, color: const Color(0xFF666666), size: 16),
        const SizedBox(width: 4),
        Text('$title: ',
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tips_and_updates, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Consigli per il successo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.dietPlan.consigli.map<Widget>((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration:
                          const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
