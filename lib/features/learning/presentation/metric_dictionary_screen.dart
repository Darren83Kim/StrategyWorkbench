import 'package:flutter/material.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class MetricDictionaryScreen extends StatelessWidget {
  const MetricDictionaryScreen({super.key});

  static const _entries = [
    _MetricDictionaryEntry(
      title: 'PER',
      subtitle: 'Price Earnings Ratio',
      summary: '주가가 이익 대비 어느 정도로 평가되는지 보는 지표입니다.',
      reading: '낮을수록 저평가처럼 보일 수 있지만, 업황 둔화나 이익 감소 우려도 함께 확인해야 합니다.',
      appUsage: '가치주 기준에서는 PER 비중이 높아 낮은 PER 샘플이 상대적으로 위로 올라오기 쉽습니다.',
      accent: Color(0xFF60A5FA),
    ),
    _MetricDictionaryEntry(
      title: 'ROE',
      subtitle: 'Return On Equity',
      summary: '자기자본으로 얼마나 효율적으로 이익을 만들었는지 보는 수익성 지표입니다.',
      reading: '높을수록 수익성이 좋게 해석되지만, 일회성 이익이나 과도한 부채 영향도 구분해야 합니다.',
      appUsage: '급등주/퀀트 기준에서는 ROE가 높을수록 지표 점수에 더 크게 반영될 수 있습니다.',
      accent: Color(0xFF10B981),
    ),
    _MetricDictionaryEntry(
      title: '배당수익률',
      subtitle: 'Dividend Yield',
      summary: '현재 가격 대비 배당이 어느 정도인지 보는 현금흐름 관련 지표입니다.',
      reading: '높은 배당은 매력적으로 보일 수 있지만, 배당 지속 가능성과 실적 변동성을 함께 봐야 합니다.',
      appUsage: '배당주 기준에서는 배당수익률 비중이 높아 배당 축의 설명력이 커집니다.',
      accent: Color(0xFFFB923C),
    ),
    _MetricDictionaryEntry(
      title: '지표 점수',
      subtitle: 'Normalized Score',
      summary: '서로 단위가 다른 지표를 같은 비교 범위로 바꾼 값입니다.',
      reading: 'PER은 낮을수록, ROE와 배당은 높을수록 좋은 방향으로 정규화합니다.',
      appUsage: '앱은 정규화한 지표에 분석 기준의 비중을 곱해 샘플 순서를 계산합니다.',
      accent: Color(0xFFA78BFA),
    ),
    _MetricDictionaryEntry(
      title: '표본 종목',
      subtitle: 'Sample Universe',
      summary: '현재 분석 기준으로 비교에 사용된 종목 집합입니다.',
      reading: '표본이 바뀌면 같은 종목도 상대 위치가 달라질 수 있습니다.',
      appUsage: '국내/미국/전체 필터와 데이터 수집 상태에 따라 표본 종목 수가 달라질 수 있습니다.',
      accent: Color(0xFF22D3EE),
    ),
    _MetricDictionaryEntry(
      title: '순위 변화',
      subtitle: 'Rank Movement',
      summary: '이전 계산 결과와 현재 계산 결과 사이의 상대 순위 차이입니다.',
      reading: '순위 변화는 지표와 표본의 상대 비교 결과이며 미래 성과를 의미하지 않습니다.',
      appUsage: '대시보드에서는 학습 편의를 위해 변동이 큰 샘플을 요약해서 보여줍니다.',
      accent: Color(0xFFF472B6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('지표 사전'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GlassContainer(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF10B981),
                    size: 30,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '분석 기준을 읽는 작은 사전',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Strategy Workbench에서 쓰는 지표가 어떤 의미인지, 앱 안에서는 어떻게 비교에 반영되는지 정리했습니다. 모든 내용은 지표 학습용 정보이며 매수/매도 권유가 아닙니다.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ..._entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MetricDictionaryCard(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDictionaryEntry {
  final String title;
  final String subtitle;
  final String summary;
  final String reading;
  final String appUsage;
  final Color accent;

  const _MetricDictionaryEntry({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.reading,
    required this.appUsage,
    required this.accent,
  });
}

class _MetricDictionaryCard extends StatelessWidget {
  final _MetricDictionaryEntry entry;

  const _MetricDictionaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: entry.accent,
            collapsedIconColor: Colors.white54,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: entry.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: entry.accent.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(
                  entry.title.characters.take(2).toString(),
                  style: TextStyle(
                    color: entry.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            title: Text(
              entry.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              entry.subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            children: [
              _DictionaryLine(
                title: '의미',
                body: entry.summary,
                accent: entry.accent,
              ),
              const SizedBox(height: 10),
              _DictionaryLine(
                title: '읽는 법',
                body: entry.reading,
                accent: entry.accent,
              ),
              const SizedBox(height: 10),
              _DictionaryLine(
                title: '앱에서의 역할',
                body: entry.appUsage,
                accent: entry.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DictionaryLine extends StatelessWidget {
  final String title;
  final String body;
  final Color accent;

  const _DictionaryLine({
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF253044)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
