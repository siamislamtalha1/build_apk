import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const GoogleSignInTestApp());
}

class GoogleSignInTestApp extends StatelessWidget {
  const GoogleSignInTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GoogleSignInTestScreen(),
    );
  }
}

class GoogleSignInTestScreen extends StatefulWidget {
  const GoogleSignInTestScreen({super.key});

  @override
  State<GoogleSignInTestScreen> createState() => _GoogleSignInTestScreenState();
}

class _GoogleSignInTestScreenState extends State<GoogleSignInTestScreen> {
  final _authService = AuthService();
  final _auth = FirebaseAuth.instance;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Firebase user: ${user == null ? "<null>" : user.uid}'),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? "<null>"}'),
            const SizedBox(height: 8),
            Text('Anonymous: ${user?.isAnonymous ?? false}'),
            const SizedBox(height: 8),
            Text('Providers: ${user?.providerData.map((p) => p.providerId).join(", ") ?? "<null>"}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _run(() async {
                  await _authService.signInWithGoogle();
                }),
                child: const Text('Sign in with Google'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _run(() async {
                  await _authService.signInAsGuest();
                }),
                child: const Text('Sign in anonymously (guest)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _run(() async {
                  await _authService.signOut();
                }),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
