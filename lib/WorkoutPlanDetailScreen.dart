import 'package:flutter/material.dart';
import 'WorkoutPlanDao.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  
  const WorkoutPlanDetailScreen({
    super.key,
    required this.workoutPlan,
  });

  @override
  _WorkoutPlanDetailScreenState createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.workoutPlan.titolo,
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanHeader(),
              SizedBox(height: 24),
              _buildPlanInfo(),
              SizedBox(height: 24),
              _buildDaySelector(),
              SizedBox(height: 16),
              _buildExercisesList(),
              SizedBox(height: 24),
              if (widget.workoutPlan.consigli.isNotEmpty) _buildAdviceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE85A30), Color(0xFFFF6B35)],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.workoutPlan.isActive ? Icons.check_circle : Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                widget.workoutPlan.isActive ? 'Piano Attivo' : 'Piano Salvato',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            widget.workoutPlan.titolo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.workoutPlan.obiettivo,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informazioni del Piano',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: 'Durata',
                  value: '${widget.workoutPlan.duratSettimane} settimane',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.fitness_center,
                  title: 'Frequenza',
                  value: widget.workoutPlan.frequenza,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person,
                  title: 'Età',
                  value: '${widget.workoutPlan.eta} anni',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.school,
                  title: 'Esperienza',
                  value: widget.workoutPlan.experience,
                ),
              ),
            ],
          ),
          if (widget.workoutPlan.additionalNotes != null && widget.workoutPlan.additionalNotes!.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note aggiuntive:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.workoutPlan.additionalNotes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          Text(
            'Creato: ${_formatDate(widget.workoutPlan.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFFE85A30), size: 24),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona il giorno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.workoutPlan.giorni.asMap().entries.map((entry) {
                int index = entry.key;
                WorkoutDay day = entry.value;
                bool isSelected = _selectedDayIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFE85A30) : Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Color(0xFFE85A30) : Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day.giorno,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Color(0xFF2C2C2C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          day.focus,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white.withOpacity(0.8) : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_selectedDayIndex >= widget.workoutPlan.giorni.length) {
      return Container();
    }

    final selectedDay = widget.workoutPlan.giorni[_selectedDayIndex];
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Color(0xFFE85A30), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDay.giorno,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      selectedDay.focus,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...selectedDay.esercizi.asMap().entries.map((entry) {
            int index = entry.key;
            Exercise exercise = entry.value;
            return _buildExerciseCard(exercise, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int number) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
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
                  color: Color(0xFFE85A30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildExerciseDetail(Icons.repeat, 'Serie', '${exercise.serie}'),
              SizedBox(width: 20),
              _buildExerciseDetail(Icons.fitness_center, 'Reps', exercise.ripetizioni),
              SizedBox(width: 20),
              _buildExerciseDetail(Icons.timer, 'Riposo', '${exercise.riposoSec}s'),
            ],
          ),
          if (exercise.note != null && exercise.note!.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.note!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF666666), size: 16),
        SizedBox(width: 4),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceSection() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
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
                color: Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tips_and_updates,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Consigli per il successo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...widget.workoutPlan.consigli.map<Widget>((consiglio) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      consiglio,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C2C2C),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ),
  );
}

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}