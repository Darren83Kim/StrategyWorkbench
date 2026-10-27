import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/features/learning/domain/metric_calculator.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class MetricCalculatorScreen extends ConsumerStatefulWidget {
  const MetricCalculatorScreen({super.key});

  @override
  ConsumerState<MetricCalculatorScreen> createState() =>
      _MetricCalculatorScreenState();
}

class _MetricCalculatorScreenState
    extends ConsumerState<MetricCalculatorScreen> {
  final _price = TextEditingController();
  final _eps = TextEditingController();
  final _income = TextEditingController();
  final _equity = TextEditingController();
  final _dividend = TextEditingController();
  final _dividendPrice = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _eps.dispose();
    _income.dispose();
    _equity.dispose();
    _dividend.dispose();
    _dividendPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final korean = (ref.watch(languageProvider).value ?? 'en') == 'ko';
    final per = MetricCalculator.per(
      price: MetricCalculator.parseNumber(_price.text),
      eps: MetricCalculator.parseNumber(_eps.text),
    );
    final roe = MetricCalculator.roePercent(
      netIncome: MetricCalculator.parseNumber(_income.text),
      equity: MetricCalculator.parseNumber(_equity.text),
    );
    final dividendYield = MetricCalculator.dividendYieldPercent(
      dividendPerShare: MetricCalculator.parseNumber(_dividend.text),
      price: MetricCalculator.parseNumber(_dividendPrice.text),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(korean ? '지표 계산기' : 'Metric calculator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                korean ? '입력한 숫자로만 계산합니다. 시장 시세가 아니고, 매수·매도 신호가 아닙니다.' : 'These results use only the numbers you type. They are not market data and not a buy or sell signal.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _CalculatorCard(
            title: 'PER',
            formula: korean
                ? 'PER = 주가 ÷ 주당이익'
                : 'PER = price ÷ earnings per share',
            accent: const Color(0xFF60A5FA),
            fields: [
              _NumberField(
                fieldKey: const Key('per-price'),
                controller: _price,
                label: korean ? '주가' : 'Price',
                onChanged: _refresh,
              ),
              _NumberField(
                fieldKey: const Key('per-eps'),
                controller: _eps,
                label: korean ? '주당이익' : 'Earnings per share',
                onChanged: _refresh,
              ),
            ],
            result: _formatResult(
              value: per,
              ready: korean
                  ? '입력값으로 계산한 PER은 ${per?.toStringAsFixed(2)}입니다.'
                  : 'PER from these inputs is ${per?.toStringAsFixed(2)}.',
              missing: korean
                  ? '주가와 주당이익이 0보다 커야 계산됩니다.'
                  : 'Price and earnings per share must be greater than zero.',
            ),
          ),
          const SizedBox(height: 12),
          _CalculatorCard(
            title: 'ROE',
            formula: korean
                ? 'ROE = 이익 ÷ 자기자본 × 100'
                : 'ROE = earnings ÷ equity × 100',
            accent: const Color(0xFF10B981),
            fields: [
              _NumberField(
                fieldKey: const Key('roe-income'),
                controller: _income,
                label: korean ? '이익' : 'Earnings',
                onChanged: _refresh,
              ),
              _NumberField(
                fieldKey: const Key('roe-equity'),
                controller: _equity,
                label: korean ? '자기자본' : 'Equity',
                onChanged: _refresh,
              ),
            ],
            result: _formatResult(
              value: roe,
              ready: korean
                  ? '입력값으로 계산한 ROE는 ${roe?.toStringAsFixed(2)}%입니다.'
                  : 'ROE from these inputs is ${roe?.toStringAsFixed(2)}%.',
              missing: korean ? '자기자본이 0보다 커야 계산됩니다. 이익은 음수일 수 있습니다.' : 'Equity must be greater than zero. Earnings can be negative.',
            ),
          ),
          const SizedBox(height: 12),
          _CalculatorCard(
            title: korean ? '배당수익률' : 'Dividend yield',
            formula: korean
                ? '배당수익률 = 주당 배당 ÷ 주가 × 100'
                : 'Dividend yield = dividend per share ÷ price × 100',
            accent: const Color(0xFFFB923C),
            fields: [
              _NumberField(
                fieldKey: const Key('dividend-cash'),
                controller: _dividend,
                label: korean ? '주당 배당' : 'Dividend per share',
                onChanged: _refresh,
              ),
              _NumberField(
                fieldKey: const Key('dividend-price'),
                controller: _dividendPrice,
                label: korean ? '주가' : 'Price',
                onChanged: _refresh,
              ),
            ],
            result: _formatResult(
              value: dividendYield,
              ready: korean
                  ? '입력값으로 계산한 배당수익률은 ${dividendYield?.toStringAsFixed(2)}%입니다.'
                  : 'Dividend yield from these inputs is ${dividendYield?.toStringAsFixed(2)}%.',
              missing: korean ? '주가가 0보다 크고 주당 배당이 0 이상이어야 계산됩니다.' : 'Price must be greater than zero and the dividend cannot be negative.',
            ),
          ),
        ],
      ),
    );
  }

  void _refresh(String _) => setState(() {});

  String _formatResult({
    required double? value,
    required String ready,
    required String missing,
  }) {
    if (value == null) {
      return missing;
    }
    return ready;
  }
}

class _CalculatorCard extends StatelessWidget {
  final String title;
  final String formula;
  final Color accent;
  final List<Widget> fields;
  final String result;

  const _CalculatorCard({
    required this.title,
    required this.formula,
    required this.accent,
    required this.fields,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formula,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...fields,
            const SizedBox(height: 8),
            Text(
              result,
              key: ValueKey(result),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
        ],
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
