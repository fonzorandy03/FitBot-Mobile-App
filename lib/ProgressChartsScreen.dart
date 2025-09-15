import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart' as rive;
import 'package:fl_chart/fl_chart.dart';

import 'progressdao.dart';
import 'authcontext.dart';
import 'WorkoutPlanDao.dart';
import 'LoginScreen.dart';

class ProgressChartsScreen extends StatefulWidget {
  const ProgressChartsScreen({super.key});

  @override
  State<ProgressChartsScreen> createState() => _ProgressChartsScreenState();
}

class ExerciseChartData {
  final String exerciseName;
  final String dayName;
  final List<WeekData> weekData;
  final double improvementPercent;
  final ProgressTrend trend;

  ExerciseChartData({
    required this.exerciseName,
    required this.dayName,
    required this.weekData,
    required this.improvementPercent,
    required this.trend,
  });
}

class WeekData {
  final int week;
  final double weight;
  final int reps;
  final bool isCompleted;
  final double totalVolume;

  WeekData({
    required this.week,
    required this.weight,
    required this.reps,
    required this.isCompleted,
  }) : totalVolume = weight * reps;
}

enum ProgressTrend { improving, declining, stable, noData }

class _ProgressChartsScreenState extends State<ProgressChartsScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _chartController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _chartAnimation;

  // Loading animations
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
  bool _hasNoData = false;
  List<ExerciseChartData> _chartData = [];
  String _selectedMetric = 'volume'; // 'volume', 'weight', 'reps'

  @override
  void initState() {
    super.initState();

    // Initialize animations
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
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic));

    // Loading animations
    _loadingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOutSine)
    );

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
    
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginRequired();
      });
      return;
    }
    
    if (_userId != currentUid) {
      _userId = currentUid;
      _loadData();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _chartController.dispose();
    _loadingController.dispose();
    _breathController.dispose();
    super.dispose();
  }

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
                CupertinoIcons.chart_bar,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Accesso Richiesto'),
          ],
        ),
        content: const Text(
          'Per visualizzare i grafici dei tuoi progressi devi prima effettuare l\'accesso al tuo account.',
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
              Navigator.pop(context);
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
      final auth = context.read<AuthContext>();
      if (auth.isAuthenticated) {
        _userId = auth.user?.uid ?? '';
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthContext>();
    if (!auth.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _hasNoData = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasNoData = false;
      _workoutPlans = [];
      _selectedPlan = null;
      _chartData = [];
    });
    _loadingController.repeat();

    try {
      if (_userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoData = true;
        });
        _loadingController.stop();
        return;
      }

      final result = await _workoutDAO.getUserWorkoutPlans(activeOnly: false);

      if (!result.success || result.workoutPlans == null || result.workoutPlans!.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoData = true;
        });
        _loadingController.stop();
        return;
      }

      _workoutPlans = result.workoutPlans!;
      _selectedPlan = _workoutPlans.first;

      await _loadProgressData();

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _fadeController.reset();
      _slideController.reset();
      _scaleController.reset();
      _chartController.reset();
      
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 150));
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _scaleController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _chartController.forward();

      _loadingController.stop();
    } catch (e) {
      setState(() => _isLoading = false);
      _loadingController.stop();
      _showErrorDialog('Errore nel caricamento dei dati: $e');
    }
  }

  Future<void> _loadProgressData() async {
    if (_selectedPlan == null || _selectedPlan!.id == null || _selectedPlan!.id!.isEmpty) return;

    try {
      // Fixed: Use first() instead of take(1).last to get the current snapshot
      final entries = await _progressDAO
          .streamPlanProgress(userId: _userId, planId: _selectedPlan!.id!)
          .first;

      if (mounted) {
        setState(() {
          _chartData = _processChartData(entries);
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento dati grafici: $e');
      if (mounted) {
        setState(() {
          _chartData = [];
        });
      }
    }
  }

  
List<ExerciseChartData> _processChartData(List<ProgressEntry> entries) {
  print('DEBUG: Processing ${entries.length} entries'); // Debug
  
  if (entries.isEmpty) return [];

  final Map<String, List<WeekData>> exerciseData = {};

  // Group by exercise
  for (final entry in entries) {
    print('DEBUG: Processing entry - Day: ${entry.dayName}, Exercise: ${entry.exerciseName}, Week: ${entry.week}, Weight: ${entry.weight}, Reps: ${entry.reps}, Completed: ${entry.isCompleted}');
    
    // Skip warm-up exercises con controlli più flessibili
    final exerciseNameLower = entry.exerciseName.trim().toLowerCase();
    if (exerciseNameLower.contains('riscaldamento') ||
        exerciseNameLower.contains('warmup') ||
        exerciseNameLower.contains('warm-up')) {
      print('DEBUG: Skipping warm-up exercise: ${entry.exerciseName}');
      continue;
    }

    // RIMOSSO il filtro troppo restrittivo sui dati "non significativi"
    // Ora accettiamo anche entry con weight=0 e reps=0 se sono completate
    // o se hanno almeno un valore > 0
    
    final key = '${entry.dayName}_${entry.exerciseName}';
    exerciseData[key] ??= [];
    
    exerciseData[key]!.add(WeekData(
      week: entry.week,
      weight: entry.weight,
      reps: entry.reps,
      isCompleted: entry.isCompleted,
    ));
    
    print('DEBUG: Added data for key: $key, Week: ${entry.week}');
  }

  print('DEBUG: Exercise data keys: ${exerciseData.keys.toList()}');

  // Create chart data
  final List<ExerciseChartData> chartData = [];
  
  exerciseData.entries.forEach((entry) {
    final key = entry.key;
    final data = entry.value;
    
    print('DEBUG: Processing key: $key with ${data.length} weeks of data');
    
    if (data.isEmpty) {
      print('DEBUG: Skipping $key - no data');
      return;
    }
    
    // Sort by week
    data.sort((a, b) => a.week.compareTo(b.week));
    
    final parts = key.split('_');
    final dayName = parts.isNotEmpty ? parts[0] : '';
    final exerciseName = parts.length > 1 ? parts.sublist(1).join('_') : key;
    
    print('DEBUG: Creating chart data for $exerciseName on $dayName');
    
    // Calculate trend and improvement - versione più permissiva
    final improvement = _calculateImprovement(data);
    final trend = _calculateTrend(data);

    print('DEBUG: Improvement: $improvement%, Trend: $trend');

    chartData.add(ExerciseChartData(
      exerciseName: exerciseName,
      dayName: dayName,
      weekData: data,
      improvementPercent: improvement,
      trend: trend,
    ));
  });

  print('DEBUG: Final chart data count: ${chartData.length}');
  return chartData;
}

  double _calculateImprovement(List<WeekData> data) {
  if (data.length < 2) return 0.0;
  
  // Trova il primo e l'ultimo valore valido (non necessariamente con volume > 0)
  WeekData? firstValid;
  WeekData? lastValid;
  
  for (final week in data) {
    if (week.totalVolume > 0 || week.isCompleted) {
      firstValid ??= week;
      lastValid = week;
    }
  }
  
  if (firstValid == null || lastValid == null || firstValid == lastValid) {
    return 0.0;
  }

  final first = firstValid.totalVolume;
  final last = lastValid.totalVolume;
  
  // Se entrambi i valori sono 0, guarda solo il completamento
  if (first == 0 && last == 0) {
    if (!firstValid.isCompleted && lastValid.isCompleted) return 100.0;
    if (firstValid.isCompleted && !lastValid.isCompleted) return -100.0;
    return 0.0;
  }
  
  if (first == 0) return last > 0 ? 100.0 : 0.0;
  return ((last - first) / first) * 100;
}

ProgressTrend _calculateTrend(List<WeekData> data) {
  if (data.length < 2) return ProgressTrend.noData;
  
  // Conta i completamenti e i volumi nelle ultime settimane
  final recentData = data.length >= 3 ? data.sublist(data.length - 3) : data;
  
  int completedCount = 0;
  double totalVolumeChange = 0.0;
  int volumeChanges = 0;
  
  for (int i = 1; i < recentData.length; i++) {
    final prev = recentData[i - 1];
    final curr = recentData[i];
    
    if (curr.isCompleted) completedCount++;
    
    if (prev.totalVolume > 0 && curr.totalVolume > 0) {
      totalVolumeChange += (curr.totalVolume - prev.totalVolume) / prev.totalVolume;
      volumeChanges++;
    } else if (prev.totalVolume == 0 && curr.totalVolume > 0) {
      totalVolumeChange += 1.0; // 100% improvement
      volumeChanges++;
    }
  }

  // Se abbiamo miglioramenti nel volume o più completamenti
  if (volumeChanges > 0) {
    final avgChange = totalVolumeChange / volumeChanges;
    if (avgChange > 0.05) return ProgressTrend.improving;
    if (avgChange < -0.05) return ProgressTrend.declining;
  }
  
  // Se non abbiamo cambi di volume ma abbiamo completamenti
  if (completedCount > recentData.length * 0.5) {
    return ProgressTrend.improving;
  }
  
  return completedCount > 0 ? ProgressTrend.stable : ProgressTrend.noData;
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthContext>();
    if (!auth.isAuthenticated) {
      return _buildNotAuthenticatedScreen();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasNoData || _chartData.isEmpty) {
      return _buildNoDataScreen();
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
                      const SizedBox(height: 20),
                      _buildStatsOverview(),
                      const SizedBox(height: 24),
                      _buildPlanSelector(),
                      const SizedBox(height: 20),
                      _buildMetricSelector(),
                      const SizedBox(height: 24),
                      _buildChartsSection(),
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

  Widget _buildNotAuthenticatedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_bar,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Accesso Richiesto',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Per visualizzare i grafici dei tuoi progressi, devi prima effettuare l\'accesso.',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Torna indietro',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Center(
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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFFFAFAFA),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08 + glow * 0.1),
                            blurRadius: 20 + (10 * glow),
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.15 + glow * 0.1),
                            blurRadius: 30 + (15 * glow),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.chart_bar,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (_, __) {
                        final progress = _loadingController.value;
                        final n = 1 + ((progress * 4).floor() % 3);
                        return Text(
                          'Analizzando progressi${List.filled(n, '.').join()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Sto elaborando i tuoi dati di allenamento',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.55),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                  'Nessun dato disponibile',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Inizia a tracciare i tuoi progressi per vedere i grafici qui.',
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
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: false,
      backgroundColor: const Color(0xFFF5F5F7),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.back,
              color: Color(0xFFFF6B35),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analisi Progressi',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visualizza l\'evoluzione dei tuoi allenamenti',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Container(
              width: 32,
              height: 32,
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
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final improvingCount = _chartData.where((d) => d.trend == ProgressTrend.improving).length;
    final decliningCount = _chartData.where((d) => d.trend == ProgressTrend.declining).length;
    final avgImprovement = _chartData.isNotEmpty 
        ? _chartData.map((d) => d.improvementPercent).reduce((a, b) => a + b) / _chartData.length
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
                      Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Miglioramento',
                  '$improvingCount',
                  CupertinoIcons.arrow_up_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'In Calo',
                  '$decliningCount',
                  CupertinoIcons.arrow_down_circle,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Progresso Medio',
            '${avgImprovement.toStringAsFixed(1)}%',
            CupertinoIcons.chart_bar_alt_fill,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _showPlanSelector,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.doc_text, color: Color(0xFFFF6B35), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Piano di Allenamento',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedPlan?.titolo ?? 'Nessun piano selezionato',
                    style: const TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildMetricSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _metricChip(
              'volume', 
              CupertinoIcons.chart_bar, 
              _selectedMetric == 'volume',
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metricChip(
              'weight', 
              CupertinoIcons.speedometer, 
              _selectedMetric == 'weight',
              gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metricChip(
              'reps', 
              CupertinoIcons.number, 
              _selectedMetric == 'reps',
              gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String key, IconData icon, bool selected, {required LinearGradient gradient}) {
  return GestureDetector(
    onTap: () {
      print('DEBUG: Switching to metric: $key'); // Debug
      setState(() => _selectedMetric = key);
      
      // Forza l'animazione del grafico per il refresh
      _chartController.reset();
      _chartController.forward();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: selected ? gradient : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: (selected ? const Color(0xFFFF6B35) : Colors.black).withOpacity(selected ? 0.15 : 0.04),
            blurRadius: selected ? 8 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: selected ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 6),
          Text(
            key.toUpperCase(),
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildChartsSection() {
    if (_chartData.isEmpty) return const SizedBox.shrink();

    // Sort: improving first, then stable, then declining, then noData
    final sorted = [..._chartData]..sort((a, b) {
      int rank(ProgressTrend t) {
        switch (t) {
          case ProgressTrend.improving: return 0;
          case ProgressTrend.stable: return 1;
          case ProgressTrend.declining: return 2;
          case ProgressTrend.noData: return 3;
        }
      }
      final r = rank(a.trend).compareTo(rank(b.trend));
      if (r != 0) return r;
      return a.exerciseName.compareTo(b.exerciseName);
    });

    return Column(
      children: [
        for (final d in sorted) _buildExerciseChartCard(d),
      ],
    );
  }
Widget _buildExerciseChartCard(ExerciseChartData d) {
  // Prepare series for weeks 1..8
  const totalWeeks = 8;
  final List<double> series = List.filled(totalWeeks, 0);
  
  // Debug: stampa i dati disponibili
  print('=== BUILDING CHART FOR ${d.exerciseName} ===');
  print('Available week data: ${d.weekData.length} weeks');
  print('Selected metric: $_selectedMetric');
  
  for (final w in d.weekData) {
    print('Week ${w.week}: weight=${w.weight}, reps=${w.reps}, volume=${w.totalVolume}, completed=${w.isCompleted}');
    
    if (w.week >= 1 && w.week <= totalWeeks) {
      double value = 0;
      switch (_selectedMetric) {
        case 'weight':
          value = w.weight;
          break;
        case 'reps':
          value = w.reps.toDouble();
          break;
        case 'volume':
        default:
          value = w.totalVolume;
          break;
      }
      series[w.week - 1] = value;
      print('Week ${w.week} -> ${_selectedMetric}: $value');
    }
  }
  
  print('Final series: $series');

  // Calcola il massimo Y in modo più robusto
  double maxY = series.fold<double>(0, (m, v) => v > m ? v : m);
  
  // Se tutti i valori sono 0, imposta un minimo per evitare grafici vuoti
  if (maxY <= 0) {
    maxY = _selectedMetric == 'reps' ? 20 : (_selectedMetric == 'weight' ? 100 : 50);
    print('All values are 0, setting maxY to: $maxY');
  }
  
  print('MaxY: $maxY');
  print('=====================================');

  final gradient = _getGradientForMetric(_selectedMetric);

  Color trendColor;
  IconData trendIcon;
  switch (d.trend) {
    case ProgressTrend.improving:
      trendColor = Colors.green;
      trendIcon = CupertinoIcons.arrow_up_right_circle_fill;
      break;
    case ProgressTrend.declining:
      trendColor = Colors.red;
      trendIcon = CupertinoIcons.arrow_down_right_circle_fill;
      break;
    case ProgressTrend.stable:
      trendColor = Colors.orange;
      trendIcon = CupertinoIcons.equal_circle_fill;
      break;
    case ProgressTrend.noData:
      trendColor = Colors.grey;
      trendIcon = CupertinoIcons.minus_circle_fill;
      break;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForMetric(_selectedMetric),
                color: Colors.white, 
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.exerciseName, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.dayName,
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.black.withOpacity(0.6), 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 14, color: trendColor),
                  const SizedBox(width: 4),
                  Text(
                    _fmtPercent(d.improvementPercent),
                    style: TextStyle(
                      color: trendColor, 
                      fontWeight: FontWeight.w800, 
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Chart - Wrappato in AnimatedBuilder per ricostruirsi quando cambia la metrica
        AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: totalWeeks.toDouble(),
                  minY: 0,
                  maxY: maxY * 1.1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY <= 0 ? 1 : (maxY / 4).clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45, // Aumentato per numeri più grandi
                        getTitlesWidget: (v, meta) => Text(
                          _formatYAxisValue(v, _selectedMetric),
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5), 
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'S${v.toInt()}',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5), 
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      curveSmoothness: 0.3,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: gradient.colors.first,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      gradient: gradient,
                      spots: [
                        for (int w = 1; w <= totalWeeks; w++)
                          FlSpot(
                            w.toDouble(),
                            series[w - 1] * _chartAnimation.value,
                          ),
                      ],
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradient.colors.map((c) => c.withOpacity(0.15)).toList(),
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
LinearGradient _getGradientForMetric(String metric) {
  switch (metric) {
    case 'weight':
      return const LinearGradient(colors: [Colors.teal, Colors.tealAccent]);
    case 'reps':
      return const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]);
    case 'volume':
    default:
      return const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)]);
  }
}

IconData _getIconForMetric(String metric) {
  switch (metric) {
    case 'weight':
      return CupertinoIcons.speedometer;
    case 'reps':
      return CupertinoIcons.number;
    case 'volume':
    default:
      return CupertinoIcons.chart_bar_alt_fill;
  }
}

String _formatYAxisValue(double value, String metric) {
  if (value == 0) return '0';
  
  switch (metric) {
    case 'weight':
      return '${value.toInt()}kg';
    case 'reps':
      return '${value.toInt()}';
    case 'volume':
    default:
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return value.toInt().toString();
  }
}
  void _showPlanSelector() {
    if (_workoutPlans.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_text, 
                        color: Color(0xFFFF6B35), 
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleziona Piano di Allenamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Plans list
              ..._workoutPlans.map((plan) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Material(
                  color: _selectedPlan?.id == plan.id 
                      ? const Color(0xFFFF6B35).withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      setState(() {
                        _selectedPlan = plan;
                        _chartData = [];
                      });
                      await _loadProgressData();
                      if (mounted) Navigator.pop(context);
                      _chartController.forward(from: 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: _selectedPlan?.id == plan.id 
                            ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                            : Border.all(color: Colors.grey.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: _selectedPlan?.id == plan.id 
                                  ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)])
                                  : LinearGradient(colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              CupertinoIcons.sportscourt,
                              color: _selectedPlan?.id == plan.id ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.titolo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPlan?.id == plan.id 
                                        ? const Color(0xFFFF6B35) 
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${plan.giorni.length} giorni di allenamento',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_selectedPlan?.id == plan.id)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.checkmark,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtPercent(double v) {
    if (v.isNaN || v.isInfinite) return '0%';
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}%';
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
}