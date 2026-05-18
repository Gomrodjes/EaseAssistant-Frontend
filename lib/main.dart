import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_colors.dart';
import 'config/measures.dart';
import 'services/notification_service.dart';
import 'views/auth/login_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ease Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.turquoise),
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 5);
  static const _phrases = [
    'Facil de usar\nDificil de no querer',
    'Tu ayuda empieza aqui',
    'Organiza mejor tu dia',
    'Conectar nunca fue tan facil',
    'Cada tarea cuenta',
    'Todo listo para ayudarte',
    'Menos esfuerzo, mas soluciones',
    'Pequenos pasos, grandes ayudas',
    'A un toque de distancia',
    'Tu asistencia, mas simple',
  ];

  late final AnimationController _controller;
  late String _selectedPhrase;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _selectedPhrase = (_phrases.toList()..shuffle()).first;
    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      final nextPhrase = (_phrases.where((phrase) => phrase != _selectedPhrase).toList()
            ..shuffle())
          .first;
      setState(() {
        _selectedPhrase = nextPhrase;
      });
    });

    Future<void>.delayed(_splashDuration, () {
      if (!mounted) return;
      _phraseTimer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE4F6F8),
              Color(0xFF8CDDEA),
              Color(0xFF79D4E2),
              Color(0xFFDDF7F8),
            ],
            stops: [0.0, 0.24, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 42 * scale),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  'EaseAssistant',
                  style: TextStyle(
                    fontSize: 31 * scale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 44 * scale),
                Container(
                  width: 220 * scale,
                  height: 220 * scale,
                  padding: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30 * scale),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x6FA8E2E6),
                        Color(0x4C63B3BC),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 10),
                        blurRadius: 18,
                      ),
                      BoxShadow(
                        color: Color(0x30FFFFFF),
                        offset: Offset(-4, -4),
                        blurRadius: 12,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/images/Icon-App-1.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 58 * scale),
                SizedBox(
                  height: 64 * scale,
                  child: Center(
                    child: Text(
                      _selectedPhrase,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0x55000000),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24 * scale),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: 11 * scale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x88FFFFFF),
                            Color(0x55D7F4F7),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _controller.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xE8FFFFFF),
                                  Color(0xFF88E0EA),
                                  Color(0xFF9B9B9B),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 78 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
