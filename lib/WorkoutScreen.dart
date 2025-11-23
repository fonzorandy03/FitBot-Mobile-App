import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'GeneratedWorkoutPlanScreen.dart';
import 'MyWorkoutPlansScreen.dart';
import 'authcontext.dart';
import 'LoginScreen.dart';
import 'package:provider/provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form variables
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedFrequency = '3 volte a settimana';
  String _selectedGoal = 'Aumentare massa muscolare';
  String _selectedExperience = 'Intermedio';
  
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
    _notesController.dispose();
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
          Icons.fitness_center,
          color: Colors.white,
          size: 35,
        ),
      ),
      SizedBox(height: 16),
      Text(
        _currentStep == 0 ? 'Informazioni Personali' : 'Conferma i tuoi dati',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C2C2C),
          letterSpacing: -1,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 8),
      Text(
        _currentStep == 0 
          ? 'Inserisci i tuoi dati per creare un piano ottimizzato'
          : 'Verifica le informazioni prima di generare il piano',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF666666),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 24),

      // 🔥 NUOVO PULSANTE ANIMATO STILE APPLE
      Consumer<AuthContext>(
        builder: (context, authContext, child) {
          if (!authContext.isAuthenticated) return SizedBox.shrink();
          
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
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
                                MyWorkoutPlansScreen(),
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
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white,
                              Color(0xFFFAFAFA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE85A30).withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE85A30).withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: Offset(0, 2),
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
                                color: Color(0xFFE85A30).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.folder_copy_outlined,
                                color: Color(0xFFE85A30),
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Le mie schede',
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
                            SizedBox(width: 8),
                            Icon(
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
          color: _currentStep > 0 ? Color(0xFFE85A30) : Color(0xFFE0E0E0),
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
            color: isActive ? Color(0xFFE85A30) : Colors.white,
            border: Border.all(
              color: isActive ? Color(0xFFE85A30) : Color(0xFFE0E0E0),
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
            color: isActive ? Color(0xFFE85A30) : Color(0xFF666666),
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
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Inserisci la tua età',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          
          SizedBox(height: 32),
          
          // Frequenza di allenamento
          Text(
            'Frequenza di allenamento',
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
                value: _selectedFrequency,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
                items: [
                  '2 volte a settimana',
                  '3 volte a settimana',
                  '4 volte a settimana',
                  '5 volte a settimana',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFrequency = newValue!;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Quante volte a settimana puoi allenarti',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),

          SizedBox(height: 32),

          // Livello di esperienza
          Text(
            'Livello di esperienza',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),

          _buildExperienceOption(
            icon: Icons.school,
            title: 'Neofita',
            subtitle: '0-6 mesi di allenamento',
            experience: 'Neofita',
            color: Color(0xFF4CAF50),
          ),
          SizedBox(height: 16),
          _buildExperienceOption(
            icon: Icons.trending_up,
            title: 'Intermedio',
            subtitle: '6 mesi - 2 anni di allenamento',
            experience: 'Intermedio',
            color: Color(0xFF2196F3),
          ),
          SizedBox(height: 16),
          _buildExperienceOption(
            icon: Icons.military_tech,
            title: 'Avanzato',
            subtitle: '2+ anni di allenamento costante',
            experience: 'Avanzato',
            color: Color(0xFF9C27B0),
          ),
          
          SizedBox(height: 32),
          
          // Obiettivi
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
            icon: Icons.local_fire_department,
            title: 'Perdere peso',
            subtitle: 'Deficit calorico, cardio intenso',
            goal: 'Perdere peso',
            color: Color(0xFFFF6B35),
          ),
          SizedBox(height: 16),
          _buildGoalOption(
            icon: Icons.balance,
            title: 'Mantenere',
            subtitle: 'Equilibrio, tonificazione',
            goal: 'Mantenere',
            color: Color(0xFF4CAF50),
          ),
          SizedBox(height: 16),
          _buildGoalOption(
            icon: Icons.fitness_center,
            title: 'Aumentare massa',
            subtitle: 'Surplus calorico, forza',
            goal: 'Aumentare massa muscolare',
            color: Color(0xFF2196F3),
          ),

          SizedBox(height: 32),

          // Note aggiuntive
          Text(
            'Note aggiuntive (opzionale)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
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
              controller: _notesController,
              maxLines: 4,
              style: TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Es. infortuni precedenti, preferenze per esercizi, limitazioni...',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Inserisci eventuali informazioni aggiuntive per personalizzare meglio il tuo piano',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          
          SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _ageController.text.isNotEmpty ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE85A30),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                disabledBackgroundColor: Color(0xFFE0E0E0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continua',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
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
            icon: Icons.person,
            title: 'Età',
            value: '${_ageController.text} anni',
          ),
          
          SizedBox(height: 16),
          
          _buildSummaryItem(
            icon: Icons.calendar_today,
            title: 'Frequenza',
            value: _selectedFrequency,
          ),
          
          SizedBox(height: 16),

          _buildSummaryItem(
            icon: Icons.school,
            title: 'Esperienza',
            value: _selectedExperience,
          ),

          SizedBox(height: 16),
          
          _buildSummaryItem(
            icon: Icons.track_changes,
            title: 'Obiettivo',
            value: _selectedGoal,
          ),

          if (_notesController.text.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.note,
              title: 'Note aggiuntive',
              value: _notesController.text,
            ),
          ],
          
          SizedBox(height: 32),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Il piano sarà generato utilizzando l\'intelligenza artificiale per ottimizzare i tuoi risultati',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2196F3),
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
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFFE85A30)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Modifica',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE85A30),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _createPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE85A30),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Genera Piano',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.auto_awesome, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
              color: Color(0xFFE85A30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFFE85A30), size: 20),
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

  Widget _buildExperienceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String experience,
    required Color color,
  }) {
    bool isSelected = _selectedExperience == experience;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedExperience = experience;
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
              Icon(Icons.check_circle, color: color, size: 24),
          ],
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
    
    return GestureDetector(
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
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
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

void _createPlan() {
  HapticFeedback.mediumImpact();

  final auth = context.read<AuthContext>();
  if (!auth.isAuthenticated) {

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GeneratedWorkoutPlanScreen(
        age: int.parse(_ageController.text),
        frequency: _selectedFrequency,
        goal: _selectedGoal,
        experience: _selectedExperience,
        additionalNotes: _notesController.text,
      ),
    ),
  );
}


}