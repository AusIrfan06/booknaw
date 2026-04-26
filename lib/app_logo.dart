import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    // We use a network image or a local asset. 
    // The user can replace 'assets/logo.png' with their own file.
    // For now, we provide a placeholder from a URL so it's visible immediately.
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.network(
        'https://uxwing.com/wp-content/themes/uxwing/download/food-and-drinks/nachos-icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.fastfood_rounded,
          size: size,
          color: Colors.deepOrange,
        ),
      ),
    );
  }
}
