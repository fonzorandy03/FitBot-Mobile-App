import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 🔍 SCHERMATA DI DIAGNOSTICA PT AI
/// Usa questa per capire cosa rileva veramente il modello
class PTAIDiagnosticScreen extends StatefulWidget {
  const PTAIDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<PTAIDiagnosticScreen> createState() => _PTAIDiagnosticScreenState();
}

class _PTAIDiagnosticScreenState extends State<PTAIDiagnosticScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _diagnosticResult;
  List<String>? _supportedExercises;
  
  static const String API_URL = 'http://10.0.2.2:5000'; // ⚠️ Modifica se necessario
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadSupportedExercises();
  }
  
  Future<void> _loadSupportedExercises() async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/pt-ai/supported-exercises'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _supportedExercises = List<String>.from(data['exercises']);
          });
        }
      }
    } catch (e) {
      print('Errore caricamento esercizi: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _diagnosticResult = null;
        });
      }
    } catch (e) {
      _showError('Errore nel caricamento dell\'immagine: $e');
    }
  }
  
  Future<void> _diagnoseImage() async {
    if (_imageFile == null) {
      _showError('Seleziona prima un\'immagine');
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _diagnosticResult = null;
    });
    
    try {
      // Converti immagine in base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      // Invia al server
      final response = await http.post(
        Uri.parse('$API_URL/api/pt-ai/diagnose-frame'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'frame': base64Image,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _diagnosticResult = data;
            _isAnalyzing = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Analisi fallita');
        }
      } else {
        throw Exception('Errore server: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Errore durante l\'analisi: $e');
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
          '🔍 PT AI Diagnostica',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Strumento di Diagnostica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Carica un\'immagine di un esercizio per vedere cosa rileva esattamente l\'AI e con quali probabilità.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Esercizi Supportati
            if (_supportedExercises != null) ...[
              const Text(
                'Esercizi Supportati dal Modello:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _supportedExercises!.map((exercise) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      exercise,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Image Preview
            if (_imageFile != null) ...[
              Container(
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
                  child: Image.file(
                    _imageFile!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _pickImage,
                icon: const Icon(Icons.image, size: 24),
                label: Text(
                  _imageFile == null ? 'Carica Immagine' : 'Cambia Immagine',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
            
            if (_imageFile != null)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _diagnoseImage,
                  icon: const Icon(Icons.search, size: 24),
                  label: const Text(
                    'Analizza',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
            
            const SizedBox(height: 32),
            
            // Results
            if (_isAnalyzing)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
              )
            else if (_diagnosticResult != null)
              _buildDiagnosticResult(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagnosticResult() {
    final result = _diagnosticResult!;
    final topExercise = result['top_exercise'] ?? '';
    final topConfidence = (result['top_confidence'] ?? 0.0) * 100;
    final allPredictions = Map<String, dynamic>.from(result['all_predictions'] ?? {});
    final angles = Map<String, dynamic>.from(result['angles'] ?? {});
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Prediction
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '🏆 Rilevamento Principale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                topExercise,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${topConfidence.toStringAsFixed(1)}% di confidenza',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // All Predictions
        const Text(
          'Tutte le Probabilità:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        
        ...allPredictions.entries.take(5).map((entry) {
          final exercise = entry.key;
          final probability = (entry.value as double) * 100;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${probability.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: probability > 50 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 24),
        
        // Angles
        const Text(
          'Angoli Rilevati:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: angles.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${(entry.value as double).toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}