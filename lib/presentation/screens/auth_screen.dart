import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/habit/habit_bloc.dart';
import 'main_navigation_hub.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSignUp = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true; // 👁️ Parol ko'rinishini boshqarish

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final String tokenAccess = googleAuth.accessToken ?? '';
        final String tokenID = googleAuth.idToken ?? '';

        if (tokenAccess.isEmpty || tokenID.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Google tokenlarini olishda xatolik yuz berdi.';
          });
          return;
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: tokenAccess,
          idToken: tokenID,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null && mounted) {
          await _enterApp(isGuestMode: false);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tizimga kirish bekor qilindi.';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.message ?? 'Google autentifikatsiya xatoligi yuz berdi.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kutilmagan xatolik yuz berdi: $error';
      });
    }
  }

  void _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorMessage = '';
    });

    if (email.isEmpty || password.isEmpty) {
      setState(
          () => _errorMessage = 'Iltimas, barcha maydonlarni to\'ldiring!');
      return;
    }
    if (password.length < 6) {
      setState(() =>
          _errorMessage = 'Parol kamida 6 ta belgidan iborat bo\'lishi shart!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;
      await _enterApp(isGuestMode: false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Xatolik yuz berdi.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tizimga kirishda xatolik yuz berdi.';
      });
    }
  }

  // 🛡️ OPTIMIZATSIYA QILINGAN: Parol tiklash mantiqi yuklanish holati bilan boyitildi
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage =
          'Parolni tiklash uchun avval email manzilingizni kiriting!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Avvalgi xatolikni tozalaymiz
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Parolni tiklash havolasi emailingizga yuborildi!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Xatolik yuz berdi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Xat yuborishda muammo yuz berdi.';
      });
    }
  }

  Future<void> _enterApp({required bool isGuestMode}) async {
    final prefs = await SharedPreferences.getInstance();

    if (isGuestMode) {
      await prefs.setBool('is_guest', true);
      await prefs.setBool('is_logged_in', false);
      await prefs.setString('last_uid', 'guest');
      await prefs.setString('current_user_id', 'guest');
    } else {
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);

      final String? currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        await prefs.setString('last_uid', currentUid);
        await prefs.setString('current_user_id', currentUid);

        if (_auth.currentUser?.displayName != null &&
            prefs.getString('USER_NAME_$currentUid') == null) {
          await prefs.setString(
              'USER_NAME_$currentUid', _auth.currentUser!.displayName!);
        }
        if (_auth.currentUser?.photoURL != null &&
            prefs.getString('USER_AVATAR_PATH_$currentUid') == null) {
          await prefs.setString(
              'USER_AVATAR_PATH_$currentUid', _auth.currentUser!.photoURL!);
        }
      }
    }
    await prefs.setBool('is_first_time', false);

    if (!mounted) return;

    context.read<HabitBloc>().add(LoadHabitsEvent());

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationHub()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.circleUser,
                      size: 80, color: AppColors.primary)
                  .animate()
                  .scale(duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                _isSignUp ? 'Ro\'yxatdan O\'tish' : 'Tizimga Kirish',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textMain),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email manzili',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  labelText: 'Parol',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage,
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : _resetPassword, // 🛠️ Yuklanish paytida o'chirib qo'yiladi
                  child: const Text('Parolni unutdingizmi?',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _handleAuth,
                        child: Text(
                          _isSignUp ? 'Ro\'yxatdan o\'tish' : 'Kirish',
                          style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              const Text('yoki', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.google,
                      color: Colors.redAccent),
                  label: const Text(
                    'Google orqali kirish',
                    style: TextStyle(
                        color: AppColors.textMain, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const FaIcon(FontAwesomeIcons.userSecret,
                    color: AppColors.textMuted),
                label: const Text(
                    'Mehmon rejimi (Guest Mode) bilan davom etish',
                    style: TextStyle(color: AppColors.textMain)),
                onPressed:
                    _isLoading ? null : () => _enterApp(isGuestMode: true),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _errorMessage =
                      ''; // Oynalar almashganda xatolikni tozalaymiz
                }),
                child: Text(
                  _isSignUp
                      ? 'Sizda akkaunt bormi? Tizimga kiring'
                      : 'Akkauntingiz yo\'qmi? Ro\'yxatdan o\'ting',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
