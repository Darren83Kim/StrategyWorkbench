import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/language_provider.dart';
import 'onboarding_controller.dart';

class OnboardingStep {
  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<OnboardingStep> _steps(bool korean) {
    if (korean) {
      return const [
        OnboardingStep(
          icon: Icons.tune,
          title: '분석 기준 고르기',
          body: '전략 탭에서 PER, ROE, 배당 비중을 고르면 그 기준으로 종목 순서가 바뀝니다.',
        ),
        OnboardingStep(
          icon: Icons.star_outline,
          title: '관심 종목 담기',
          body: '순위 목록에서 별표를 누르면 대시보드 관심 종목 레이더에 모입니다.',
        ),
        OnboardingStep(
          icon: Icons.menu_book_outlined,
          title: '지표 사전 보기',
          body: 'PER, ROE, 배당이 무엇을 뜻하는지는 지표 사전에서 짧게 확인할 수 있습니다.',
        ),
      ];
    }
    return const [
      OnboardingStep(
        icon: Icons.tune,
        title: 'Pick analysis criteria',
        body:
            'On the Strategy tab, set PER, ROE, and dividend weights to change how stocks are ordered.',
      ),
      OnboardingStep(
        icon: Icons.star_outline,
        title: 'Build a watchlist',
        body:
            'Star a stock in the ranking and it shows up on the dashboard watchlist radar.',
      ),
      OnboardingStep(
        icon: Icons.menu_book_outlined,
        title: 'Open the metric dictionary',
        body:
            'The metric dictionary explains what PER, ROE, and dividend yield mean in this app.',
      ),
    ];
  }

  Future<void> _finish() async {
    await onboardingController.complete();
    if (!mounted) {
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final korean = ref.watch(languageProvider).value == 'ko' ||
        (ref.watch(languageProvider).value == null &&
            WidgetsBinding.instance.platformDispatcher.locale.languageCode
                .toLowerCase()
                .startsWith('ko'));
    final steps = _steps(korean);
    final isLast = _index == steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(korean ? '건너뛰기' : 'Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(step.icon, size: 72, color: const Color(0xFF10B981)),
                        const SizedBox(height: 24),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (index) {
                  final active = index == _index;
                  return Container(
                    width: active ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF10B981)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                      return;
                    }
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Text(
                    isLast
                        ? (korean ? '시작하기' : 'Get started')
                        : (korean ? '다음' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
