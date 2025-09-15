import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth_dao.dart';

// Importa il DAO che abbiamo creato
// import 'firebase_auth_dao.dart'; // Assicurati di salvare il DAO in questo file

class AuthContext extends ChangeNotifier {
  final FirebaseAuthDAO _authDAO = FirebaseAuthDAO();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthContext() {
    // Verifica iniziale dello stato Firebase
    _checkFirebaseStatus();
    
    // Ascolta i cambiamenti dello stato di autenticazione
    _authDAO.authStateChanges.listen((User? user) {
      print('Auth state changed: ${user?.email ?? "null"}');
      _user = user;
      notifyListeners();
    });
  }

  // Verifica stato Firebase
  void _checkFirebaseStatus() async {
    print('Verifica stato Firebase...');
    final debugInfo = _authDAO.getDebugInfo();
    print('Firebase Debug Info: $debugInfo');
    
    if (!_authDAO.isFirebaseInitialized) {
      _setError('Firebase non è inizializzato correttamente');
    } else {
      print('Firebase inizializzato correttamente');
      // Test connessione
      final connectionTest = await _authDAO.testFirebaseConnection();
      print('Test connessione Firebase: ${connectionTest ? "OK" : "FALLITO"}');
    }
  }

  // Metodo per il login con email e password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      print('Tentativo di login per: $email');
      
      final result = await _authDAO.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      
      if (result.success && result.user != null) {
        _user = result.user;
        print('Login riuscito per: ${result.user!.email}');
        return true;
      } else {
        print('Login fallito: ${result.error}');
        _setError(result.error ?? 'Errore durante il login');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      print('Errore imprevisto durante il login: $e');
      _setError('Errore imprevisto durante il login: ${e.toString()}');
      return false;
    }
  }

  // Metodo per la registrazione con email e password
  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      print('Tentativo di registrazione per: $email');
      
      final result = await _authDAO.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      
      if (result.success && result.user != null) {
        _user = result.user;
        print('Registrazione riuscita per: ${result.user!.email}');
        return true;
      } else {
        print('Registrazione fallita: ${result.error}');
        _setError(result.error ?? 'Errore durante la registrazione');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      print('Errore imprevisto durante la registrazione: $e');
      _setError('Errore imprevisto durante la registrazione: ${e.toString()}');
      return false;
    }
  }

  // Metodo per il logout
  Future<void> signOut() async {
    try {
      print('Tentativo di logout...');
      final result = await _authDAO.signOut();
      
      if (result.success) {
        _user = null;
        _clearError();
        print('Logout riuscito');
      } else {
        print('Logout fallito: ${result.error}');
        _setError(result.error ?? 'Errore durante il logout');
      }
    } catch (e) {
      print('Errore durante il logout: $e');
      _setError('Errore durante il logout: ${e.toString()}');
    }
  }

  // Metodo per il reset della password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      print('Tentativo di reset password per: $email');
      
      final result = await _authDAO.resetPassword(email: email);
      
      _setLoading(false);
      
      if (result.success) {
        print('Email di reset inviata con successo');
        return true;
      } else {
        print('Reset password fallito: ${result.error}');
        _setError(result.error ?? 'Errore durante il reset password');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      print('Errore durante il reset password: $e');
      _setError('Errore durante il reset password: ${e.toString()}');
      return false;
    }
  }

  // Metodi privati per gestire lo stato
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Metodo per pulire gli errori manualmente
  void clearError() {
    _clearError();
  }

  // Metodo per verificare se l'email è verificata
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Metodo per inviare email di verifica
  Future<bool> sendEmailVerification() async {
    try {
      print('Tentativo di invio email di verifica...');
      final result = await _authDAO.sendEmailVerification();
      
      if (result.success) {
        print('Email di verifica inviata');
        return true;
      } else {
        print('Invio email verifica fallito: ${result.error}');
        _setError(result.error ?? 'Errore durante l\'invio dell\'email di verifica');
        return false;
      }
    } catch (e) {
      print('Errore durante l\'invio email verifica: $e');
      _setError('Errore durante l\'invio dell\'email di verifica: ${e.toString()}');
      return false;
    }
  }

  // Metodo per aggiornare il profilo utente
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      print('Tentativo di aggiornamento profilo...');
      final result = await _authDAO.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      if (result.success && result.user != null) {
        _user = result.user;
        notifyListeners();
        print('Profilo aggiornato con successo');
        return true;
      } else {
        print('Aggiornamento profilo fallito: ${result.error}');
        _setError(result.error ?? 'Errore durante l\'aggiornamento del profilo');
        return false;
      }
    } catch (e) {
      print('Errore durante l\'aggiornamento profilo: $e');
      _setError('Errore durante l\'aggiornamento del profilo: ${e.toString()}');
      return false;
    }
  }

  // Metodo per ottenere il nome utente da visualizzare
  String get displayName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    } else if (_user?.email != null) {
      return _user!.email!.split('@')[0];
    }
    return 'Utente';
  }

  // Metodo per ottenere le iniziali dell'utente
  String get userInitials {
    final name = displayName;
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  // Metodo di debug
  void debugFirebaseStatus() {
    print('=== DEBUG FIREBASE STATUS ===');
    print('User: ${_user?.email ?? "null"}');
    print('Loading: $_isLoading');
    print('Error: $_errorMessage');
    print('DAO Debug Info: ${_authDAO.getDebugInfo()}');
    print('============================');
  }

  // Metodo per ricaricare l'utente corrente
  Future<void> reloadUser() async {
    try {
      final currentUser = _authDAO.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = _authDAO.currentUser;
        notifyListeners();
      }
    } catch (e) {
      print('Errore durante il reload dell\'utente: $e');
    }
  }
}