import 'package:flutter/material.dart';
import 'PTAIWorkoutScreen.dart';
import 'PTAIVideoAnalysisScreen.dart';

/// Schermata di selezione esercizio per PT AI
class PTAIExerciseSelector extends StatefulWidget {
  const PTAIExerciseSelector({Key? key}) : super(key: key);

  @override
  State<PTAIExerciseSelector> createState() => _PTAIExerciseSelectorState();
}

class _PTAIExerciseSelectorState extends State<PTAIExerciseSelector> {
  // ✅ ESERCIZI SUPPORTATI DAL MODELLO (CORRETTI)
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Jumping Jacks',
      'icon': Icons.directions_run,
      'color': const Color(0xFF4CAF50),
      'defaultReps': 20,
      'description': 'Salti con apertura gambe',
    },
    {
      'name': 'Pull ups',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF2196F3),
      'defaultReps': 10,
      'description': 'Trazioni alla sbarra',
    },
    {
      'name': 'Push Ups',
      'icon': Icons.airline_seat_flat,
      'color': const Color(0xFF9C27B0),
      'defaultReps': 15,
      'description': 'Piegamenti sulle braccia',
    },
    {
      'name': 'Russian twists',
      'icon': Icons.refresh,
      'color': const Color(0xFFFF9800),
      'defaultReps': 25,
      'description': 'Torsioni russe addominali',
    },
    {
      'name': 'Squats',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFFE91E63),
      'defaultReps': 20,
      'description': 'Piegamenti sulle gambe',
    },
  ];

  String _selectedExercise = 'Squats';
  int _targetReps = 20;
  String _selectedMode = 'live'; // 'live' o 'video'

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
          'PT AI Workout',
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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Allena con l\'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scegli modalità: tempo reale o analisi video',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 🆕 SELEZIONE MODALITÀ
            const Text(
              'Modalità Allenamento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    'live',
                    'Tempo Reale',
                    'Feedback istantaneo durante l\'esercizio',
                    Icons.videocam,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    'video',
                    'Analisi Video',
                    'Carica un video e ricevi feedback dettagliato',
                    Icons.video_library,
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Selezione Esercizio
            const Text(
              'Seleziona Esercizio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            ...(_exercises.map((exercise) {
              final isSelected = _selectedExercise == exercise['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedExercise = exercise['name'];
                    _targetReps = exercise['defaultReps'];
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (exercise['color'] as Color).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? exercise['color'] as Color
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (exercise['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          exercise['icon'] as IconData,
                          color: exercise['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            Text(
                              exercise['description'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: exercise['color'] as Color,
                          size: 28,
                        ),
                    ],
                  ),
                ),
              );
            }).toList()),
            
            const SizedBox(height: 32),
            
            // Target Ripetizioni (solo per modalità live)
            if (_selectedMode == 'live') ...[
              const Text(
                'Ripetizioni Target',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_targetReps > 5) {
                        setState(() => _targetReps--);
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove, color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_targetReps',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  IconButton(
                    onPressed: () {
                      if (_targetReps < 50) {
                        setState(() => _targetReps++);
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
            ] else ...[
              const SizedBox(height: 32),
            ],
            
            // Pulsante Start
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedMode == 'live') {
                    // Modalità tempo reale (esistente)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PTAIWorkoutScreen(
                          exerciseName: _selectedExercise,
                          targetReps: _targetReps,
                        ),
                      ),
                    );
                  } else {
                    // 🆕 Modalità analisi video
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PTAIVideoAnalysisScreen(
                          exerciseName: _selectedExercise,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMode == 'live' 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: (_selectedMode == 'live' 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2196F3)).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedMode == 'live' 
                          ? Icons.play_arrow_rounded 
                          : Icons.upload_rounded,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedMode == 'live' 
                          ? 'Inizia Allenamento'
                          : 'Carica Video',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedMode == 'live'
                          ? 'L\'AI rileverà automaticamente i tuoi movimenti e conterà le ripetizioni in tempo reale'
                          : 'Carica un video del tuo allenamento e ricevi feedback dettagliato sulla tua forma',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF2196F3).withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModeCard(
    String mode,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : const Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}