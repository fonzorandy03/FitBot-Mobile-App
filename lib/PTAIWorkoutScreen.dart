import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PTAIWorkoutScreen extends StatefulWidget {
  final String exerciseName;
  final int targetReps;
  
  const PTAIWorkoutScreen({
    Key? key,
    required this.exerciseName,
    required this.targetReps,
  }) : super(key: key);

  @override
  State<PTAIWorkoutScreen> createState() => _PTAIWorkoutScreenState();
}

class _PTAIWorkoutScreenState extends State<PTAIWorkoutScreen>
    with TickerProviderStateMixin {
  
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  // PT AI State
  String _detectedExercise = '';
  int _repsCount = 0;
  double _confidence = 0.0;
  int _formScore = 0;
  List<String> _feedback = [];
  bool _isAnalyzing = false;
  
  // Timer per frame processing
  Timer? _frameTimer;
  
  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // API Configuration
  static const String API_URL = 'http://127.0.0.1:5000/health';  // ⚠️ MODIFICA QUESTO
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showError('Nessuna fotocamera disponibile');
        return;
      }
      
      // Usa fotocamera frontale se disponibile
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startFrameProcessing();
      }
    } catch (e) {
      _showError('Errore inizializzazione fotocamera: $e');
    }
  }
  
  void _startFrameProcessing() {
    // Processa un frame ogni 500ms (2 FPS per non sovraccaricare)
    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isCameraInitialized && !_isAnalyzing) {
        _captureAndAnalyzeFrame();
      }
    });
  }
  
  Future<void> _captureAndAnalyzeFrame() async {
    if (!_isCameraInitialized || _isAnalyzing) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Invia al server PT AI
      final response = await http.post(
        Uri.parse('$API_URL/api/pt-ai/analyze-frame'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'frame': 'data:image/jpeg;base64,$base64Image',
        }),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _detectedExercise = data['exercise'] ?? '';
            _repsCount = data['reps'] ?? 0;
            _confidence = (data['confidence'] ?? 0.0).toDouble();
            _formScore = data['form_score'] ?? 0;
            _feedback = List<String>.from(data['feedback'] ?? []);
          });
          
          // Feedback vocale/vibrazione se completato
          if (_repsCount >= widget.targetReps && _repsCount > 0) {
            _onWorkoutComplete();
          }
        }
      }
    } catch (e) {
      print('Errore analisi frame: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
  
  void _onWorkoutComplete() {
    _frameTimer?.cancel();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Completato!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hai completato ${widget.targetReps} ripetizioni!'),
            const SizedBox(height: 16),
            Text('Forma: $_formScore/100'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'reps': _repsCount,
                'form_score': _formScore,
              });
            },
            child: const Text('Termina'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCounters();
              _startFrameProcessing();
            },
            child: const Text('Continua'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetCounters() async {
    try {
      await http.post(
        Uri.parse('$API_URL/api/pt-ai/reset-reps'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'exercise': _detectedExercise,
        }),
      );
      
      setState(() {
        _repsCount = 0;
        _formScore = 0;
        _feedback = [];
      });
    } catch (e) {
      print('Errore reset: $e');
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isCameraInitialized)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            
            // Overlay UI
            _buildOverlayUI(),
            
            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverlayUI() {
    return Column(
      children: [
        const Spacer(),
        
        // Stats Container
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getFormColor().withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Exercise Name
              Text(
                _detectedExercise.isEmpty ? 'In attesa...' : _detectedExercise,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (_confidence > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Reps Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85A30),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE85A30).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_repsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '/ ${widget.targetReps}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Form Score
              if (_formScore > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Forma:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$_formScore/100',
                          style: TextStyle(
                            color: _getFormColor(),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getFormIcon(),
                          color: _getFormColor(),
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _formScore / 100,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_getFormColor()),
                    minHeight: 8,
                  ),
                ),
              ],
              
              // Feedback
              if (_feedback.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                ..._feedback.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getFormColor() {
    if (_formScore >= 85) return Colors.green;
    if (_formScore >= 70) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getFormIcon() {
    if (_formScore >= 85) return Icons.check_circle;
    if (_formScore >= 70) return Icons.warning_rounded;
    return Icons.error_outline;
  }
}