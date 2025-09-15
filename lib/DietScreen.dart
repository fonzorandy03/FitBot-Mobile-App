import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'authcontext.dart';
import 'GeneratedDietPlanScreen.dart';
import 'mydietplansScreen.dart';
import 'LoginScreen.dart';



class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  _DietScreenState createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form variables
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController();
  
  String _selectedActivityLevel = 'Moderato';
  String _selectedGoal = 'Mantenere il peso';
  final Set<String> _selectedIntolerances = {};
  
  int _currentStep = 0;
  final int _totalSteps = 2;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4F0), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: 35),
                  
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(),
                  ),
                  
                  SizedBox(height: 30),
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStepIndicator(),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCurrentStepContent(),
                    ),
                  ),
                  
                  SizedBox(height: 40),                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
  return Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: Colors.white,
          size: 35,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _currentStep == 0 ? 'Informazioni Personali' : 'Conferma i tuoi dati',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C2C2C),
          letterSpacing: -1,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        _currentStep == 0
            ? 'Inserisci i tuoi dati per creare un piano alimentare'
            : 'Verifica le informazioni prima di generare il piano',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF666666),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),

      // 🔥 PULSANTE "Le mie diete" (stesso stile Apple ma verde)
      Consumer<AuthContext>(
        builder: (context, authContext, child) {
          if (!authContext.isAuthenticated) return const SizedBox.shrink();

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                       
                    Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                MyDietPlansScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              var begin = Offset(0.0, 1.0);
                              var end = Offset.zero;
                              var curve = Curves.easeInOutCubic;
                              var tween = Tween(begin: begin, end: end).chain(
                                CurveTween(curve: curve),
                              );
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration: Duration(milliseconds: 600),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.white, Color(0xFFFAFAFA)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.folder_copy_outlined,
                                color: Color(0xFF4CAF50),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Le mie diete',
                                  style: TextStyle(
                                    color: Color(0xFF2C2C2C),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Visualizza i tuoi piani',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF666666),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ],
  );
}


  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Dati Personali'),
        Container(
          width: 40,
          height: 2,
          color: _currentStep > 0 ? Color(0xFF4CAF50) : Color(0xFFE0E0E0),
          margin: EdgeInsets.symmetric(horizontal: 8),
        ),
        _buildStepDot(1, 'Conferma'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF4CAF50) : Colors.white,
            border: Border.all(
              color: isActive ? Color(0xFF4CAF50) : Color(0xFFE0E0E0),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: isActive
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Color(0xFF4CAF50) : Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    return Container(
      key: ValueKey('step1'),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Età
          Text(
            'Età',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _ageController,
            hintText: 'Inserisci la tua età',
            keyboardType: TextInputType.number,
            icon: Icons.person_rounded,
          ),
          
          SizedBox(height: 24),
          
          // Peso e Altezza in una riga
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso (kg)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _weightController,
                      hintText: 'Inserisci il tuo peso',
                      keyboardType: TextInputType.number,
                      icon: Icons.monitor_weight_rounded,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Altezza (cm)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _heightController,
                      hintText: 'Inserisci la tua altezza',
                      keyboardType: TextInputType.number,
                      icon: Icons.height_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32),
          
          // Livello di attività fisica
          Text(
            'Livello di attività fisica',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityLevel,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
                items: [
                  'Sedentario',
                  'Leggero',
                  'Moderato',
                  'Attivo',
                  'Molto attivo',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue!;
                  });
                },
              ),
            ),
          ),
          
          SizedBox(height: 32),

          // Obiettivo
          Text(
            'Obiettivo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),
          
          _buildGoalOption(
            icon: Icons.trending_down_rounded,
            title: 'Perdere peso',
            subtitle: 'Deficit calorico controllato',
            goal: 'Perdere peso',
            color: Color(0xFFFF6B35),
          ),
          SizedBox(height: 12),
          _buildGoalOption(
            icon: Icons.balance_rounded,
            title: 'Mantenere il peso',
            subtitle: 'Equilibrio nutrizionale',
            goal: 'Mantenere il peso',
            color: Color(0xFF4CAF50),
          ),
          SizedBox(height: 12),
          _buildGoalOption(
            icon: Icons.trending_up_rounded,
            title: 'Aumentare massa',
            subtitle: 'Surplus calorico proteico',
            goal: 'Aumentare massa',
            color: Color(0xFF2196F3),
          ),

          SizedBox(height: 32),

          // Intolleranze alimentari
          Text(
            'Intolleranze alimentari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seleziona eventuali intolleranze alimentari da considerare nel piano',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildIntoleranceChip('Lattosio'),
              _buildIntoleranceChip('Glutine'),
              _buildIntoleranceChip('Frutta secca'),
              _buildIntoleranceChip('Uova'),
            ],
          ),

          SizedBox(height: 32),

          // Preferenze alimentari
          Text(
            'Preferenze alimentari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Questa opzione è facoltativa',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _preferencesController,
              maxLines: 3,
              style: TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Seleziona le tue preferenze (opzionale)',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.favorite_rounded, color: Color(0xFF4CAF50)),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _canProceed() ? () {
                  HapticFeedback.lightImpact();
                  _nextStep();
                } : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _canProceed() 
                      ? LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)])
                      : null,
                    color: _canProceed() ? null : Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _canProceed() ? [
                      BoxShadow(
                        color: Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continua',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _canProceed() ? Colors.white : Color(0xFF999999),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded, 
                        size: 18,
                        color: _canProceed() ? Colors.white : Color(0xFF999999),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      key: ValueKey('step2'),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riepilogo dei tuoi dati',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 24),
          
          _buildSummaryItem(
            icon: Icons.person_rounded,
            title: 'Età',
            value: '${_ageController.text} anni',
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.monitor_weight_rounded,
                  title: 'Peso',
                  value: '${_weightController.text} kg',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.height_rounded,
                  title: 'Altezza',
                  value: '${_heightController.text} cm',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          _buildSummaryItem(
            icon: Icons.directions_run_rounded,
            title: 'Attività fisica',
            value: _selectedActivityLevel,
          ),

          SizedBox(height: 16),
          
          _buildSummaryItem(
            icon: Icons.track_changes_rounded,
            title: 'Obiettivo',
            value: _selectedGoal,
          ),

          if (_selectedIntolerances.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.warning_rounded,
              title: 'Intolleranze',
              value: _selectedIntolerances.join(', '),
            ),
          ],

          if (_preferencesController.text.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.favorite_rounded,
              title: 'Preferenze',
              value: _preferencesController.text,
            ),
          ],
          
          SizedBox(height: 32),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50).withOpacity(0.1), Color(0xFF66BB6A).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF4CAF50), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Il piano alimentare sarà generato utilizzando l\'intelligenza artificiale per ottimizzare la tua nutrizione',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4CAF50),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _currentStep = 0;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF4CAF50)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Modifica',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _createDietPlan();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Genera Piano',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.restaurant_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: Padding(
            padding: EdgeInsets.all(16),
            child: Icon(icon, color: Color(0xFF4CAF50), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String goal,
    required Color color,
  }) {
    bool isSelected = _selectedGoal == goal;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedGoal = goal;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntoleranceChip(String intolerance) {
    bool isSelected = _selectedIntolerances.contains(intolerance);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            if (isSelected) {
              _selectedIntolerances.remove(intolerance);
            } else {
              _selectedIntolerances.add(intolerance);
            }
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)])
              : null,
            color: isSelected ? null : Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.check_rounded, color: Colors.white, size: 16),
              if (isSelected) SizedBox(width: 6),
              Text(
                intolerance,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF4CAF50), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    return _ageController.text.isNotEmpty && 
           _weightController.text.isNotEmpty && 
           _heightController.text.isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

 void _createDietPlan() {
  HapticFeedback.mediumImpact();

  // 🔐 Se non sei loggato -> vai al Login
  final auth = context.read<AuthContext>();
  if (!auth.isAuthenticated) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>LoginScreen()),
    );
    return;
  }

  // ✅ Se sei loggato, continua come prima

  // Validazione veloce per evitare crash in parse:
  final age = int.tryParse(_ageController.text);
  final weight = double.tryParse(_weightController.text);
  final height = double.tryParse(_heightController.text);

  if (age == null || weight == null || height == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Controlla i campi numerici (età, peso, altezza)')
          ],
        ),
        backgroundColor: const Color(0xFFFF6B35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 12),
          Text('Piano alimentare in generazione...')
        ],
      ),
      backgroundColor: const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
    ),
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GeneratedDietPlanScreen(
        age: age,
        weight: weight,
        height: height,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
        intolerances: _selectedIntolerances.toList(),
        preferences: _preferencesController.text.isEmpty
            ? null
            : _preferencesController.text,
      ),
    ),
  );
}
}