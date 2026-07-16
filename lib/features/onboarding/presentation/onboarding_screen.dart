import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.edit_note_rounded,
      title: 'Tus ideas, en calma',
      body:
          'Un espacio tranquilo para escribir notas y capturar lo que piensas.',
    ),
    _OnboardingPageData(
      icon: Icons.dashboard_customize_rounded,
      title: 'Organiza sin esfuerzo',
      body:
          'Filtra por carpetas, fija lo importante y encuentra tus notas rapido.',
    ),
    _OnboardingPageData(
      icon: Icons.checklist_rounded,
      title: 'Listas e imagenes',
      body: 'Crea checklists, agrega imagenes y conserva todo sincronizado.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(page: _pages[index]);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < _pages.length; index++)
                    _StepDot(
                      isActive: index == _currentPage,
                      onTap: () => _goToPage(index),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _nextStep,
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Comenzar' : 'Siguiente',
                ),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _nextStep() {
    if (_currentPage == _pages.length - 1) {
      context.go('/auth');
      return;
    }

    _goToPage(_currentPage + 1);
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({this.isActive = false, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isActive ? 22 : 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.sage : AppColors.paperMuted,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: AppColors.paperMuted,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(page.icon, color: AppColors.sage, size: 58),
        ),
        const SizedBox(height: 38),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          page.body,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
