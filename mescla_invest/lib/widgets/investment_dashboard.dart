// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Dashboard visual de investimentos da carteira simulada.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/dashboard_calculator.dart';
import '../models/ativo_model.dart';
import '../models/transaction_model.dart';

enum InvestmentDashboardPeriod { d1, s1, m1, m6, ytd }

class InvestmentDashboard extends StatefulWidget {
  final List<AtivoModel> ativos;
  final List<TransactionModel> transacoes;
  final String currentUid;

  const InvestmentDashboard({
    super.key,
    required this.ativos,
    required this.transacoes,
    required this.currentUid,
  });

  @override
  State<InvestmentDashboard> createState() => _InvestmentDashboardState();
}

class _InvestmentDashboardState extends State<InvestmentDashboard> {
  InvestmentDashboardPeriod _period = InvestmentDashboardPeriod.m1;

  static const Map<InvestmentDashboardPeriod, String> _periodLabels = {
    InvestmentDashboardPeriod.d1: '1D',
    InvestmentDashboardPeriod.s1: '1S',
    InvestmentDashboardPeriod.m1: '1M',
    InvestmentDashboardPeriod.m6: '6M',
    InvestmentDashboardPeriod.ytd: 'YTD',
  };

  static const List<Color> _chartColors = [
    Color(0xFF1E6B5E),
    Color(0xFF2F80ED),
    Color(0xFFF2994A),
    Color(0xFF9B51E0),
    Color(0xFF56CCF2),
    Color(0xFF6FCF97),
    Color(0xFFEB5757),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final data = DashboardCalculator.calculate(
      ativos: widget.ativos,
      transacoes: widget.transacoes,
      currentUid: widget.currentUid,
      periodStart: _periodStart(now),
      now: now,
    );

    if (!data.hasPositions) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildSummary(data.summary),
        const SizedBox(height: 12),
        _buildLineSection(data.portfolioHistory),
        const SizedBox(height: 12),
        _buildAllocationSection(data.positions),
        const SizedBox(height: 12),
        _buildResultSection(data.positions),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_rounded, color: AppColors.textHint, size: 36),
          const SizedBox(height: 8),
          Text(
            'Nenhum ativo na carteira.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(PortfolioSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMetricCard(
              width: itemWidth,
              label: 'Valor atual',
              value: _formatCents(summary.currentValueCents),
            ),
            _buildMetricCard(
              width: itemWidth,
              label: 'Total pago',
              value: _formatCents(summary.investedValueCents),
            ),
            _buildMetricCard(
              width: itemWidth,
              label: 'Resultado',
              value: _formatSignedCents(summary.resultCents),
              valueColor: _resultColor(summary.resultCents),
            ),
            _buildMetricCard(
              width: itemWidth,
              label: 'Rentabilidade',
              value: _formatSignedPercent(summary.resultPercent),
              valueColor: _resultColor(summary.resultCents),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFDDE4F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineSection(List<DashboardLinePoint> points) {
    return _buildSection(
      title: 'Valor da carteira',
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          if (points.length < 2)
            _buildChartEmpty('Histórico insuficiente.')
          else
            SizedBox(height: 180, child: _buildLineChart(points)),
        ],
      ),
    );
  }

  Widget _buildAllocationSection(List<DashboardPosition> positions) {
    final visiblePositions = positions
        .where((position) => position.currentValueCents > 0)
        .toList();

    return _buildSection(
      title: 'Distribuicao por startup',
      child: visiblePositions.isEmpty
          ? _buildChartEmpty('Sem valor investido.')
          : Column(
              children: [
                SizedBox(
                  height: 190,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 38,
                      sectionsSpace: 2,
                      sections: List.generate(visiblePositions.length, (index) {
                        final position = visiblePositions[index];
                        final percent = position.allocationPercent;

                        return PieChartSectionData(
                          value: position.currentValueCents.toDouble(),
                          title: percent >= 8
                              ? '${percent.toStringAsFixed(0)}%'
                              : '',
                          color: _chartColors[index % _chartColors.length],
                          radius: 58,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegend(visiblePositions),
              ],
            ),
    );
  }

  Widget _buildResultSection(List<DashboardPosition> positions) {
    final visiblePositions = [...positions]
      ..sort((first, second) {
        return second.resultCents.abs().compareTo(first.resultCents.abs());
      });
    final limitedPositions = visiblePositions.take(6).toList();

    return _buildSection(
      title: 'Ganho ou perda por startup',
      child: limitedPositions.isEmpty
          ? _buildChartEmpty('Sem ativos para comparar.')
          : SizedBox(height: 220, child: _buildBarChart(limitedPositions)),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: InvestmentDashboardPeriod.values.map((period) {
        final selected = period == _period;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _period = period),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _periodLabels[period]!,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(List<DashboardLinePoint> points) {
    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].valueCents / 100),
    ];
    final minValue = spots.map((spot) => spot.y).reduce(math.min);
    final maxValue = spots.map((spot) => spot.y).reduce(math.max);
    final range = maxValue - minValue;
    final padding = range <= 0
        ? math.max(maxValue.abs() * 0.1, 1.0)
        : range * 0.12;
    final minY = math.max(0.0, minValue - padding);
    final maxY = maxValue + padding;
    final positive = spots.last.y >= spots.first.y;
    final lineColor = positive ? Colors.green.shade700 : Colors.red.shade700;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY <= minY ? minY + 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _chartInterval(minY, maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.textHint.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: _chartInterval(minY, maxY),
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatShortReais(value),
                  style: TextStyle(color: AppColors.textHint, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _bottomInterval(points.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(points[index].date),
                    style: TextStyle(color: AppColors.textHint, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (items) {
              return items.map((item) {
                final point = points[item.spotIndex];

                return LineTooltipItem(
                  '${_formatCents(point.valueCents)}\n${_formatDate(point.date)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: points.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBarChart(List<DashboardPosition> positions) {
    final values = positions.map((item) => item.resultCents / 100).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final maxAbs = math.max(minValue.abs(), maxValue.abs());
    final chartMax = maxValue <= 0 ? maxAbs * 0.15 : maxAbs * 1.2;
    final chartMin = minValue >= 0 ? -maxAbs * 0.15 : -maxAbs * 1.2;
    final minY = chartMin == 0 ? -1.0 : chartMin;
    final maxY = chartMax == 0 ? 1.0 : chartMax;

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _chartInterval(minY, maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.textHint.withValues(
              alpha: value == 0 ? 0.45 : 0.18,
            ),
            strokeWidth: value == 0 ? 1.4 : 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: _chartInterval(minY, maxY),
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatShortReais(value),
                  style: TextStyle(color: AppColors.textHint, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= positions.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortName(positions[index].startupName),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final position = positions[group.x.toInt()];

              return BarTooltipItem(
                '${position.startupName}\n${_formatSignedCents(position.resultCents)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(positions.length, (index) {
          final position = positions[index];
          final value = position.resultCents / 100;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: 16,
                color: _resultColor(position.resultCents),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegend(List<DashboardPosition> positions) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: List.generate(positions.length, (index) {
        final position = positions[index];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _chartColors[index % _chartColors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${_shortName(position.startupName)} '
              '${position.allocationPercent.toStringAsFixed(0)}%',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChartEmpty(String text) {
    return SizedBox(
      height: 110,
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      ),
    );
  }

  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case InvestmentDashboardPeriod.d1:
        return now.subtract(const Duration(hours: 24));
      case InvestmentDashboardPeriod.s1:
        return now.subtract(const Duration(days: 7));
      case InvestmentDashboardPeriod.m1:
        return now.subtract(const Duration(days: 30));
      case InvestmentDashboardPeriod.m6:
        return now.subtract(const Duration(days: 180));
      case InvestmentDashboardPeriod.ytd:
        return DateTime(now.year, 1, 1);
    }
  }

  Color _resultColor(int cents) {
    if (cents > 0) return Colors.green.shade700;
    if (cents < 0) return Colors.red.shade700;
    return AppColors.textPrimary;
  }

  double _chartInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 0) return 1;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    if (range <= 100) return 25;
    if (range <= 500) return 100;
    if (range <= 1000) return 250;
    return (range / 4).roundToDouble();
  }

  double _bottomInterval(int totalPoints) {
    if (totalPoints <= 5) return 1;
    if (totalPoints <= 12) return 2;
    if (totalPoints <= 30) return 6;
    return (totalPoints / 5).roundToDouble();
  }

  String _formatCents(int cents) {
    final value = cents.abs() / 100;
    final sign = cents < 0 ? '-' : '';
    return '${sign}R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatSignedCents(int cents) {
    if (cents > 0) return '+${_formatCents(cents)}';
    return _formatCents(cents);
  }

  String _formatSignedPercent(double percent) {
    final sign = percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String _formatShortReais(double value) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(1)}M';
    }

    if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}k';
    }

    return '$sign${absValue.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 10) return trimmed;
    return '${trimmed.substring(0, 9)}.';
  }
}
