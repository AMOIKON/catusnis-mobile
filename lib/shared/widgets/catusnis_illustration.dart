// lib/shared/widgets/catusnis_illustration.dart
//
// Pour utiliser le GIF dans Flutter :
// 1. Copier catusnis_animation.gif dans assets/images/
// 2. Ajouter flutter_gif ou utiliser Image.asset directement
//
// Flutter supporte les GIF nativement avec Image.asset !

import 'package:flutter/material.dart';

class CatusnisIllustration extends StatelessWidget {
  final double size;
  const CatusnisIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // ✅ Flutter joue les GIF automatiquement
      child: Image.asset(
        'assets/images/catusnis_animation.gif',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
