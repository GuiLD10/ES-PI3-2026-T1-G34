// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Calcula metricas e series do dashboard de investimentos.

import '../../models/ativo_model.dart';
import '../../models/transaction_model.dart' hide pricePrecisionScale;

class DashboardData {
  final PortfolioSummary summary;
  final List<DashboardPosition> positions;
  final List<DashboardLinePoint> portfolioHistory;

  const DashboardData({
    required this.summary,
    required this.positions,
    required this.portfolioHistory,
  });

  bool get hasPositions => positions.isNotEmpty;
}

class PortfolioSummary {
  final int currentValueCents;
  final int investedValueCents;
  final int resultCents;
  final double resultPercent;

  const PortfolioSummary({
    required this.currentValueCents,
    required this.investedValueCents,
    required this.resultCents,
    required this.resultPercent,
  });
}

class DashboardPosition {
  final String startupId;
  final String startupName;
  final int quantity;
  final int averagePriceCents;
  final int currentPriceCents;
  final int investedValueCents;
  final int currentValueCents;
  final int resultCents;
  final double resultPercent;
  final double allocationPercent;

  const DashboardPosition({
    required this.startupId,
    required this.startupName,
    required this.quantity,
    required this.averagePriceCents,
    required this.currentPriceCents,
    required this.investedValueCents,
    required this.currentValueCents,
    required this.resultCents,
    required this.resultPercent,
    required this.allocationPercent,
  });
}

class DashboardLinePoint {
  final DateTime date;
  final int valueCents;

  const DashboardLinePoint({required this.date, required this.valueCents});
}

class DashboardCalculator {
  DashboardCalculator._();

  static DashboardData calculate({
    required List<AtivoModel> ativos,
    List<TransactionModel> transacoes = const [],
    String currentUid = '',
    required DateTime periodStart,
    required DateTime now,
  }) {
    final ativosPorStartup = {
      for (final ativo in ativos) ativo.startupId: ativo,
    };
    final estadosPorStartup = _buildTradeStates(transacoes, currentUid);
    final startupIds = <String>{
      for (final ativo in ativos)
        if (ativo.quantidadeTotal > 0) ativo.startupId,
      ...estadosPorStartup.keys,
    };
    final rawPositions = startupIds
        .map((startupId) {
          return _buildRawPosition(
            ativo: ativosPorStartup[startupId],
            tradeState: estadosPorStartup[startupId],
            startupId: startupId,
          );
        })
        .where((position) {
          return position.quantity > 0 ||
              position.investedValueCents > 0 ||
              position.resultCents != 0;
        })
        .toList();

    final currentValueCents = rawPositions.fold<int>(
      0,
      (total, item) => total + item.currentValueCents,
    );
    final investedValueCents = rawPositions.fold<int>(
      0,
      (total, item) => total + item.investedValueCents,
    );
    final resultCents = rawPositions.fold<int>(
      0,
      (total, item) => total + item.resultCents,
    );
    final positions =
        rawPositions.map((position) {
          final allocationPercent = currentValueCents <= 0
              ? 0.0
              : (position.currentValueCents / currentValueCents) * 100;

          return DashboardPosition(
            startupId: position.startupId,
            startupName: position.startupName,
            quantity: position.quantity,
            averagePriceCents: position.averagePriceCents,
            currentPriceCents: position.currentPriceCents,
            investedValueCents: position.investedValueCents,
            currentValueCents: position.currentValueCents,
            resultCents: position.resultCents,
            resultPercent: position.resultPercent,
            allocationPercent: allocationPercent,
          );
        }).toList()..sort((first, second) {
          return second.currentValueCents.compareTo(first.currentValueCents);
        });

    return DashboardData(
      summary: PortfolioSummary(
        currentValueCents: currentValueCents,
        investedValueCents: investedValueCents,
        resultCents: resultCents,
        resultPercent: _percent(resultCents, investedValueCents),
      ),
      positions: positions,
      portfolioHistory: _buildPortfolioHistory(
        ativos: ativos.where((ativo) => ativo.quantidadeTotal > 0).toList(),
        periodStart: periodStart,
        now: now,
        currentValueCents: currentValueCents,
      ),
    );
  }

  static DashboardPosition _buildRawPosition({
    required AtivoModel? ativo,
    required _TradeState? tradeState,
    required String startupId,
  }) {
    final quantity = ativo?.quantidadeTotal ?? tradeState?.openQuantity ?? 0;
    final currentPricePreciseCents = ativo == null
        ? 0
        : _currentPricePrecise(ativo);
    final currentPriceCents = _preciseToDisplayCents(currentPricePreciseCents);
    final averagePricePreciseCents = _averagePricePrecise(ativo, tradeState);
    final averagePriceCents = _preciseToDisplayCents(averagePricePreciseCents);
    final openCostCents = _preciseTotalToCents(
      _openCostPrecise(ativo, tradeState),
    );
    final totalInvestedCents = _preciseTotalToCents(
      tradeState?.totalBoughtPreciseCents ?? 0,
    );
    final investedValueCents = totalInvestedCents > 0
        ? totalInvestedCents
        : openCostCents;
    final currentValueCents = _positionValueCents(
      quantity,
      currentPricePreciseCents,
    );
    final realizedResultCents = _preciseTotalToCents(
      tradeState?.realizedResultPreciseCents ?? 0,
    );
    final unrealizedResultCents = currentValueCents - openCostCents;
    final resultCents = realizedResultCents + unrealizedResultCents;

    return DashboardPosition(
      startupId: startupId,
      startupName: _startupName(ativo, tradeState, startupId),
      quantity: quantity,
      averagePriceCents: averagePriceCents,
      currentPriceCents: currentPriceCents,
      investedValueCents: investedValueCents,
      currentValueCents: currentValueCents,
      resultCents: resultCents,
      resultPercent: _percent(resultCents, investedValueCents),
      allocationPercent: 0,
    );
  }

  static List<DashboardLinePoint> _buildPortfolioHistory({
    required List<AtivoModel> ativos,
    required DateTime periodStart,
    required DateTime now,
    required int currentValueCents,
  }) {
    if (ativos.isEmpty) {
      return const [];
    }

    final dates = <DateTime>[
      for (final ativo in ativos)
        for (final point in ativo.historicoPrecos)
          if (!point.data.isBefore(periodStart) && !point.data.isAfter(now))
            point.data,
    ]..sort();

    final uniqueDates = _uniqueDates(dates);

    if (uniqueDates.isEmpty) {
      return [
        DashboardLinePoint(date: periodStart, valueCents: currentValueCents),
        DashboardLinePoint(date: now, valueCents: currentValueCents),
      ];
    }

    final points = <DashboardLinePoint>[];
    points.add(
      DashboardLinePoint(
        date: periodStart,
        valueCents: _portfolioValueAt(ativos, periodStart),
      ),
    );

    for (final date in uniqueDates) {
      points.add(
        DashboardLinePoint(
          date: date,
          valueCents: _portfolioValueAt(ativos, date),
        ),
      );
    }

    points.add(DashboardLinePoint(date: now, valueCents: currentValueCents));

    return _compactRepeatedDates(points);
  }

  static int _portfolioValueAt(List<AtivoModel> ativos, DateTime date) {
    return ativos.fold<int>(0, (total, ativo) {
      return total +
          _positionValueCents(
            ativo.quantidadeTotal,
            _pricePreciseAt(ativo, date),
          );
    });
  }

  static int _pricePreciseAt(AtivoModel ativo, DateTime date) {
    final history = [...ativo.historicoPrecos]
      ..sort((first, second) => first.data.compareTo(second.data));
    PricePoint? selected;

    for (final point in history) {
      if (point.data.isAfter(date)) {
        break;
      }

      if (point.precoCentavos > 0) {
        selected = point;
      }
    }

    if (selected != null) {
      return selected.precoPrecisoCentavos;
    }

    for (final point in history) {
      if (point.precoPrecisoCentavos > 0) {
        return point.precoPrecisoCentavos;
      }
    }

    return _currentPricePrecise(ativo);
  }

  static int _currentPricePrecise(AtivoModel ativo) {
    if (ativo.precoAtualPrecisoCentavos > 0) {
      return ativo.precoAtualPrecisoCentavos;
    }

    if (ativo.precoAtualCentavos > 0) {
      return ativo.precoAtualCentavos * pricePrecisionScale;
    }

    if (ativo.precoPrimarioPrecisoCentavos > 0) {
      return ativo.precoPrimarioPrecisoCentavos;
    }

    if (ativo.precoPrimarioCentavos > 0) {
      return ativo.precoPrimarioCentavos * pricePrecisionScale;
    }

    return ativo.valorMedioCentavos * pricePrecisionScale;
  }

  static int _averagePricePrecise(AtivoModel? ativo, _TradeState? tradeState) {
    if (tradeState != null && tradeState.openQuantity > 0) {
      return (tradeState.openCostPreciseCents / tradeState.openQuantity)
          .round();
    }

    if (ativo != null && ativo.valorMedioPrecisoCentavos > 0) {
      return ativo.valorMedioPrecisoCentavos;
    }

    return (ativo?.valorMedioCentavos ?? 0) * pricePrecisionScale;
  }

  static int _positionValueCents(int quantity, int pricePreciseCents) {
    return ((quantity * pricePreciseCents) / pricePrecisionScale).round();
  }

  static int _preciseTotalToCents(int preciseCents) {
    return (preciseCents / pricePrecisionScale).round();
  }

  static int _preciseToDisplayCents(int pricePreciseCents) {
    return (pricePreciseCents / pricePrecisionScale).round();
  }

  static int _openCostPrecise(AtivoModel? ativo, _TradeState? tradeState) {
    if (tradeState != null && tradeState.hasTrades) {
      return tradeState.openCostPreciseCents;
    }

    if (ativo == null) {
      return 0;
    }

    return ativo.quantidadeTotal * _averagePricePrecise(ativo, null);
  }

  static String _startupName(
    AtivoModel? ativo,
    _TradeState? tradeState,
    String startupId,
  ) {
    final ativoNome = ativo?.startupNome.trim() ?? '';
    if (ativoNome.isNotEmpty) {
      return ativoNome;
    }

    final transacaoNome = tradeState?.startupName.trim() ?? '';
    if (transacaoNome.isNotEmpty) {
      return transacaoNome;
    }

    return startupId;
  }

  static Map<String, _TradeState> _buildTradeStates(
    List<TransactionModel> transacoes,
    String currentUid,
  ) {
    final uid = currentUid.trim();
    if (uid.isEmpty || transacoes.isEmpty) {
      return {};
    }

    final states = <String, _TradeState>{};
    final sortedTransactions = [...transacoes]
      ..sort((first, second) => first.criadoEm.compareTo(second.criadoEm));

    for (final transacao in sortedTransactions) {
      final isBuy = transacao.compradorUid == uid;
      final isSell = transacao.vendedorUid == uid;

      if (isBuy == isSell) {
        continue;
      }

      final state = states.putIfAbsent(
        transacao.startupId,
        () => _TradeState(startupName: transacao.startupNome),
      );

      if (state.startupName.isEmpty && transacao.startupNome.isNotEmpty) {
        state.startupName = transacao.startupNome;
      }

      if (isBuy) {
        state.applyBuy(
          quantity: transacao.quantidade,
          totalPreciseCents: transacao.valorTotalPrecisoCentavos,
        );
      } else {
        state.applySell(
          quantity: transacao.quantidade,
          totalPreciseCents: transacao.valorTotalPrecisoCentavos,
        );
      }
    }

    return states;
  }

  static List<DateTime> _uniqueDates(List<DateTime> dates) {
    final seen = <int>{};
    final unique = <DateTime>[];

    for (final date in dates) {
      final key = date.millisecondsSinceEpoch;
      if (seen.add(key)) {
        unique.add(date);
      }
    }

    return unique;
  }

  static List<DashboardLinePoint> _compactRepeatedDates(
    List<DashboardLinePoint> points,
  ) {
    final compacted = <DashboardLinePoint>[];

    for (final point in points) {
      if (compacted.isNotEmpty &&
          compacted.last.date.millisecondsSinceEpoch ==
              point.date.millisecondsSinceEpoch) {
        compacted[compacted.length - 1] = point;
      } else {
        compacted.add(point);
      }
    }

    if (compacted.length == 1) {
      final only = compacted.first;
      return [
        only,
        DashboardLinePoint(
          date: only.date.add(const Duration(minutes: 1)),
          valueCents: only.valueCents,
        ),
      ];
    }

    return compacted;
  }

  static double _percent(int numerator, int denominator) {
    if (denominator <= 0) {
      return 0;
    }

    return (numerator / denominator) * 100;
  }
}

class _TradeState {
  String startupName;
  int openQuantity = 0;
  int openCostPreciseCents = 0;
  int totalBoughtPreciseCents = 0;
  int realizedResultPreciseCents = 0;
  bool hasTrades = false;

  _TradeState({required this.startupName});

  void applyBuy({required int quantity, required int totalPreciseCents}) {
    if (quantity <= 0 || totalPreciseCents <= 0) {
      return;
    }

    hasTrades = true;
    openQuantity += quantity;
    openCostPreciseCents += totalPreciseCents;
    totalBoughtPreciseCents += totalPreciseCents;
  }

  void applySell({required int quantity, required int totalPreciseCents}) {
    if (quantity <= 0 || totalPreciseCents <= 0) {
      return;
    }

    hasTrades = true;
    final quantityWithKnownCost = quantity > openQuantity
        ? openQuantity
        : quantity;
    final costRemoved = openQuantity <= 0
        ? 0
        : ((openCostPreciseCents * quantityWithKnownCost) / openQuantity)
              .round();

    realizedResultPreciseCents += totalPreciseCents - costRemoved;
    openQuantity -= quantityWithKnownCost;
    openCostPreciseCents -= costRemoved;

    if (openQuantity <= 0) {
      openQuantity = 0;
      openCostPreciseCents = 0;
    }
  }
}
