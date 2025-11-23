"""
PT AI Server - API per rilevamento esercizi in tempo reale
Integrazione con FitBot AI
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import pickle
import cv2
import mediapipe as mp
import base64
from tensorflow.keras.models import model_from_json
import json
from collections import deque
import time

app = Flask(__name__)
CORS(app)

# ============================================
# CONFIGURAZIONE MODELLO
# ============================================

class PTAIModel:
    def __init__(self):
        self.model = None
        self.scaler = None
        self.label_encoder = None
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            smooth_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # Buffer per smooth predictions
        self.prediction_buffer = deque(maxlen=5)
        
        # Contatori per ripetizioni
        self.rep_counters = {}
        self.rep_states = {}
        
        self.load_model()
    
    def load_model(self):   # <---- QUI: 4 SPAZI ESATTI, NON 6
        """Carica il modello addestrato"""
        try:
            import os
            base_dir = os.path.dirname(os.path.abspath(__file__))

            # Carica architettura
            arch_path = os.path.join(base_dir, 'pt_ai_nn_model_architecture.json')
            with open(arch_path, 'r') as f:
                model_json = f.read()
            self.model = model_from_json(model_json)

            # Carica pesi
            weights_path = os.path.join(base_dir, 'pt_ai_nn_model.weights.h5')
            self.model.load_weights(weights_path)

            # Carica preprocessing info
            prep_path = os.path.join(base_dir, 'pt_ai_nn_model_preprocessing.pkl')
            with open(prep_path, 'rb') as f:
                preprocessing = pickle.load(f)
                self.scaler = preprocessing['scaler']
                self.label_encoder = preprocessing['label_encoder']
                self.numeric_columns = preprocessing['numeric_columns']
                self.categorical_columns = preprocessing['categorical_columns']

            print("✅ Modello PT AI caricato con successo!")
            return True

        except Exception as e:
            print(f"❌ Errore caricamento modello: {e}")
            return False

    
    def extract_angles_from_frame(self, frame_base64):
        """Estrae gli angoli dalle landmarks usando MediaPipe"""
        try:
            # Decodifica immagine base64
            img_data = base64.b64decode(frame_base64.split(',')[1] if ',' in frame_base64 else frame_base64)
            nparr = np.frombuffer(img_data, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Converti in RGB per MediaPipe
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Processa con MediaPipe
            results = self.pose.process(frame_rgb)
            
            if not results.pose_landmarks:
                return None, None
            
            landmarks = results.pose_landmarks.landmark
            
            # Estrai angoli (esempio per squat/push-up)
            angles = self.calculate_all_angles(landmarks)
            
            return angles, landmarks
            
        except Exception as e:
            print(f"Errore estrazione angoli: {e}")
            return None, None
    
    def calculate_all_angles(self, landmarks):
        """Calcola tutti gli angoli necessari"""
        def get_angle(a, b, c):
            """Calcola angolo tra 3 punti"""
            radians = np.arctan2(c.y - b.y, c.x - b.x) - \
                     np.arctan2(a.y - b.y, a.x - b.x)
            angle = np.abs(radians * 180.0 / np.pi)
            if angle > 180.0:
                angle = 360 - angle
            return angle
        
        try:
            angles = {
                # Braccia
                'left_elbow': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_ELBOW.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_WRIST.value]
                ),
                'right_elbow': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_ELBOW.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_WRIST.value]
                ),
                
                # Gambe
                'left_knee': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.LEFT_HIP.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_KNEE.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_ANKLE.value]
                ),
                'right_knee': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_KNEE.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_ANKLE.value]
                ),
                
                # Spalle
                'left_shoulder': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.LEFT_ELBOW.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_HIP.value]
                ),
                'right_shoulder': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_ELBOW.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP.value]
                ),
                
                # Anche
                'left_hip': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_HIP.value],
                    landmarks[self.mp_pose.PoseLandmark.LEFT_KNEE.value]
                ),
                'right_hip': get_angle(
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP.value],
                    landmarks[self.mp_pose.PoseLandmark.RIGHT_KNEE.value]
                ),
            }
            
            return angles
            
        except Exception as e:
            print(f"Errore calcolo angoli: {e}")
            return None
    
    def predict_exercise(self, angles, side='Center'):
        """Predice l'esercizio dai dati degli angoli"""
        try:
            if not angles:
                return None, 0.0
            
            # Prepara input per il modello
            input_data = []
            for col in self.numeric_columns:
                angle_name = col.lower().replace('_', ' ')
                # Mappa i nomi delle colonne agli angoli
                if 'elbow' in angle_name:
                    if 'left' in angle_name:
                        input_data.append(angles.get('left_elbow', 0))
                    else:
                        input_data.append(angles.get('right_elbow', 0))
                elif 'knee' in angle_name:
                    if 'left' in angle_name:
                        input_data.append(angles.get('left_knee', 0))
                    else:
                        input_data.append(angles.get('right_knee', 0))
                elif 'shoulder' in angle_name:
                    if 'left' in angle_name:
                        input_data.append(angles.get('left_shoulder', 0))
                    else:
                        input_data.append(angles.get('right_shoulder', 0))
                elif 'hip' in angle_name:
                    if 'left' in angle_name:
                        input_data.append(angles.get('left_hip', 0))
                    else:
                        input_data.append(angles.get('right_hip', 0))
                else:
                    input_data.append(0)
            
            # Normalizza
            input_scaled = self.scaler.transform([input_data])
            
            # Aggiungi categorical features (se presenti)
            categorical_encoded = np.zeros(len(self.categorical_columns))
            input_final = np.hstack([input_scaled, categorical_encoded.reshape(1, -1)])
            
            # Predizione
            prediction = self.model.predict(input_final, verbose=0)
            predicted_class = np.argmax(prediction[0])
            confidence = float(prediction[0][predicted_class])
            
            # Smooth prediction con buffer
            self.prediction_buffer.append((predicted_class, confidence))
            
            # Voto maggioranza
            if len(self.prediction_buffer) >= 3:
                classes = [p[0] for p in self.prediction_buffer]
                most_common = max(set(classes), key=classes.count)
                avg_confidence = np.mean([p[1] for p in self.prediction_buffer if p[0] == most_common])
                
                exercise_name = self.label_encoder.inverse_transform([most_common])[0]
                return exercise_name, float(avg_confidence)
            
            exercise_name = self.label_encoder.inverse_transform([predicted_class])[0]
            return exercise_name, confidence
            
        except Exception as e:
            print(f"Errore predizione: {e}")
            return None, 0.0
    
    def count_reps(self, exercise_name, angles):
        """Conta le ripetizioni basandosi sugli angoli"""
        try:
            if exercise_name not in self.rep_counters:
                self.rep_counters[exercise_name] = 0
                self.rep_states[exercise_name] = 'up'
            
            # Logica conteggio per diversi esercizi
            if 'squat' in exercise_name.lower():
                return self._count_squat_reps(exercise_name, angles)
            elif 'push' in exercise_name.lower() or 'piegamento' in exercise_name.lower():
                return self._count_pushup_reps(exercise_name, angles)
            elif 'curl' in exercise_name.lower():
                return self._count_curl_reps(exercise_name, angles)
            else:
                # Generico basato su angolo medio
                return self._count_generic_reps(exercise_name, angles)
                
        except Exception as e:
            print(f"Errore conteggio reps: {e}")
            return self.rep_counters.get(exercise_name, 0)
    
    def _count_squat_reps(self, exercise_name, angles):
        """Conta ripetizioni squat"""
        avg_knee = (angles.get('left_knee', 180) + angles.get('right_knee', 180)) / 2
        
        if avg_knee < 100 and self.rep_states[exercise_name] == 'up':
            self.rep_states[exercise_name] = 'down'
        elif avg_knee > 160 and self.rep_states[exercise_name] == 'down':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'up'
        
        return self.rep_counters[exercise_name]
    
    def _count_pushup_reps(self, exercise_name, angles):
        """Conta ripetizioni push-up"""
        avg_elbow = (angles.get('left_elbow', 180) + angles.get('right_elbow', 180)) / 2
        
        if avg_elbow < 90 and self.rep_states[exercise_name] == 'up':
            self.rep_states[exercise_name] = 'down'
        elif avg_elbow > 160 and self.rep_states[exercise_name] == 'down':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'up'
        
        return self.rep_counters[exercise_name]
    
    def _count_curl_reps(self, exercise_name, angles):
        """Conta ripetizioni curl"""
        avg_elbow = (angles.get('left_elbow', 180) + angles.get('right_elbow', 180)) / 2
        
        if avg_elbow < 50 and self.rep_states[exercise_name] == 'down':
            self.rep_states[exercise_name] = 'up'
        elif avg_elbow > 160 and self.rep_states[exercise_name] == 'up':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'down'
        
        return self.rep_counters[exercise_name]
    
    def _count_generic_reps(self, exercise_name, angles):
        """Conteggio generico basato su variazione angoli"""
        avg_angle = np.mean(list(angles.values()))
        
        if avg_angle < 100 and self.rep_states[exercise_name] == 'up':
            self.rep_states[exercise_name] = 'down'
        elif avg_angle > 140 and self.rep_states[exercise_name] == 'down':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'up'
        
        return self.rep_counters[exercise_name]
    
    def evaluate_form(self, exercise_name, angles):
        """Valuta la forma dell'esercizio"""
        try:
            feedback = []
            score = 100
            
            if 'squat' in exercise_name.lower():
                # Valuta simmetria ginocchia
                knee_diff = abs(angles.get('left_knee', 0) - angles.get('right_knee', 0))
                if knee_diff > 15:
                    feedback.append("⚠️ Mantieni le ginocchia allineate")
                    score -= 15
                
                # Valuta profondità
                avg_knee = (angles.get('left_knee', 180) + angles.get('right_knee', 180)) / 2
                if avg_knee > 120:
                    feedback.append("💡 Prova a scendere più in basso")
                    score -= 10
                
            elif 'push' in exercise_name.lower():
                # Valuta allineamento corpo
                avg_hip = (angles.get('left_hip', 180) + angles.get('right_hip', 180)) / 2
                if avg_hip < 160:
                    feedback.append("⚠️ Mantieni il corpo dritto")
                    score -= 20
                
                # Valuta simmetria braccia
                elbow_diff = abs(angles.get('left_elbow', 0) - angles.get('right_elbow', 0))
                if elbow_diff > 20:
                    feedback.append("⚠️ Mantieni le braccia simmetriche")
                    score -= 15
            
            if score >= 85:
                feedback.insert(0, "✅ Ottima forma!")
            elif score >= 70:
                feedback.insert(0, "👍 Buona forma")
            else:
                feedback.insert(0, "⚠️ Forma da migliorare")
            
            return {
                'score': max(0, score),
                'feedback': feedback
            }
            
        except Exception as e:
            print(f"Errore valutazione forma: {e}")
            return {'score': 50, 'feedback': ['Errore valutazione']}
    
    def reset_counters(self, exercise_name=None):
        """Reset contatori ripetizioni"""
        if exercise_name:
            self.rep_counters[exercise_name] = 0
            self.rep_states[exercise_name] = 'up'
        else:
            self.rep_counters = {}
            self.rep_states = {}


# ============================================
# INIZIALIZZAZIONE GLOBALE
# ============================================

pt_ai_model = PTAIModel()


# ============================================
# API ENDPOINTS
# ============================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': pt_ai_model.model is not None,
        'timestamp': time.time()
    })


@app.route('/api/pt-ai/analyze-frame', methods=['POST'])
def analyze_frame():
    """
    Analizza un singolo frame e ritorna:
    - Esercizio rilevato
    - Confidence
    - Conteggio ripetizioni
    - Valutazione forma
    """
    try:
        data = request.json
        frame_base64 = data.get('frame')
        
        if not frame_base64:
            return jsonify({'error': 'Frame mancante'}), 400
        
        # Estrai angoli
        angles, landmarks = pt_ai_model.extract_angles_from_frame(frame_base64)
        
        if not angles:
            return jsonify({
                'success': False,
                'error': 'Nessuna persona rilevata nel frame'
            }), 200
        
        # Predici esercizio
        exercise_name, confidence = pt_ai_model.predict_exercise(angles)
        
        if not exercise_name or confidence < 0.5:
            return jsonify({
                'success': False,
                'error': 'Esercizio non riconosciuto con sufficiente confidenza'
            }), 200
        
        # Conta ripetizioni
        reps = pt_ai_model.count_reps(exercise_name, angles)
        
        # Valuta forma
        form_evaluation = pt_ai_model.evaluate_form(exercise_name, angles)
        
        return jsonify({
            'success': True,
            'exercise': exercise_name,
            'confidence': confidence,
            'reps': reps,
            'form_score': form_evaluation['score'],
            'feedback': form_evaluation['feedback'],
            'angles': angles,
            'timestamp': time.time()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/pt-ai/reset-reps', methods=['POST'])
def reset_reps():
    """Reset contatore ripetizioni"""
    try:
        data = request.json
        exercise_name = data.get('exercise')
        
        pt_ai_model.reset_counters(exercise_name)
        
        return jsonify({
            'success': True,
            'message': f'Contatore reset per {exercise_name if exercise_name else "tutti gli esercizi"}'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/pt-ai/supported-exercises', methods=['GET'])
def supported_exercises():
    """Lista esercizi supportati dal modello"""
    try:
        if pt_ai_model.label_encoder:
            exercises = pt_ai_model.label_encoder.classes_.tolist()
            return jsonify({
                'success': True,
                'exercises': exercises,
                'count': len(exercises)
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Modello non caricato'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================
# AVVIO SERVER
# ============================================

if __name__ == '__main__':
    print("🚀 Avvio PT AI Server...")
    print("📡 Server in ascolto su http://0.0.0.0:5000")
    print("💪 Modello PT AI pronto!")
    
    app.run(host='0.0.0.0', port=5000, debug=True)