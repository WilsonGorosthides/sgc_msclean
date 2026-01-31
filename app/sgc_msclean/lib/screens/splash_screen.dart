import 'package:flutter/material.dart';
import 'home_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Aguarda 3 segundos e navega para a HomeScreen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Usa pushReplacement para não deixar voltar para a splash screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo preto para combinar com o círculo da logo
      backgroundColor: Colors.black, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animação suave de entrada da logo
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value, // Um leve efeito de zoom
                    child: child,
                  ),
                );
              },
              // AQUI ESTÁ A SUA NOVA LOGO:
              child: Image.asset(
                'assets/images/logo_ms_clean.png',
                width: 250, 
              ),
            ),
            const SizedBox(height: 50),
            // Indicador de carregamento azul para combinar com a marca
            const CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}