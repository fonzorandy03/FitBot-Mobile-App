import 'package:flutter/material.dart';
import 'PTAIWorkoutScreen.dart';

/// Schermata di selezione esercizio per PT AI
class PTAIExerciseSelector extends StatefulWidget {
  const PTAIExerciseSelector({Key? key}) : super(key: key);

  @override
  State<PTAIExerciseSelector> createState() => _PTAIExerciseSelectorState();
}

class _PTAIExerciseSelectorState extends State<PTAIExerciseSelector> {
  // Esercizi supportati dal modello
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Squat',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFF4CAF50),
      'defaultReps': 15,
      'description': 'Piegamenti sulle gambe',
    },
    {
      'name': 'Push-up',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF2196F3),
      'defaultReps': 12,
      'description': 'Piegamenti sulle braccia',
    },
    {
      'name': 'Curl',
      'icon': Icons.sports_gymnastics,
      'color': const Color(0xFF9C27B0),
      'defaultReps': 10,
      'description': 'Curl bicipiti',
    },
    {
      'name': 'Plank',
      'icon': Icons.airline_seat_flat,
      'color': const Color(0xFFFF9800),
      'defaultReps': 30,
      'description': 'Plank isometrico (secondi)',
    },
  ];

  String _selectedExercise = 'Squat';
  int _targetReps = 15;

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
                    Icons.videocam_rounded,
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
                    'Il tuo personal trainer virtuale ti guiderà in tempo reale',
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
            
            // Target Ripetizioni
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
            
            // Pulsante Start
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PTAIWorkoutScreen(
                        exerciseName: _selectedExercise,
                        targetReps: _targetReps,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Inizia Workout',
                      style: TextStyle(
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
                      'L\'AI rileverà automaticamente i tuoi movimenti e conterà le ripetizioni',
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
}

