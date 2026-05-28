// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Widget de grafico de valorizacao dos tokens

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/ativo_model.dart';
import '../core/constants/app_colors.dart';

enum PeriodoGrafico { d1, s1, m1, m6, ytd }

class TokenValorizacaoChart extends StatefulWidget {
  final List<AtivoModel> ativos;

  const TokenValorizacaoChart({super.key, required this.ativos});

  @override
  State<TokenValorizacaoChart> createState() => _TokenValorizacaoChartState();
}

class _TokenValorizacaoChartState extends State<TokenValorizacaoChart> {
  PeriodoGrafico _periodoSelecionado = PeriodoGrafico.m1;
  int _ativoSelecionadoIndex = 0;

  static const Map<PeriodoGrafico, String> _periodLabels = {
    PeriodoGrafico.d1: '1D',
    PeriodoGrafico.s1: '1S',
    PeriodoGrafico.m1: '1M',
    PeriodoGrafico.m6: '6M',
    PeriodoGrafico.ytd: 'YTD',
  };

  @override
  Widget build(BuildContext context) {
    if (widget.ativos.isEmpty) {
      return _buildEmptyState();
    }

    // Clamp index
    if (_ativoSelecionadoIndex >= widget.ativos.length) {
      _ativoSelecionadoIndex = 0;
    }

    final ativo = widget.ativos[_ativoSelecionadoIndex];
    final pontosFiltrados = _filtrarPorPeriodo(ativo.historicoPrecos);

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
            'Grafico de Valorizacao',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Token selector chips
          if (widget.ativos.length > 1) ...[
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.ativos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _ativoSelecionadoIndex;
                  final a = widget.ativos[index];
                  return GestureDetector(
                    onTap: () => setState(() => _ativoSelecionadoIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        a.startupNome.isNotEmpty ? a.startupNome : a.startupId,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Variation indicator
          _buildVariacaoIndicator(ativo, pontosFiltrados),
          const SizedBox(height: 16),
          // Chart
          pontosFiltrados.length >= 2
              ? SizedBox(height: 180, child: _buildChart(pontosFiltrados))
              : SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Sem transacoes registradas neste periodo.',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          // Period selector
          _buildPeriodSelector(),
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafico de Valorizacao',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.textHint,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum ativo na carteira.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVariacaoIndicator(AtivoModel ativo, List<PricePoint> pontos) {
    double variacao = 0;
    int precoAtual = ativo.precoAtualCentavos;

    if (pontos.isNotEmpty) {
      final precoInicio = pontos.first.precoCentavos;
      if (precoInicio > 0) {
        variacao = ((precoAtual - precoInicio) / precoInicio) * 100;
      }
    } else if (ativo.precoPrimarioCentavos > 0) {
      variacao =
          ((precoAtual - ativo.precoPrimarioCentavos) /
              ativo.precoPrimarioCentavos) *
          100;
    }

    final isPositivo = variacao >= 0;
    final corVariacao = isPositivo
        ? Colors.green.shade700
        : Colors.red.shade700;
    final iconeVariacao = isPositivo
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final sinal = isPositivo ? '+' : '';

    return Row(
      children: [
        Text(
          'R\$ ${(precoAtual / 100).toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: corVariacao.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconeVariacao, size: 14, color: corVariacao),
              const SizedBox(width: 3),
              Text(
                '$sinal${variacao.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: corVariacao,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<PricePoint> pontos) {
    final spots = <FlSpot>[];
    for (int i = 0; i < pontos.length; i++) {
      spots.add(FlSpot(i.toDouble(), pontos[i].precoCentavos / 100));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;
    final chartMinY = (minY - padding).clamp(0, double.infinity);
    final chartMaxY = maxY + padding;

    // Determine if the trend is positive
    final isPositive = spots.last.y >= spots.first.y;
    final lineColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final gradientColors = isPositive
        ? [
            Colors.green.shade400.withValues(alpha: 0.3),
            Colors.green.shade400.withValues(alpha: 0.0),
          ]
        : [
            Colors.red.shade400.withValues(alpha: 0.3),
            Colors.red.shade400.withValues(alpha: 0.0),
          ];

    return LineChart(
      LineChartData(
        minY: chartMinY.toDouble(),
        maxY: chartMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(chartMinY.toDouble(), chartMaxY),
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
              reservedSize: 48,
              interval: _calcInterval(chartMinY.toDouble(), chartMaxY),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(color: AppColors.textHint, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _calcBottomInterval(pontos.length),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= pontos.length) {
                  return const SizedBox.shrink();
                }
                final d = pontos[idx].data;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
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
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final ponto = idx < pontos.length ? pontos[idx] : null;
                final dataStr = ponto != null
                    ? '${ponto.data.day.toString().padLeft(2, '0')}/${ponto.data.month.toString().padLeft(2, '0')}/${ponto.data.year}'
                    : '';
                return LineTooltipItem(
                  'R\$ ${spot.y.toStringAsFixed(2).replaceAll('.', ',')}\n$dataStr',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
            dotData: FlDotData(
              show: pontos.length <= 15,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: lineColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: PeriodoGrafico.values.map((periodo) {
        final isSelected = periodo == _periodoSelecionado;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _periodoSelecionado = periodo),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                _periodLabels[periodo]!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<PricePoint> _filtrarPorPeriodo(List<PricePoint> pontos) {
    final now = DateTime.now();
    late DateTime inicio;

    switch (_periodoSelecionado) {
      case PeriodoGrafico.d1:
        inicio = now.subtract(const Duration(hours: 24));
        break;
      case PeriodoGrafico.s1:
        inicio = now.subtract(const Duration(days: 7));
        break;
      case PeriodoGrafico.m1:
        inicio = now.subtract(const Duration(days: 30));
        break;
      case PeriodoGrafico.m6:
        inicio = now.subtract(const Duration(days: 180));
        break;
      case PeriodoGrafico.ytd:
        inicio = DateTime(now.year, 1, 1);
        break;
    }

    return pontos.where((p) => p.data.isAfter(inicio)).toList();
  }

  double _calcInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1;
    if (range <= 1) return 0.25;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    if (range <= 100) return 25;
    return (range / 4).roundToDouble();
  }

  double _calcBottomInterval(int totalPoints) {
    if (totalPoints <= 5) return 1;
    if (totalPoints <= 15) return 3;
    if (totalPoints <= 30) return 7;
    return (totalPoints / 5).roundToDouble();
  }
}
