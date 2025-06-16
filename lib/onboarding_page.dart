import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/screens/splash_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final List<Widget> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticleDots();
  }

  Future<void> _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isSmallScreen = screenSize.width < 360;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OnboardingStyles.darkBlueColor,
              Color(0xFF0A2342), // fallback for opacity
              Color(0xFF0A2342),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: _buildDecorativeCircle(200,
                  OnboardingStyles.greenColor.withOpacity(0.1),
                  OnboardingStyles.lightBlueColor.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _buildDecorativeCircle(250,
                  OnboardingStyles.lightBlueColor.withOpacity(0.1),
                  OnboardingStyles.greenColor.withOpacity(0.05)),
            ),
            ..._particles,
            SafeArea(
              child: IntroductionScreen(
                pages: [
                  _buildPageModel(
                    context,
                    "Speak the World",
                    "Translate conversations in real-time with our advanced voice recognition technology.",
                    'assets/globe.svg',
                    [OnboardingStyles.greenColor, OnboardingStyles.lightBlueColor],
                    1,
                    OnboardingStyles.greenColor,
                  ),
                  _buildPageModel(
                    context,
                    "Natural Conversations",
                    "Speak or type in your language and get instant translations with natural-sounding voice.",
                    'assets/mic.svg',
                    [OnboardingStyles.lightBlueColor, OnboardingStyles.greenColor],
                    2,
                    OnboardingStyles.lightBlueColor,
                  ),
                  _buildPageModel(
                    context,
                    "Travel Confidently",
                    "Share translations, save favorites, and access offline when you need them most.",
                    'assets/travel.svg',
                    [OnboardingStyles.greenColor, OnboardingStyles.lightBlueColor],
                    3,
                    OnboardingStyles.greenColor,
                  ),
                ],
                onDone: _onIntroEnd,
                showSkipButton: true,
                skip: _buildSkipButton(),
                next: _buildNextButton(),
                done: _buildDoneButton(),
                dotsDecorator: DotsDecorator(
                  size: const Size(8, 8),
                  color: Colors.white.withOpacity(0.4),
                  activeSize: Size(isSmallScreen ? 25 : 35, 8),
                  activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  activeColor: OnboardingStyles.greenColor,
                  spacing: const EdgeInsets.symmetric(horizontal: 5),
                ),
                globalBackgroundColor: Colors.transparent,
                bodyPadding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : (isSmallScreen ? 16 : 30)),
                controlsPadding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageViewModel _buildPageModel(BuildContext context, String title, String body, String asset,
      List<Color> colors, int index, Color titleColor) {
    return PageViewModel(
      title: title,
      body: body,
      image: _buildOnboardingImage(context, asset, colors, index),
      decoration: _getPageDecoration(titleColor),
    );
  }

  Widget _buildOnboardingImage(BuildContext context, String assetName, List<Color> gradientColors, int pageIndex) {
    return Container(
      width: 300,
      height: 300,
      margin: const EdgeInsets.only(bottom: 20),
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [gradientColors[0].withOpacity(0.2), Colors.transparent],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A2342),
                    Color(0xFF0A2342),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: gradientColors[0].withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            Transform.rotate(
              angle: pageIndex * 0.15 * 2 * pi,
              child: CustomPaint(
                painter: DashedCirclePainter(
                  color: gradientColors[0].withOpacity(0.3),
                  dashes: 12,
                  gapSize: 12,
                ),
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withOpacity(0.2),
                    gradientColors[1].withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: OnboardingStyles.buildSvgIcon(assetName),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color1, Color color2) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color1, color2],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }

  List<Widget> _buildParticleDots() {
    const int seed = 42;
    final List<Widget> dots = [];

    for (int i = 0; i < 8; i++) {
      final double size = (i % 3 + 1) * 4.0;
      final double top = ((seed + i * 100) % 800).toDouble();
      final double left = ((seed + i * 200) % 400).toDouble();
      final double opacity = ((i % 5) + 1) * 0.05;
      final color = i % 2 == 0
          ? OnboardingStyles.greenColor.withOpacity(opacity)
          : OnboardingStyles.lightBlueColor.withOpacity(opacity);

      dots.add(Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ));
    }
    return dots;
  }

  PageDecoration _getPageDecoration(Color titleColor) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: titleColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      bodyTextStyle: const TextStyle(
        fontSize: 18,
        color: Colors.white70,
        height: 1.5,
        letterSpacing: 0.3,
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      pageColor: Colors.transparent,
      imagePadding: const EdgeInsets.only(top: 40),
    );
  }

  Widget _buildSkipButton() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    child: Text("Skip", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
  );

  Widget _buildNextButton() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [OnboardingStyles.greenColor, OnboardingStyles.lightBlueColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: OnboardingStyles.primaryShadow,
    ),
    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
  );

  Widget _buildDoneButton() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [OnboardingStyles.greenColor, OnboardingStyles.lightBlueColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: OnboardingStyles.primaryShadow,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text("GO", style: OnboardingStyles.buttonTextStyle),
        SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
      ],
    ),
  );
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashes;
  final double gapSize;

  DashedCirclePainter({required this.color, required this.dashes, required this.gapSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashLength = (2 * pi * radius - gapSize * dashes) / dashes;

    for (int i = 0; i < dashes; i++) {
      final startAngle = (i * (dashLength + gapSize)) / radius;
      final endAngle = startAngle + dashLength / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class OnboardingStyles {
  static const Color darkBlueColor = Color(0xFF0A2342);
  static const Color greenColor = Color(0xFF2CA58D);
  static const Color lightBlueColor = Color(0xFF0496FF);

  static const TextStyle buttonTextStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontSize: 16,
    letterSpacing: 0.5,
  );

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: greenColor.withOpacity(0.3),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];

  static Widget buildSvgIcon(String assetName) {
    return SvgPicture.asset(
      assetName,
      color: Colors.white,
      height: 100,
      width: 100,
    );
  }
}
