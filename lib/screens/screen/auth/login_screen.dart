import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';

/// Login screen with email/password, Google Sign-In, and guest mode
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _didSubmit = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signInWithEmail() {
    if (_formKey.currentState!.validate()) {
      _didSubmit = true;
      context.read<AuthCubit>().signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _signInAsGuest() {
    _didSubmit = true;
    context.read<AuthCubit>().signInAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Authenticated) {
            if (_didSubmit) {
              _didSubmit = false;
              final from = GoRouterState.of(context).uri.queryParameters['from'];
              final target = from == 'profile' ? '/Profile' : '/Explore';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(target);
                }
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
                    // App Logo
                    Image.asset(
                      'assets/icons/BloomeeLogoFG.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),

                    // Welcome Text
                    Text(
                      'Welcome to Musicly',
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
                      'Your music, everywhere',
                      style: Default_Theme.secondoryTextStyle.merge(
                        TextStyle(
                          fontSize: 16,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email/Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
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
                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _signInWithEmail,
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
                                      'Sign In',
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

                    const SizedBox(height: 16),

                    // Forgot Password
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final from = GoRouterState.of(context)
                                  .uri
                                  .queryParameters['from'];
                              context.push(
                                from == null
                                    ? '/ForgotPassword'
                                    : '/ForgotPassword?from=$from',
                              );
                            },
                      child: Text(
                        'Forgot Password?',
                        style: Default_Theme.secondoryTextStyle.merge(
                          TextStyle(
                            color: Default_Theme.accentColor2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Default_Theme.secondoryTextStyle.merge(
                              TextStyle(
                                color: Default_Theme.primaryColor2,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Guest Mode Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInAsGuest,
                        icon: const Icon(MingCute.user_3_line, size: 20),
                        label: const Text('Continue as Guest'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Default_Theme.primaryColor2,
                          side: BorderSide(
                            color: Default_Theme.primaryColor2
                                .withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
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
                                  final from = GoRouterState.of(context)
                                      .uri
                                      .queryParameters['from'];
                                  context.push(
                                    from == null
                                        ? '/Signup'
                                        : '/Signup?from=$from',
                                  );
                                },
                          child: Text(
                            'Sign Up',
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
