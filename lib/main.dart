import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive hide LinearGradient;
import 'package:provider/provider.dart';
import 'custom_bottom_navbar.dart';
import 'WorkoutScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_init.dart';
import 'authcontext.dart';
import 'loginscreen.dart';
import 'TracciamentoProgressi.dart';
import  'DietScreen.dart';


void main() async {
  // Necessario per inizializzare i plugin prima di runApp
  WidgetsFlutterBinding.ensureInitialized();
 
  // Inizializza Firebase usando la tua classe
  await FirebaseInit.init();
 
  runApp(FitBotApp());
}

class FitBotApp extends StatelessWidget {
  const FitBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthContext()),
      ],
      child: MaterialApp(
        title: 'FitBot AI',
        theme: ThemeData(
          primaryColor: Color(0xFFE85A30),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: Colors.white,
        ),
        home: MainNavigation(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return child!;
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: FitBotNavItems.defaultItems,
      ),
    );
  }
  
  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return FitBotHomePage();
      case 1:
        return WorkoutScreen();
      case 2:
        return DietScreen();
      case 3:
        return ProgressTrackingScreen();
      case 4:
        return VideoScreen();
      default:
        return FitBotHomePage();
    }
  }
}

class FitBotHomePage extends StatefulWidget {
  const FitBotHomePage({super.key});

  @override
  _FitBotHomePageState createState() => _FitBotHomePageState();
}

class _FitBotHomePageState extends State<FitBotHomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    // Verifica che Firebase sia inizializzato correttamente
    print('Firebase apps: ${Firebase.apps.length}');
    if (Firebase.apps.isNotEmpty) {
      print('Firebase inizializzato correttamente!');
    }
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthContext>(
      builder: (context, authContext, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8F4F0),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 35),
                    
                    // Header con tasto login/logout
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildHeader(authContext),
                    ),
                    
                    SizedBox(height: 20),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildLogo(),
                    ),
                    
                    SizedBox(height: 30),
                    
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildMainTitle(authContext),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildStatsSection(),
                      ),
                    ),
                    
                    SizedBox(height: 50),
                    
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFeaturesSection(),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTestimonialSection(),
                    ),
                    
                    SizedBox(height: 50),
                    
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCTASection(authContext),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthContext authContext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          authContext.isAuthenticated 
            ? 'Ciao, ${authContext.displayName}!'
            : 'FitBot AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        if (authContext.isAuthenticated)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await authContext.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF666666)),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFE85A30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  authContext.userInitials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            icon: Icon(Icons.login, size: 18),
            label: Text('Accedi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE85A30),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isAnimating = !_isAnimating;
            });
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFE85A30),
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
            child: AnimatedScale(
              scale: _isAnimating ? 1.1 : 1.0,
              duration: Duration(milliseconds: 200),
              child: Center(
                child: Text(
                  'FB',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FitBot',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
                letterSpacing: -1,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFE85A30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainTitle(AuthContext authContext) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFFE85A30),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            'Powered by AI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          authContext.isAuthenticated ? 'Benvenuto!' : 'Il Futuro del',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2C2C),
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        if (!authContext.isAuthenticated)
          Text(
            'Fitness',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE85A30),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
        SizedBox(height: 20),
        Text(
          authContext.isAuthenticated
            ? 'Sei pronto per il tuo allenamento di oggi? I tuoi piani personalizzati ti aspettano!'
            : 'Trasforma il tuo corpo con piani di allenamento e nutrizione personalizzati creati dall\'intelligenza artificiale.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: authContext.isAuthenticated
  ? () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WorkoutScreen()),
      );
    }
  : () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE85A30),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                authContext.isAuthenticated ? 'Inizia Allenamento' : 'Inizia Subito',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!authContext.isAuthenticated) ...[
              SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFFE85A30),
                  side: BorderSide(color: Color(0xFFE85A30)),
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Guarda Demo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('50K+', 'Utenti Attivi'),
          _buildStatDivider(),
          _buildStatItem('1M+', 'Allenamenti Completati'),
          _buildStatDivider(),
          _buildStatItem('95%', 'Soddisfazione'),
          _buildStatDivider(),
          _buildStatItem('4.9', 'Rating App Store'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE85A30),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Color(0xFFE0E0E0),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        Text(
          'Perché Scegliere FITBOT',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2C2C),
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'La tecnologia più avanzata al servizio del tuo benessere',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        Column(
          children: [
            _buildAnimatedFeatureCard(
              icon: Icons.fitness_center,
              title: 'Allenamenti Personalizzati',
              description: 'Piani di workout creati su misura per i tuoi obiettivi e il tuo livello di fitness.',
              color: Color(0xFFE85A30),
              delay: 0,
            ),
            SizedBox(height: 16),
            _buildAnimatedFeatureCard(
              icon: Icons.restaurant,
              title: 'Nutrizione Intelligente',
              description: 'Piani alimentari ottimizzati basati sui tuoi gusti e necessità nutrizionali.',
              color: Color(0xFF4CAF50),
              delay: 200,
            ),
            SizedBox(height: 16),
            _buildAnimatedFeatureCard(
              icon: Icons.trending_up,
              title: 'Tracciamento Progressi',
              description: 'Monitora i tuoi miglioramenti con analytics avanzati e intelligenza artificiale.',
              color: Color(0xFF2196F3),
              delay: 400,
            ),
            SizedBox(height: 16),
            _buildAnimatedFeatureCard(
              icon: Icons.psychology,
              title: 'AI Powered',
              description: 'Intelligenza artificiale che si adatta continuamente alle tue esigenze.',
              color: Color(0xFF9C27B0),
              delay: 600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: AnimatedOpacity(
                opacity: value,
                duration: Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05 + (0.03 * value)),
                          spreadRadius: 0,
                          blurRadius: 15 + (5 * value),
                          offset: Offset(0, 5 + (3 * value)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1 + (0.05 * value)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedRotation(
                            turns: value * 0.1,
                            duration: Duration(milliseconds: 800),
                            child: Icon(
                              icon,
                              color: color,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C2C2C),
                                ),
                                child: Text(title),
                              ),
                              SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  height: 1.4,
                                ),
                                child: Text(description),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 6,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.3 * value),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTestimonialSection() {
    return Container(
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
        children: [
          Text(
            'Cosa Dicono i Nostri Utenti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: Color(0xFFFFB800),
                size: 20,
              );
            }),
          ),
          SizedBox(height: 16),
          Text(
            '"I piani di allenamento sono perfetti per la mia routine quotidiana."',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2C2C2C),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE85A30),
                child: Text(
                  'AM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Andrea M.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  Text(
                    'Manager',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(AuthContext authContext) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE85A30), Color(0xFFD14420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            authContext.isAuthenticated 
              ? 'Il Tuo Piano Ti Aspetta!'
              : 'Pronto a Trasformare il Tuo Corpo?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            authContext.isAuthenticated
              ? 'Inizia subito il tuo allenamento personalizzato e raggiungi i tuoi obiettivi!'
              : 'Unisciti a migliaia di persone che hanno già raggiunto i loro obiettivi con FITBOT',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: authContext.isAuthenticated
                  ? () {
                      // Naviga al workout
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Iniziando il tuo piano personalizzato!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFE85A30),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authContext.isAuthenticated ? 'Vai al Workout' : 'Crea il Tuo Piano',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: authContext.isAuthenticated
              ? [
                  _buildCTAFeature('✓ Personalizzato per te'),
                  _buildCTAFeature('✓ Aggiornato quotidianamente'),
                  _buildCTAFeature('✓ Risultati garantiti'),
                ]
              : [
                  _buildCTAFeature('✓ Prova gratuita'),
                  _buildCTAFeature('✓ Nessun impegno'),
                  _buildCTAFeature('✓ Risultati garantiti'),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTAFeature(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Pagine placeholder per le altre sezioni


class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F4F0), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 80, color: Color(0xFF2196F3)),
              SizedBox(height: 24),
              Text(
                'Progressi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              Text(
                'Traccia i tuoi miglioramenti',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F4F0), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle, size: 80, color: Color(0xFF9C27B0)),
              SizedBox(height: 24),
              Text(
                'Video',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              Text(
                'Tutorial e guide video',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}