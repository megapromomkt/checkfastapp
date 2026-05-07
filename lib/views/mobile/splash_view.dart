import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import 'mobile_premium_home_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Navegação automática após 5 segundos para a Home
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MobilePremiumHomeView()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: Center(
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A Logo que "Acende" com efeito de Neon Glow pulsante
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withOpacity(0.4 * _glowAnimation.value),
                        blurRadius: 50 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ícone de Escudo que brilha conforme a animação
                      Icon(
                        Icons.verified_user_sharp,
                        size: 90,
                        color: AppColors.neonCyan.withOpacity(0.2 + (0.8 * _glowAnimation.value)),
                      ),
                      // Aro de carregamento sutil pulsando junto
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: _glowAnimation.value,
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.neonCyan.withOpacity(0.3 * _glowAnimation.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Nome do App com gradiente animado que acompanha o brilho
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3 + (0.7 * _glowAnimation.value)),
                      AppColors.neonCyan.withOpacity(_glowAnimation.value),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'CHECKFAST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'SISTEMA DE AUDITORIA INTELIGENTE',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
