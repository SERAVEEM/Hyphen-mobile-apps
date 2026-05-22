import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'categories.dart';
import 'HomePage.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HypenApp());
}

class HypenApp extends StatelessWidget {
  const HypenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYPEN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const OnboardingScreen(),
    );
  }
}


//  Slide data model

class SlideData {
  final Color color;
  final String category;
  final String headline;
  final String imagePath;

  const SlideData({
    required this.color,
    required this.category,
    required this.headline,
    required this.imagePath,
  });
}

const List<SlideData> _slides = [
  SlideData(
    color: Color.fromARGB(0, 0, 0, 0), 
    category: 'FASHION',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide1.png',
  ),
  SlideData(
    color: Color.fromARGB(255, 44, 62, 80), // dark navy
    category: 'STREET',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide4.jpg',
  ),
  SlideData(
    color: Color.fromARGB(255, 26, 26, 26), // near-black
    category: 'LUXURY',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide3.jpg',
  ),
];


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {

  int _currentIndex = 0;
  Timer? _timer;

  
  late final AnimationController _textCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // Derived animations from the single controller
  late final Animation<double> _textFade = _textCtrl;
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _textCtrl.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _slides.length;
    });
    // Reset and replay the text entrance animation
    _textCtrl
      // ..reset()
      ..forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Background carousel ──────────────────────────
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Container(
              // ValueKey tells AnimatedSwitcher "this is a new slide"
              key: ValueKey(_currentIndex),
              color: slide.color,
              
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 600,
              ),
            ),
          ),

          // ── Bottom dark gradient — keeps text legible ────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.6, 1.0],
                colors: [Colors.transparent, Colors.black38],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(
                    child: Text(
                      'HYPEN.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.96,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 33),
                  child: FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            slide.category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slide.headline,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 84),

                Padding(
                  padding: const EdgeInsets.fromLTRB(33, 0, 33, 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      TextButton(
                        onPressed: () => debugPrint('Skip tapped'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}

