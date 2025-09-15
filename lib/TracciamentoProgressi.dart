import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart' as rive;
import 'ProgressChartsScreen.dart';

import 'progressdao.dart';
import 'authcontext.dart';
import 'WorkoutPlanDao.dart';
import 'LoginScreen.dart'; // Importa la schermata di login

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}
class ExerciseProgress {
  final int week;
  final double weight;
  final int reps;
  final bool isCompleted;

  ExerciseProgress({
    required this.week,
    required this.weight,
    required this.reps,
    required this.isCompleted,
  });
}
class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with TickerProviderStateMixin {
  // Animation Controllers principali
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  // Animations principali
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Loader migliorato - animazioni più fluide
  late AnimationController _loadingController;
  late Animation<double> _rotationAnimation;
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;

  // Rive
  bool _riveAvailable = true;

  // DAOs / Auth
  final WorkoutPlanDAO _workoutDAO = WorkoutPlanDAO();
  final ProgressDAO _progressDAO = ProgressDAO();
  late String _userId = '';

  // Data
  List<WorkoutPlan> _workoutPlans = [];
  WorkoutPlan? _selectedPlan;
  bool _isLoading = true;
  bool _hasNoPlans = false;

  // Progress tracking (locale; persistenza con ProgressDAO)
  Map<String, List<ExerciseProgress>> _progressData = {};
  int _currentWeek = 1;
  final int _totalWeeks = 8;

  @override
  void initState() {
    super.initState();

    // Initialize animations base
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    // Loader rotante migliorato
    _loadingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOutSine)
    );

    // Effetto respiro più fluido
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 0.03, end: 0.25).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutCirc),
    );

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutQuart),
    );

    _preloadRive();
  }

  Future<void> _preloadRive() async {
    try {
      await rootBundle.load('assets/loading_fitness.riv');
      if (mounted) setState(() => _riveAvailable = true);
    } catch (_) {
      if (mounted) setState(() => _riveAvailable = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthContext>();
    final currentUid = auth.user?.uid ?? '';
    
    // Controllo login aggiunto
if (!auth.isAuthenticated) {
  return;
}
    
    if (_userId != currentUid) {
      _userId = currentUid;
      _loadData();
    }
  }

  // Nuovo metodo per mostrare richiesta di login
  void _showLoginRequired() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.person_circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Accesso Richiesto'),
          ],
        ),
        content: const Text(
          'Per visualizzare e tracciare i tuoi progressi devi prima effettuare l\'accesso al tuo account.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: const Text(
              'Accedi',
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Torna alla schermata precedente
            },
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    ).then((_) {
      // Ricarica i dati dopo il login
      final auth = context.read<AuthContext>();
      if (auth.isAuthenticated) {
        _userId = auth.user?.uid ?? '';
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _loadingController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Controllo autenticazione prima di caricare
    final auth = context.read<AuthContext>();
    if (!auth.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _hasNoPlans = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasNoPlans = false;
      _workoutPlans = [];
      _selectedPlan = null;
      _progressData.clear();
      _currentWeek = 1;
    });
    _loadingController.repeat();

    try {
      if (_userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoPlans = true;
        });
        _loadingController.stop();
        return;
      }

      final result = await _workoutDAO.getUserWorkoutPlans(activeOnly: false);

      if (!result.success || result.workoutPlans == null || result.workoutPlans!.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoPlans = true;
        });
        if (result.error != null) {
          _showErrorDialog(result.error!);
        }
        _loadingController.stop();
        return;
      }

      _workoutPlans = result.workoutPlans!;
      _selectedPlan = _workoutPlans.first;

      _initializeProgressData();
      await _hydrateProgressFromFirestore();

      setState(() {
        _isLoading = false;
      });

      // Animazioni di entrata più fluide con timing migliorato
      _fadeController.reset();
      _slideController.reset();
      _scaleController.reset();
      
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 150));
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _scaleController.forward();

      _loadingController.stop();
    } catch (e) {
      setState(() => _isLoading = false);
      _loadingController.stop();
      _showErrorDialog('Errore nel caricamento dei piani: $e');
    }
  }

  void _initializeProgressData() {
    if (_selectedPlan == null) return;

    for (var day in _selectedPlan!.giorni) {
      for (var exercise in day.esercizi) {
        final nome = exercise.nome.trim().toLowerCase();
        if (nome.contains('riscaldamento')) {
          continue;
        }

        final key = '${day.giorno}_${exercise.nome}';
        _progressData[key] = List.generate(
          _totalWeeks,
          (index) => ExerciseProgress(
            week: index + 1,
            weight: 0.0,
            reps: 0,
            isCompleted: false,
          ),
        );
      }
    }
  }

  Future<void> _hydrateProgressFromFirestore() async {
    if (_selectedPlan == null || _selectedPlan!.id == null || _selectedPlan!.id!.isEmpty || _userId.isEmpty) return;
    try {
      final entries = await _progressDAO
          .streamPlanProgress(userId: _userId, planId: _selectedPlan!.id!)
          .first;

      for (final e in entries) {
        final key = '${e.dayName}_${e.exerciseName}';
        if (!_progressData.containsKey(key)) continue;
        final weekIndex = (e.week - 1).clamp(0, _totalWeeks - 1);
        final list = _progressData[key]!;
        list[weekIndex] = ExerciseProgress(
          week: e.week,
          weight: e.weight,
          reps: e.reps,
          isCompleted: e.isCompleted,
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
      // silenzioso
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controllo autenticazione nel build
    final auth = context.watch<AuthContext>();
    if (!auth.isAuthenticated) {
      return _buildNotAuthenticatedScreen();
    }

    if (_isLoading) {
      return _buildLoadingProgress();
    }

    if (_hasNoPlans) {
      return _buildNoPlansScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStatsCards(),
                      const SizedBox(height: 32),
                      _buildPlanSelector(),
                      const SizedBox(height: 24),
                      _buildWeekSelector(),
                      const SizedBox(height: 32),
                      _buildProgressSection(),
                      const SizedBox(height: 100),
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

  // Nuova schermata per utenti non autenticati
  Widget _buildNotAuthenticatedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.person_circle,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Accesso Richiesto',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Per tracciare i tuoi progressi e visualizzare i piani di allenamento, devi prima effettuare l\'accesso.',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                  child: const Text(
                    'Accedi ora',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPlansScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _riveAvailable
                  ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const rive.RiveAnimation.asset(
                        'assets/loading_fitness.riv',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_square,
                        size: 36,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
              const SizedBox(height: 24),
              const Text(
                'Nessun piano trovato',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _userId.isEmpty
                    ? 'Accedi per visualizzare o creare i tuoi piani di allenamento.'
                    : 'Crea o salva un piano per iniziare a tracciare i progressi.',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: false,
      backgroundColor: Color(0xFFF5F5F7),
      elevation: 0,
    );
  }

  Widget _buildHeader() {
  final auth = context.watch<AuthContext>();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_riveAvailable)
              SizedBox(
                width: 54,
                height: 54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const rive.RiveAnimation.asset(
                    'assets/loading_fitness.riv',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tracciamento Progressi',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ciao ${auth.displayName}! Inserisci i tuoi dati per tracciare i progressi',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Bottone per visualizzare grafici
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProgressChartsScreen(),
              ),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.chart_bar,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadData,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.refresh,
              color: Color(0xFFFF6B35),
              size: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Settimana',
              '$_currentWeek',
              CupertinoIcons.calendar,
              Colors.green,
              true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Esercizi',
              '${_getTrackedExercisesCount()}',
              CupertinoIcons.list_bullet,
              Colors.blue,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            scale: 1.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
                  color: Color(0xFFFF6B35),
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Piano Selezionato',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showEnhancedPlanSelector,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPlan?.titolo ?? 'Nessun piano selezionato',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.black.withOpacity(0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nuovo selettore piani migliorato
  void _showEnhancedPlanSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_text_fill,
                        color: Color(0xFFFF6B35),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleziona Piano di Allenamento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista piani migliorata
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _workoutPlans.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final plan = _workoutPlans[index];
                    final isSelected = plan.id == _selectedPlan?.id;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _selectedPlan = plan;
                            _progressData.clear();
                            _currentWeek = 1;
                            _initializeProgressData();
                          });
                          await _hydrateProgressFromFirestore();
                          if (mounted) Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF6B35).withOpacity(0.05) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
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
                                      gradient: LinearGradient(
                                        colors: isSelected 
                                          ? [const Color(0xFFFF6B35), const Color(0xFFFF8A65)]
                                          : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.doc_text_fill,
                                      color: isSelected ? Colors.white : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.titolo,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? const Color(0xFFFF6B35) : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${plan.giorni.length} giorni di allenamento',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.checkmark,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              if (plan.obiettivo.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? const Color(0xFFFF6B35).withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    plan.obiettivo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Padding bottom per evitare sovrapposizioni
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Settimana',
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _totalWeeks,
            itemBuilder: (context, index) {
              final week = index + 1;
              final isSelected = week == _currentWeek;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _selectWeek(week),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 250),
                    scale: isSelected ? 1.03 : 1.0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6B35) : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '$week',
                            key: ValueKey('week_$week$isSelected'),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (_selectedPlan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _selectedPlan!.giorni.map((day) {
        // Filtra gli esercizi rimuovendo il riscaldamento
        final exercises = day.esercizi
            .where((exercise) => !exercise.nome.trim().toLowerCase().contains('riscaldamento'))
            .toList();

        if (exercises.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header del giorno con design moderno
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.1),
                      const Color(0xFFFF6B35).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.calendar_today,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.giorno,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.focus,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${exercises.length} esercizi',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista esercizi con nuovo design
              ...exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                final isLast = index == exercises.length - 1;
                return _buildModernExerciseProgress(day.giorno, exercise, isLast);
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernExerciseProgress(String dayName, Exercise exercise, bool isLast) {
    final key = '${dayName}_${exercise.nome}';
    final progressList = _progressData[key] ?? [];
    final currentProgress = progressList.isNotEmpty && _currentWeek <= progressList.length
        ? progressList[_currentWeek - 1]
        : null;

    final completed = currentProgress?.isCompleted == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: isLast 
            ? null 
            : Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        children: [
          // Header dell'esercizio
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: completed
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [const Color(0xFFFF6B35).withOpacity(0.8), const Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (completed ? Colors.green : const Color(0xFFFF6B35)).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  completed ? CupertinoIcons.checkmark : CupertinoIcons.sportscourt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nome,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: completed ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.serie} serie × ${exercise.ripetizioni} reps',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Sezione input con design moderno
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: completed ? Colors.green.withOpacity(0.2) : const Color(0xFFFF6B35).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInputField(
                        'Peso (kg)',
                        currentProgress?.weight.toString() ?? '0',
                        (value) => _updateProgress(key, weight: double.tryParse(value) ?? 0),
                        fieldKey: ValueKey('weight_${key}_$_currentWeek'),
                        icon: CupertinoIcons.timer,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernInputField(
                        'Ripetizioni',
                        currentProgress?.reps.toString() ?? '0',
                        (value) => _updateProgress(key, reps: int.tryParse(value) ?? 0),
                        fieldKey: ValueKey('reps_${key}_$_currentWeek'),
                        icon: CupertinoIcons.repeat,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Bottone di completamento moderno
                GestureDetector(
                  onTap: () => _toggleCompletion(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: completed
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [const Color(0xFFFF6B35), const Color(0xFFFF8A65)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (completed ? Colors.green : const Color(0xFFFF6B35)).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          completed ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            completed ? 'Completato!' : 'Segna come completato',
                            key: ValueKey(completed),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputField(
    String label,
    String value,
    Function(String) onChanged, {
    required Key fieldKey,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            key: fieldKey,
            initialValue: value == '0' ? '' : value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: '0',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _selectWeek(int week) {
    setState(() {
      _currentWeek = week;
    });
  }

  void _updateProgress(String key, {double? weight, int? reps}) {
    final progressList = _progressData[key];
    if (progressList != null && _currentWeek <= progressList.length) {
      final currentProgress = progressList[_currentWeek - 1];
      final updated = ExerciseProgress(
        week: _currentWeek,
        weight: weight ?? currentProgress.weight,
        reps: reps ?? currentProgress.reps,
        isCompleted: currentProgress.isCompleted,
      );
      progressList[_currentWeek - 1] = updated;
      setState(() {});

      _persistUpsertFromKey(
        key: key,
        weight: weight,
        reps: reps,
        isCompleted: null,
      );
    }
  }

  void _toggleCompletion(String key) {
    final progressList = _progressData[key];
    if (progressList != null && _currentWeek <= progressList.length) {
      final currentProgress = progressList[_currentWeek - 1];
      final newCompleted = !currentProgress.isCompleted;
      progressList[_currentWeek - 1] = ExerciseProgress(
        week: _currentWeek,
        weight: currentProgress.weight,
        reps: currentProgress.reps,
        isCompleted: newCompleted,
      );
      setState(() {});

      _persistUpsertFromKey(
        key: key,
        weight: null,
        reps: null,
        isCompleted: newCompleted,
      );
    }
  }

  Future<void> _persistUpsertFromKey({
    required String key,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) async {
    if (_selectedPlan == null || _selectedPlan!.id == null || _selectedPlan!.id!.isEmpty) {
      debugPrint('Piano non selezionato o senza ID');
      return;
    }
    if (_userId.isEmpty) {
      debugPrint('Utente non autenticato');
      return;
    }

    final planId = _selectedPlan!.id!;
    final parsed = _parseKey(key);
    final dayName = parsed.key;
    final exerciseName = parsed.value;

    try {
      await _progressDAO.upsertProgress(
        userId: _userId,
        planId: planId,
        dayName: dayName,
        exerciseName: exerciseName,
        week: _currentWeek,
        weight: weight,
        reps: reps,
        isCompleted: isCompleted,
      );
      debugPrint('Progresso salvato: $dayName / $exerciseName / week=$_currentWeek');
    } catch (e) {
      debugPrint('Errore salvataggio progresso: $e');
      _showErrorDialog('Errore di connessione. Riprova più tardi.');
    }
  }

  MapEntry<String, String> _parseKey(String key) {
    final idx = key.indexOf('_');
    if (idx <= 0) return MapEntry('', key);
    return MapEntry(key.substring(0, idx), key.substring(idx + 1));
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Errore'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int _getTrackedExercisesCount() {
    if (_selectedPlan == null) return 0;
    return _selectedPlan!.giorni
        .expand((day) => day.esercizi)
        .where((ex) => !ex.nome.trim().toLowerCase().contains('riscaldamento'))
        .length;
  }

  String _dots(int n) => List.filled(n, '.').join();

  // Animazione di caricamento migliorata e più fluida
// Animazione di caricamento migliorata e più fluida
Widget _buildLoadingProgress() {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F7),
    body: Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _breathAnim, _pulseAnim]),
        builder: (_, __) {
          final glow = _glowAnim.value;
          final pulse = _pulseAnim.value;
          
          return Transform.scale(
            scale: _breathAnim.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container principale con effetti migliorati
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        const Color(0xFFFAFAFA),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      // Ombra principale
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08 + glow * 0.1),
                        blurRadius: 25 + (15 * glow),
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                      // Ombra glow colorata
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.15 + glow * 0.1),
                        blurRadius: 40 + (20 * glow),
                        offset: const Offset(0, 8),
                      ),
                      // Ombra interna per profondità
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background animato
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B35).withOpacity(0.05 + glow * 0.05),
                                const Color(0xFFFF8A65).withOpacity(0.03 + glow * 0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Contenuto principale
                        _riveAvailable
                            ? Transform.scale(
                                scale: 0.9 + (pulse * 0.1),
                                child: const rive.RiveAnimation.asset(
                                  'assets/loading_fitness.riv', 
                                  fit: BoxFit.cover
                                ),
                              )
                            : RotationTransition(
                                turns: _rotationAnimation,
                                child: Transform.scale(
                                  scale: 0.8 + (pulse * 0.2),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Testo con animazione dei puntini più fluida
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) {
                    final progress = _loadingController.value;
                    final n = 1 + ((progress * 4).floor() % 3);
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 150),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, -2 * (1 - value)),
                          child: Opacity(
                            opacity: 0.7 + (0.3 * value),
                            child: Text(
                              'Caricamento progressi${_dots(n)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C2C),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Sottotitolo con fade
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value * 0.7,
                      child: Text(
                        'Sto sincronizzando i tuoi dati di allenamento',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.55),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Indicatore di progresso
                Container(
                  width: 220,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Color(0xFFE7E7EA),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}}