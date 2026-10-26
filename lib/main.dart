import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MessApp());
}

class MessApp extends StatelessWidget {
  const MessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        fontFamily: 'NotoSansBengali',
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// A dedicated Wrapper to handle both Authentication and Authorization states
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
        }
        
        // If user is NOT logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // If user IS logged in, we must check if they are authorized in Firestore
        // FutureBuilder handles the async check
        return FutureBuilder<bool>(
          future: _authService.isCurrentUserAuthorized(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
            }
            
            bool isAuthorized = authSnapshot.data ?? false;
            
            if (isAuthorized) {
              return const MainLayout();
            } else {
              // User is logged in to Google but not authorized in our database
              // We should force sign out so they return to LoginScreen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _authService.signOut();
              });
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
            }
          },
        );
      },
    );
  }
}
