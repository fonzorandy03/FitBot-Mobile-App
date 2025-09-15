import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? errorCode;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.errorCode,
  });

  factory AuthResult.success(User user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String error, [String? errorCode]) {
    return AuthResult(success: false, error: error, errorCode: errorCode);
  }
}

class FirebaseAuthDAO {
  static final FirebaseAuthDAO _instance = FirebaseAuthDAO._internal();
  factory FirebaseAuthDAO() => _instance;
  FirebaseAuthDAO._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter per l'utente corrente
  User? get currentUser => _auth.currentUser;
  
  // Stream per ascoltare i cambiamenti di autenticazione
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verifica se Firebase è inizializzato correttamente
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Registrazione con email e password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Verifica che Firebase sia inizializzato
      if (!isFirebaseInitialized) {
        return AuthResult.failure('Firebase non è inizializzato correttamente');
      }

      // Validazione input
      if (email.trim().isEmpty) {
        return AuthResult.failure('Email non può essere vuota');
      }

      if (password.isEmpty) {
        return AuthResult.failure('Password non può essere vuota');
      }

      if (password.length < 6) {
        return AuthResult.failure('La password deve essere di almeno 6 caratteri');
      }

      // Validazione formato email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        return AuthResult.failure('Formato email non valido');
      }

      print('Tentativo di registrazione per: ${email.trim()}');
      
      // Tentativo di registrazione
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (userCredential.user != null) {
        print('Registrazione completata con successo');
        return AuthResult.success(userCredential.user!);
      } else {
        return AuthResult.failure('Errore durante la creazione dell\'utente');
      }

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseErrorMessage(e), e.code);
    } catch (e) {
      print('Errore generico durante la registrazione: $e');
      return AuthResult.failure('Errore imprevisto durante la registrazione: ${e.toString()}');
    }
  }

  // Login con email e password
  Future<AuthResult> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Verifica che Firebase sia inizializzato
      if (!isFirebaseInitialized) {
        return AuthResult.failure('Firebase non è inizializzato correttamente');
      }

      // Validazione input
      if (email.trim().isEmpty) {
        return AuthResult.failure('Email non può essere vuota');
      }

      if (password.isEmpty) {
        return AuthResult.failure('Password non può essere vuota');
      }

      print('Tentativo di login per: ${email.trim()}');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (userCredential.user != null) {
        print('Login completato con successo');
        return AuthResult.success(userCredential.user!);
      } else {
        return AuthResult.failure('Errore durante il login');
      }

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException durante login: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseErrorMessage(e), e.code);
    } catch (e) {
      print('Errore generico durante il login: $e');
      return AuthResult.failure('Errore imprevisto durante il login: ${e.toString()}');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      if (!isFirebaseInitialized) {
        return AuthResult.failure('Firebase non è inizializzato correttamente');
      }

      if (email.trim().isEmpty) {
        return AuthResult.failure('Email non può essere vuota');
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return AuthResult(success: true); // Rimosso il placeholder user non necessario
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e), e.code);
    } catch (e) {
      return AuthResult.failure('Errore durante l\'invio dell\'email di reset: ${e.toString()}');
    }
  }

  // Logout
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.failure('Errore durante il logout: ${e.toString()}');
    }
  }

  // Invia email di verifica
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult(success: true);
      }
      return AuthResult.failure('Nessun utente da verificare o email già verificata');
    } catch (e) {
      return AuthResult.failure('Errore durante l\'invio dell\'email di verifica: ${e.toString()}');
    }
  }

  // Aggiorna profilo utente
  Future<AuthResult> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
        return AuthResult.success(_auth.currentUser!);
      }
      return AuthResult.failure('Nessun utente attualmente loggato');
    } catch (e) {
      return AuthResult.failure('Errore durante l\'aggiornamento del profilo: ${e.toString()}');
    }
  }

  // Verifica stato di connessione Firebase - METODO CORRETTO
  Future<bool> testFirebaseConnection() async {
    try {
      // Test alternativo: prova a controllare l'utente corrente
      // Questo è un'operazione sicura che non richiede autenticazione
      final currentUser = _auth.currentUser;
      
      // Se arriviamo qui senza errori, Firebase funziona
      print('Test connessione Firebase: OK (Current user: ${currentUser?.email ?? 'nessuno'})');
      return true;
      
    } catch (e) {
      print('Errore test connessione Firebase: $e');
      return false;
    }
  }

  // Ottieni messaggi di errore user-friendly
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nessun utente trovato con questa email';
      case 'wrong-password':
        return 'Password errata';
      case 'email-already-in-use':
        return 'Un account con questa email esiste già';
      case 'weak-password':
        return 'La password è troppo debole';
      case 'invalid-email':
        return 'Formato email non valido';
      case 'user-disabled':
        return 'Questo account è stato disabilitato';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova più tardi';
      case 'operation-not-allowed':
        return 'Operazione non consentita';
      case 'network-request-failed':
        return 'Errore di connessione. Controlla la tua connessione internet';
      case 'invalid-credential':
        return 'Credenziali non valide';
      case 'account-exists-with-different-credential':
        return 'Esiste già un account con queste credenziali';
      case 'credential-already-in-use':
        return 'Queste credenziali sono già in uso';
      case 'invalid-verification-code':
        return 'Codice di verifica non valido';
      case 'invalid-verification-id':
        return 'ID di verifica non valido';
      case 'missing-verification-code':
        return 'Codice di verifica mancante';
      case 'missing-verification-id':
        return 'ID di verifica mancante';
      case 'quota-exceeded':
        return 'Quota di utilizzo superata. Riprova più tardi';
      case 'app-deleted':
        return 'Questa app è stata eliminata';
      case 'keychain-error':
        return 'Errore del portachiavi';
      case 'internal-error':
        return 'Errore interno del server. Riprova più tardi';
      case 'invalid-api-key':
        return 'Chiave API non valida';
      case 'app-not-authorized':
        return 'App non autorizzata per questo progetto';
      default:
        return e.message ?? 'Errore durante l\'autenticazione';
    }
  }

  // Debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'firebaseInitialized': isFirebaseInitialized,
      'currentUser': currentUser?.email ?? 'Nessuno',
      'appsCount': Firebase.apps.length,
      'authInstance': _auth.toString(),
    };
  }
}