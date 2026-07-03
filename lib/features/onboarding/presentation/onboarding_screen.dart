import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Saltar'),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: AppColors.paperMuted,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.sage,
                    size: 58,
                  ),
                ),
              ),
              const SizedBox(height: 38),
              Text(
                'Tus ideas, en calma',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Un espacio tranquilo para escribir notas y capturar lo que piensas.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _StepDot(isActive: true),
                  _StepDot(),
                  _StepDot(),
                ],
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Siguiente'),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => context.go('/auth'),
                child: Text.rich(
                  TextSpan(
                    text: 'Ya tienes cuenta? ',
                    children: [
                      TextSpan(
                        text: 'Inicia sesion',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isActive ? 22 : 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.sage : AppColors.paperMuted,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
