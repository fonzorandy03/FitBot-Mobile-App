"""
PT AI Server - API per rilevamento esercizi in tempo reale
Integrazione con FitBot AI - CON VALIDAZIONE ESERCIZIO
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
from collections import deque, Counter
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
        
        self.prediction_buffer = deque(maxlen=5)
        self.rep_counters = {}
        self.rep_states = {}
        
        self.load_model()
    
    def load_model(self):
        """Carica il modello addestrato"""
        try:
            import os
            base_dir = os.path.dirname(os.path.abspath(__file__))

            arch_path = os.path.join(base_dir, 'pt_ai_nn_model_architecture.json')
            with open(arch_path, 'r') as f:
                model_json = f.read()
            self.model = model_from_json(model_json)

            weights_path = os.path.join(base_dir, 'pt_ai_nn_model.weights.h5')
            self.model.load_weights(weights_path)

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
            img_data = base64.b64decode(frame_base64.split(',')[1] if ',' in frame_base64 else frame_base64)
            nparr = np.frombuffer(img_data, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.pose.process(frame_rgb)
            
            if not results.pose_landmarks:
                return None, None
            
            landmarks = results.pose_landmarks.landmark
            angles = self.calculate_all_angles(landmarks)
            
            return angles, landmarks
            
        except Exception as e:
            print(f"Errore estrazione angoli: {e}")
            return None, None
    
    def calculate_all_angles(self, landmarks):
        """Calcola tutti gli angoli necessari"""
        def get_angle(a, b, c):
            radians = np.arctan2(c.y - b.y, c.x - b.x) - \
                     np.arctan2(a.y - b.y, a.x - b.x)
            angle = np.abs(radians * 180.0 / np.pi)
            if angle > 180.0:
                angle = 360 - angle
            return angle
        
        try:
            angles = {
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
            
            input_data = []
            for col in self.numeric_columns:
                angle_name = col.lower().replace('_', ' ')
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
            
            input_scaled = self.scaler.transform([input_data])
            categorical_encoded = np.zeros(len(self.categorical_columns))
            input_final = np.hstack([input_scaled, categorical_encoded.reshape(1, -1)])
            
            prediction = self.model.predict(input_final, verbose=0)
            predicted_class = np.argmax(prediction[0])
            confidence = float(prediction[0][predicted_class])
            
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
            
            if 'squat' in exercise_name.lower():
                return self._count_squat_reps(exercise_name, angles)
            elif 'push' in exercise_name.lower() or 'piegamento' in exercise_name.lower():
                return self._count_pushup_reps(exercise_name, angles)
            elif 'curl' in exercise_name.lower():
                return self._count_curl_reps(exercise_name, angles)
            elif 'jumping' in exercise_name.lower() or 'jack' in exercise_name.lower():
                return self._count_jumping_jack_reps(exercise_name, angles)
            else:
                return self._count_generic_reps(exercise_name, angles)
                
        except Exception as e:
            print(f"Errore conteggio reps: {e}")
            return self.rep_counters.get(exercise_name, 0)
    
    def _count_squat_reps(self, exercise_name, angles):
        avg_knee = (angles.get('left_knee', 180) + angles.get('right_knee', 180)) / 2
        
        if avg_knee < 100 and self.rep_states[exercise_name] == 'up':
            self.rep_states[exercise_name] = 'down'
        elif avg_knee > 160 and self.rep_states[exercise_name] == 'down':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'up'
        
        return self.rep_counters[exercise_name]
    
    def _count_pushup_reps(self, exercise_name, angles):
        avg_elbow = (angles.get('left_elbow', 180) + angles.get('right_elbow', 180)) / 2
        
        if avg_elbow < 90 and self.rep_states[exercise_name] == 'up':
            self.rep_states[exercise_name] = 'down'
        elif avg_elbow > 160 and self.rep_states[exercise_name] == 'down':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'up'
        
        return self.rep_counters[exercise_name]
    
    def _count_curl_reps(self, exercise_name, angles):
        avg_elbow = (angles.get('left_elbow', 180) + angles.get('right_elbow', 180)) / 2
        
        if avg_elbow < 50 and self.rep_states[exercise_name] == 'down':
            self.rep_states[exercise_name] = 'up'
        elif avg_elbow > 160 and self.rep_states[exercise_name] == 'up':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'down'
        
        return self.rep_counters[exercise_name]
    
    def _count_jumping_jack_reps(self, exercise_name, angles):
        """Conta ripetizioni jumping jack"""
        avg_shoulder = (angles.get('left_shoulder', 0) + angles.get('right_shoulder', 0)) / 2
        
        if exercise_name not in self.rep_states:
            self.rep_states[exercise_name] = 'closed'
        
        if avg_shoulder < 50 and self.rep_states[exercise_name] == 'closed':
            self.rep_states[exercise_name] = 'open'
            print(f"   🔄 Jumping Jack: Stato → OPEN (shoulder: {avg_shoulder:.1f}°)")
        elif avg_shoulder > 140 and self.rep_states[exercise_name] == 'open':
            self.rep_counters[exercise_name] += 1
            self.rep_states[exercise_name] = 'closed'
            print(f"   ✅ Jumping Jack: Rep #{self.rep_counters[exercise_name]} contata! (shoulder: {avg_shoulder:.1f}°)")
        
        return self.rep_counters[exercise_name]
    
    def _count_generic_reps(self, exercise_name, angles):
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
                knee_diff = abs(angles.get('left_knee', 0) - angles.get('right_knee', 0))
                if knee_diff > 15:
                    feedback.append("⚠️ Mantieni le ginocchia allineate")
                    score -= 15
                
                avg_knee = (angles.get('left_knee', 180) + angles.get('right_knee', 180)) / 2
                if avg_knee > 120:
                    feedback.append("💡 Prova a scendere più in basso")
                    score -= 10
                
            elif 'push' in exercise_name.lower():
                avg_hip = (angles.get('left_hip', 180) + angles.get('right_hip', 180)) / 2
                if avg_hip < 160:
                    feedback.append("⚠️ Mantieni il corpo dritto")
                    score -= 20
                
                elbow_diff = abs(angles.get('left_elbow', 0) - angles.get('right_elbow', 0))
                if elbow_diff > 20:
                    feedback.append("⚠️ Mantieni le braccia simmetriche")
                    score -= 15
            
            elif 'jumping' in exercise_name.lower() or 'jack' in exercise_name.lower():
                shoulder_diff = abs(angles.get('left_shoulder', 0) - angles.get('right_shoulder', 0))
                if shoulder_diff > 20:
                    feedback.append("⚠️ Mantieni le braccia simmetriche")
                    score -= 15
                
                avg_shoulder = (angles.get('left_shoulder', 0) + angles.get('right_shoulder', 0)) / 2
                if avg_shoulder > 60:
                    feedback.append("💡 Porta le braccia completamente sopra la testa")
                    score -= 10
            
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

@app.route('/api/pt-ai/analyze-video', methods=['POST'])
def analyze_video():
    """Analizza un video completo con VALIDAZIONE ESERCIZIO"""
    try:
        data = request.json
        frames = data.get('frames', [])
        expected_exercise = data.get('exercise', '')
        
        print(f"\n{'='*60}")
        print(f"📥 DATI RICEVUTI:")
        print(f"   Esercizio ricevuto (raw): '{expected_exercise}'")
        print(f"   Tipo: {type(expected_exercise)}")
        print(f"   Lunghezza: {len(expected_exercise) if expected_exercise else 0}")
        print(f"   Frame ricevuti: {len(frames)}")
        print(f"{'='*60}")
        
        if not frames:
            return jsonify({
                'success': False,
                'error': 'Nessun frame ricevuto'
            }), 400
        
        # Normalizza il nome
        expected_exercise_clean = expected_exercise.strip()
        
        print(f"\n{'='*60}")
        print(f"🎬 INIZIO ANALISI VIDEO")
        print(f"📝 Esercizio dichiarato: '{expected_exercise_clean}'")
        print(f"📸 Frame da analizzare: {len(frames)}")
        
        # Mostra tutti gli esercizi supportati
        supported = pt_ai_model.label_encoder.classes_.tolist()
        print(f"✅ Esercizi supportati dal modello:")
        for ex in supported:
            print(f"   - '{ex}'")
        print(f"{'='*60}\n")
        
        detected_exercises = []
        all_reps_per_exercise = {}
        all_form_scores = []
        all_feedback = []
        frames_with_person = 0
        
        pt_ai_model.reset_counters()
        
        for idx, frame_base64 in enumerate(frames):
            angles, landmarks = pt_ai_model.extract_angles_from_frame(frame_base64)
            
            if not angles:
                print(f"⚠️ Frame {idx}: Nessuna persona rilevata")
                continue
            
            frames_with_person += 1
            
            detected_exercise, confidence = pt_ai_model.predict_exercise(angles)
            
            if detected_exercise and confidence > 0.4:
                detected_exercises.append(detected_exercise)
                print(f"✅ Frame {idx}: {detected_exercise} (conf: {confidence:.2f})")
                
                reps = pt_ai_model.count_reps(detected_exercise, angles)
                
                if detected_exercise not in all_reps_per_exercise:
                    all_reps_per_exercise[detected_exercise] = []
                all_reps_per_exercise[detected_exercise].append(reps)
                
                form_eval = pt_ai_model.evaluate_form(detected_exercise, angles)
                all_form_scores.append(form_eval['score'])
                all_feedback.extend(form_eval['feedback'])
            else:
                print(f"⚠️ Frame {idx}: Esercizio non riconosciuto (conf: {confidence:.2f})")
        
        if not detected_exercises:
            return jsonify({
                'success': False,
                'error': 'Nessun esercizio rilevato nel video.',
                'frames_analyzed': len(frames),
                'frames_with_person': frames_with_person
            }), 200
        
        exercise_counter = Counter(detected_exercises)
        most_common_exercise, count = exercise_counter.most_common(1)[0]
        detection_rate = count / len(detected_exercises) * 100
        
        print(f"\n{'='*60}")
        print(f"📊 ANALISI RILEVAMENTI:")
        for exercise, cnt in exercise_counter.most_common():
            percentage = cnt / len(detected_exercises) * 100
            print(f"   {exercise}: {cnt} frame ({percentage:.1f}%)")
        print(f"{'='*60}\n")
        
        # Verifica corrispondenza
        exercise_match = False
        normalized_detected = most_common_exercise.lower().replace(' ', '').replace('-', '').replace('_', '')
        normalized_expected = expected_exercise_clean.lower().replace(' ', '').replace('-', '').replace('_', '')
        
        print(f"🔍 VERIFICA MATCH:")
        print(f"   Expected RAW: '{expected_exercise_clean}'")
        print(f"   Expected normalized: '{normalized_expected}'")
        print(f"   Detected RAW: '{most_common_exercise}'")
        print(f"   Detected normalized: '{normalized_detected}'")
        
        # Match esatto
        if normalized_expected == normalized_detected:
            exercise_match = True
            print(f"   ✅ MATCH ESATTO!")
        elif normalized_expected in normalized_detected:
            exercise_match = True
            print(f"   ✅ MATCH PARZIALE (expected dentro detected)!")
        elif normalized_detected in normalized_expected:
            exercise_match = True
            print(f"   ✅ MATCH PARZIALE (detected dentro expected)!")
        else:
            print(f"   ⚠️ Nessun match diretto, provo fuzzy matching...")
            
            exercise_aliases = {
                'jumpingjacks': ['jumpingjacks', 'jumpingjack', 'jack', 'jacks', 'jumpingjax'],
                'squats': ['squat', 'squats'],
                'pushups': ['pushup', 'pushups', 'piegamento', 'piegamenti'],
                'pullups': ['pullup', 'pullups', 'trazione', 'trazioni'],
                'russiantwists': ['russiantwist', 'russiantwists', 'twist', 'twists'],
            }
            
            for key, aliases in exercise_aliases.items():
                if normalized_expected in aliases and normalized_detected in aliases:
                    exercise_match = True
                    print(f"   ✅ FUZZY MATCH su gruppo '{key}'!")
                    break
            
            if not exercise_match:
                print(f"   ❌ NO MATCH TROVATO")
                print(f"   💡 Suggerimento: controlla che il nome sia esatto")
        
        total_reps = max(all_reps_per_exercise.get(most_common_exercise, [0]))
        avg_form_score = sum(all_form_scores) / len(all_form_scores) if all_form_scores else 0
        unique_feedback = list(set(all_feedback))
        
        response_data = {
            'success': True,
            'exercise_match': exercise_match,
            'is_supported': True,
            'expected_exercise': expected_exercise_clean,
            'detected_exercise': most_common_exercise,
            'detection_confidence': round(detection_rate, 1),
            'total_reps': total_reps if exercise_match else 0,
            'avg_form_score': round(avg_form_score) if exercise_match else 0,
            'feedback': [],
            'frames_analyzed': len(frames),
            'frames_with_person': frames_with_person,
            'timestamp': time.time()
        }
        
        if not exercise_match:
            response_data['feedback'] = [
                f"❌ Esercizio errato rilevato!",
                f"🎯 Atteso: {expected_exercise}",
                f"👁️ Rilevato: {most_common_exercise}",
                f"💡 Assicurati di eseguire l'esercizio corretto"
            ]
        else:
            if total_reps == 0:
                response_data['feedback'] = [
                    "⚠️ Nessuna ripetizione contata",
                    "💡 Assicurati di completare il movimento completo",
                    "📹 Verifica che il corpo sia interamente nel frame"
                ]
            else:
                response_data['feedback'] = unique_feedback[:5]
        
        print(f"\n{'='*60}")
        print(f"✅ ANALISI COMPLETATA")
        print(f"   Match esercizio: {'SÌ' if exercise_match else 'NO'}")
        print(f"   Ripetizioni: {total_reps}")
        print(f"   Forma media: {round(avg_form_score)}/100")
        print(f"{'='*60}\n")
        
        return jsonify(response_data)
        
    except Exception as e:
        print(f"❌ ERRORE ANALISI: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'model_loaded': pt_ai_model.model is not None,
        'timestamp': time.time()
    })


@app.route('/api/pt-ai/analyze-frame', methods=['POST'])
def analyze_frame():
    try:
        data = request.json
        frame_base64 = data.get('frame')
        
        if not frame_base64:
            return jsonify({'error': 'Frame mancante'}), 400
        
        angles, landmarks = pt_ai_model.extract_angles_from_frame(frame_base64)
        
        if not angles:
            return jsonify({
                'success': False,
                'error': 'Nessuna persona rilevata nel frame'
            }), 200
        
        exercise_name, confidence = pt_ai_model.predict_exercise(angles)
        
        if not exercise_name or confidence < 0.5:
            return jsonify({
                'success': False,
                'error': 'Esercizio non riconosciuto'
            }), 200
        
        reps = pt_ai_model.count_reps(exercise_name, angles)
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


@app.route('/api/pt-ai/debug-model', methods=['GET'])
def debug_model():
    try:
        if not pt_ai_model.label_encoder:
            return jsonify({
                'success': False,
                'error': 'Modello non caricato'
            }), 500
        
        classes = pt_ai_model.label_encoder.classes_.tolist()
        
        info = {
            'success': True,
            'model_loaded': pt_ai_model.model is not None,
            'total_exercises': len(classes),
            'exercises': classes,
            'exercises_lowercase': [ex.lower() for ex in classes],
            'exercises_normalized': [ex.lower().replace(' ', '').replace('-', '').replace('_', '') for ex in classes],
        }
        
        return jsonify(info)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/pt-ai/test-match', methods=['POST'])
def test_match():
    """
    🧪 TEST: Verifica se un nome esercizio matcha con il modello
    """
    try:
        data = request.json
        test_name = data.get('exercise', '')
        
        supported = pt_ai_model.label_encoder.classes_.tolist()
        normalized_test = test_name.lower().replace(' ', '').replace('-', '').replace('_', '')
        
        results = {
            'input': test_name,
            'normalized': normalized_test,
            'supported_exercises': supported,
            'matches': []
        }
        
        # Verifica match con ogni esercizio supportato
        for ex in supported:
            normalized_ex = ex.lower().replace(' ', '').replace('-', '').replace('_', '')
            
            match_type = None
            if normalized_test == normalized_ex:
                match_type = 'EXACT'
            elif normalized_test in normalized_ex:
                match_type = 'PARTIAL (input in model)'
            elif normalized_ex in normalized_test:
                match_type = 'PARTIAL (model in input)'
            
            if match_type:
                results['matches'].append({
                    'exercise': ex,
                    'match_type': match_type,
                    'normalized': normalized_ex
                })
        
        return jsonify(results)
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    print("🚀 Avvio PT AI Server...")
    print("📡 Server in ascolto su http://0.0.0.0:5000")
    print("💪 Modello PT AI pronto con validazione esercizi!")
    
    app.run(host='0.0.0.0', port=5000, debug=True)