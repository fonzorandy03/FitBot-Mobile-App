import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';


class PTAIVideoAnalysisScreen extends StatefulWidget {
  final String exerciseName;
  
  const PTAIVideoAnalysisScreen({
    Key? key,
    required this.exerciseName,
  }) : super(key: key);

  @override
  State<PTAIVideoAnalysisScreen> createState() => _PTAIVideoAnalysisScreenState();
}

class _PTAIVideoAnalysisScreenState extends State<PTAIVideoAnalysisScreen>
    with TickerProviderStateMixin {
  
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // API Configuration
  static const String API_URL = 'http://10.0.2.2:5000'; // ⚠️ MODIFICA QUESTO
  
  final ImagePicker _picker = ImagePicker();
  
  // 🔧 MAPPING NOMI ESERCIZI - NOMI ESATTI DAL MODELLO
  final Map<String, String> exerciseNameMapping = {
    // Jumping Jacks
    'jumping jacks': 'Jumping Jacks',
    'jumpingjacks': 'Jumping Jacks',
    'jumping jack': 'Jumping Jacks',
    'jumpingjack': 'Jumping Jacks',
    
    // Pull ups
    'pull ups': 'Pull ups',
    'pullups': 'Pull ups',
    'pull up': 'Pull ups',
    'pullup': 'Pull ups',
    'pull-ups': 'Pull ups',
    'pull-up': 'Pull ups',
    'trazioni': 'Pull ups',
    
    // Push Ups
    'push ups': 'Push Ups',
    'pushups': 'Push Ups',
    'push up': 'Push Ups',
    'pushup': 'Push Ups',
    'push-ups': 'Push Ups',
    'push-up': 'Push Ups',
    'piegamenti': 'Push Ups',
    
    // Russian twists
    'russian twists': 'Russian twists',
    'russian twist': 'Russian twists',
    'russiantwists': 'Russian twists',
    'russiantwist': 'Russian twists',
    
    // Squats
    'squats': 'Squats',
    'squat': 'Squats',
  };
  
  String _normalizeExerciseName(String name) {
    final normalized = name.toLowerCase().trim();
    final mapped = exerciseNameMapping[normalized];
    
    if (mapped != null) {
      print('✅ Nome mappato: "$name" → "$mapped"');
      return mapped;
    }
    
    print('⚠️ Nome non trovato nel mapping, uso originale: "$name"');
    return name;
  }
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
          _analysisResult = null;
        });
        
        // Inizializza video player e ASPETTA il completamento
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_videoFile!);
        
        await _videoController!.initialize();
        setState(() {});
        
        print('✅ Video caricato - Durata: ${_videoController!.value.duration.inSeconds}s');
      }
    } catch (e) {
      _showError('Errore nel caricamento del video: $e');
    }
  }
  
  Future<void> _analyzeVideo() async {
    if (_videoFile == null) {
      _showError('Seleziona prima un video');
      return;
    }
    
    // VERIFICA che il controller sia inizializzato
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _showError('Video non ancora pronto, riprova tra un momento');
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });
    
    try {
      print('🎬 Inizio estrazione frame...');
      
      // 1. Estrai frame dal video
      List<String> frames = await _extractFrames(_videoFile!);
      
      print('📸 Frame estratti: ${frames.length}');
      
      if (frames.isEmpty) {
        throw Exception('Nessun frame estratto dal video');
      }
      
      // 2. Invia frame al server PT AI
      print('📤 Invio dati al server...');
      
      // 🔧 Normalizza il nome dell'esercizio
      final normalizedExerciseName = _normalizeExerciseName(widget.exerciseName);
      print('📝 Esercizio ORIGINALE: "${widget.exerciseName}"');
      print('📝 Esercizio NORMALIZZATO: "$normalizedExerciseName"');
      print('📊 Numero frame estratti: ${frames.length}');
      
      if (frames.isEmpty) {
        throw Exception('Nessun frame estratto dal video');
      }
      
      final response = await http.post(
        Uri.parse('$API_URL/api/pt-ai/analyze-video'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'frames': frames,
          'exercise': normalizedExerciseName,  // ← Usa nome normalizzato
        }),
      ).timeout(const Duration(seconds: 60));
      
      print('📥 Risposta server - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _analysisResult = data;
            _isAnalyzing = false;
          });
          print('✅ Analisi completata con successo!');
        } else {
          throw Exception(data['error'] ?? 'Analisi fallita');
        }
      } else {
        print('❌ Errore HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Errore server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Errore analisi: $e');
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Errore durante l\'analisi: $e');
    }
  }
  
  // 🔧 VERSIONE CORRETTA - Estrae frame dal video
  Future<List<String>> _extractFrames(File videoFile) async {
    final List<String> framesBase64 = [];

    try {
      // Ottieni la durata REALE dal video file (non dal controller)
      Duration? videoDuration;
      
      if (_videoController != null && _videoController!.value.isInitialized) {
        videoDuration = _videoController!.value.duration;
        print('📹 Durata video dal controller: ${videoDuration.inSeconds}s');
      }
      
      // Se la durata è ancora zero o null, estrai almeno 10 frame a intervalli fissi
      if (videoDuration == null || videoDuration == Duration.zero) {
        print('⚠️ Durata non disponibile, estraggo frame a intervalli fissi');
        
        // Prova a estrarre frame a 0, 500ms, 1s, 1.5s, ecc fino a 5s
        for (int i = 0; i < 10; i++) {
          final timeMs = i * 500;
          
          try {
            final Uint8List? uint8list = await VideoThumbnail.thumbnailData(
              video: videoFile.path,
              imageFormat: ImageFormat.JPEG,
              quality: 75,
              timeMs: timeMs,
            );

            if (uint8list != null && uint8list.isNotEmpty) {
              final base64Image = base64Encode(uint8list);
              framesBase64.add('data:image/jpeg;base64,$base64Image');
              print('✅ Frame $i estratto (${timeMs}ms)');
            }
          } catch (e) {
            print('⚠️ Impossibile estrarre frame a ${timeMs}ms: $e');
            break; // Se fallisce, probabilmente abbiamo superato la durata del video
          }
        }
        
        return framesBase64;
      }

      // Estrai frame ogni 500ms
      const stepMs = 500;
      final totalMs = videoDuration.inMilliseconds;
      
      print('📸 Estraggo frame ogni ${stepMs}ms per ${totalMs}ms totali');
      
      for (int timeMs = 0; timeMs < totalMs; timeMs += stepMs) {
        try {
          final Uint8List? uint8list = await VideoThumbnail.thumbnailData(
            video: videoFile.path,
            imageFormat: ImageFormat.JPEG,
            quality: 75,
            timeMs: timeMs,
          );

          if (uint8list != null && uint8list.isNotEmpty) {
            final base64Image = base64Encode(uint8list);
            framesBase64.add('data:image/jpeg;base64,$base64Image');
            print('✅ Frame estratto a ${timeMs}ms');
          } else {
            print('⚠️ Frame vuoto a ${timeMs}ms');
          }
        } catch (e) {
          print('❌ Errore estrazione frame a ${timeMs}ms: $e');
        }
      }

      print('📊 Totale frame estratti: ${framesBase64.length}');
      
      // Se non abbiamo estratto nessun frame, prova almeno il frame a 0
      if (framesBase64.isEmpty) {
        print('⚠️ Nessun frame estratto, provo frame a 0ms');
        final Uint8List? uint8list = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
          timeMs: 0,
        );

        if (uint8list != null) {
          final base64Image = base64Encode(uint8list);
          framesBase64.add('data:image/jpeg;base64,$base64Image');
        }
      }

      return framesBase64;
      
    } catch (e) {
      print('❌ Errore generale estrazione frame: $e');
      return framesBase64;
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        title: const Text(
          'Analisi Video',
          style: TextStyle(
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
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              if (_videoFile != null) ...[
                _buildVideoPreview(),
                const SizedBox(height: 24),
              ],
              
              _buildActionButtons(),
              const SizedBox(height: 32),
              
              if (_isAnalyzing)
                _buildLoadingWidget()
              else if (_analysisResult != null)
                _buildResultWidget(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.video_library, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Analisi: ${widget.exerciseName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Carica un video del tuo allenamento per ricevere feedback dettagliato',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_videoController!),
              
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF2196F3),
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _pickVideo,
            icon: const Icon(Icons.upload_rounded, size: 24),
            label: Text(
              _videoFile == null ? 'Carica Video' : 'Cambia Video',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (_videoFile != null)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeVideo,
              icon: const Icon(Icons.analytics_rounded, size: 24),
              label: const Text(
                'Analizza Video',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2196F3),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Analizzando il video...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'AI sta processando ogni frame per valutare la tua forma',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultWidget() {
    final result = _analysisResult!;
    final reps = result['total_reps'] ?? 0;
    final avgFormScore = result['avg_form_score'] ?? 0;
    final feedback = List<String>.from(result['feedback'] ?? []);
    final exerciseMatch = result['exercise_match'] ?? true;
    final detectedExercise = result['detected_exercise'] ?? '';
    final expectedExercise = result['expected_exercise'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risultati Analisi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2C2C),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ripetizioni',
                  '$reps',
                  Icons.repeat,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Forma Media',
                  '$avgFormScore/100',
                  Icons.star,
                  _getFormColor(avgFormScore),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (feedback.isNotEmpty) ...[
            const Text(
              'Feedback dell\'AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            ...feedback.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tip, style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C))),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
  
  Color _getFormColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}