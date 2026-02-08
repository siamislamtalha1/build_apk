import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:Bloomee/services/firebase/firestore_service.dart';

/// Sign-up screen for email/password registration
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _didSubmit = false;

  Timer? _usernameDebounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameError;

  String _normalizedUsername(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    return v.startsWith('@') ? v.substring(1) : v;
  }

  Future<void> _checkUsernameAvailability(String raw) async {
    final v = _normalizedUsername(raw);
    if (v.isEmpty) {
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    final re = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!re.hasMatch(v)) {
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = false;
        _usernameError = 'Username must be 3-20 chars (letters, numbers, _)';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    try {
      final fs = FirestoreService();
      final uid = await fs.getUserIdByUsername(v);
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = uid == null;
        _usernameError = uid == null ? null : 'Username already taken';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
        _usernameError = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      _usernameDebounce?.cancel();
      _usernameDebounce = Timer(const Duration(milliseconds: 350), () {
        _checkUsernameAvailability(_usernameController.text);
      });
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_didSubmit) return; // Prevent double submission
    if (_formKey.currentState!.validate()) {
      if (_checkingUsername) return;
      if (_usernameError != null) return;
      _didSubmit = true;
      context.read<AuthCubit>().signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            desiredUsername: _usernameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(MingCute.arrow_left_line),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _didSubmit = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Unauthenticated) {
            _didSubmit = false;
          } else if (state is Authenticated) {
            if (_didSubmit) {
              _didSubmit = false;
              final from =
                  GoRouterState.of(context).uri.queryParameters['from'];
              final target = from == 'profile' ? '/Profile' : '/Explore';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.go(target);
              });
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Create Account',
                      style: Default_Theme.primaryTextStyle.merge(
                        TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Default_Theme.primaryColor1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: Default_Theme.secondoryTextStyle.merge(
                        TextStyle(
                          fontSize: 16,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Sign-up Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              hintText: 'Enter your name',
                              prefixIcon: const Icon(MingCute.user_3_line),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.05),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: '@yourname',
                              prefixIcon: const Icon(MingCute.at_line),
                              suffixIcon: _checkingUsername
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (_usernameAvailable == null
                                      ? null
                                      : Icon(
                                          _usernameAvailable == true
                                              ? MingCute.check_circle_line
                                              : MingCute.close_circle_line,
                                          color: _usernameAvailable == true
                                              ? Colors.green
                                              : Colors.red,
                                        )),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.05),
                              errorText: _usernameError,
                            ),
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) {
                                return null; // optional (random username will be assigned)
                              }
                              final raw =
                                  v.startsWith('@') ? v.substring(1) : v;
                              final re = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
                              if (!re.hasMatch(raw)) {
                                return 'Username must be 3-20 chars (letters, numbers, _)';
                              }
                              if (_usernameError != null) {
                                return _usernameError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(MingCute.mail_line),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.05),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            enabled: !isLoading,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(MingCute.lock_line),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? MingCute.eye_close_line
                                      : MingCute.eye_line,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.05),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !isLoading,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(MingCute.lock_line),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? MingCute.eye_close_line
                                      : MingCute.eye_line,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.05),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Default_Theme.accentColor2,
                                foregroundColor: scheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: scheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Default_Theme.secondoryTextStyle.merge(
                            TextStyle(
                              color: Default_Theme.primaryColor2,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.pop();
                                },
                          child: Text(
                            'Sign In',
                            style: Default_Theme.secondoryTextStyle.merge(
                              TextStyle(
                                color: Default_Theme.accentColor2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
