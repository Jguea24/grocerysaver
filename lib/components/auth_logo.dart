import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.size = 96, this.showSubtitle = true});

  final double size;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/logo_grocesy.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                color: Theme.of(context).colorScheme.primaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.shopping_basket_rounded,
                  size: size * 0.55,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Grocery Saver',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F5F3F),
            letterSpacing: 0.2,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Compara precios y ahorra cada semana',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF507561)),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
