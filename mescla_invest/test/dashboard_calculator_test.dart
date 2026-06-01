// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Testes das metricas do dashboard de investimentos.

import 'package:flutter_test/flutter_test.dart';
import 'package:mescla_invest/core/utils/dashboard_calculator.dart';
import 'package:mescla_invest/models/ativo_model.dart';
import 'package:mescla_invest/models/transaction_model.dart'
    hide pricePrecisionScale;

void main() {
  test('calcula resumo e resultado por startup', () {
    final now = DateTime(2026, 5, 29, 12);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 10,
          valorMedioCentavos: 100,
          precoAtualCentavos: 120,
        ),
        _ativo(
          id: 'startup_002',
          nome: 'Startup B',
          quantidade: 5,
          valorMedioCentavos: 200,
          precoAtualCentavos: 100,
        ),
      ],
      periodStart: now.subtract(const Duration(days: 30)),
      now: now,
    );

    expect(data.summary.currentValueCents, 1700);
    expect(data.summary.investedValueCents, 2000);
    expect(data.summary.resultCents, -300);
    expect(data.summary.resultPercent, closeTo(-15, 0.01));

    final startupA = data.positions.firstWhere(
      (position) => position.startupId == 'startup_001',
    );
    expect(startupA.currentValueCents, 1200);
    expect(startupA.investedValueCents, 1000);
    expect(startupA.resultCents, 200);
    expect(startupA.resultPercent, closeTo(20, 0.01));
    expect(startupA.allocationPercent, closeTo(70.58, 0.01));
  });

  test('mantem linha estavel quando nao ha historico real no periodo', () {
    final now = DateTime(2026, 5, 29, 12);
    final periodStart = now.subtract(const Duration(days: 30));
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 10,
          valorMedioCentavos: 100,
          precoAtualCentavos: 120,
        ),
      ],
      periodStart: periodStart,
      now: now,
    );

    expect(data.portfolioHistory, hasLength(2));
    expect(data.portfolioHistory.first.date, periodStart);
    expect(data.portfolioHistory.first.valueCents, 1200);
    expect(data.portfolioHistory.last.date, now);
    expect(data.portfolioHistory.last.valueCents, 1200);
  });

  test('usa historico real de preco quando existem transacoes no periodo', () {
    final now = DateTime(2026, 5, 29, 12);
    final firstTradeDate = DateTime(2026, 5, 28, 13);
    final secondTradeDate = DateTime(2026, 5, 29, 9);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 10,
          valorMedioCentavos: 100,
          precoAtualCentavos: 125,
          historicoPrecos: [
            PricePoint(
              precoCentavos: 110,
              precoPrecisoCentavos: 110 * pricePrecisionScale,
              data: firstTradeDate,
            ),
            PricePoint(
              precoCentavos: 125,
              precoPrecisoCentavos: 125 * pricePrecisionScale,
              data: secondTradeDate,
            ),
          ],
        ),
      ],
      periodStart: now.subtract(const Duration(days: 1)),
      now: now,
    );

    expect(data.portfolioHistory, hasLength(4));
    expect(data.portfolioHistory[0].valueCents, 1100);
    expect(data.portfolioHistory[1].date, firstTradeDate);
    expect(data.portfolioHistory[1].valueCents, 1100);
    expect(data.portfolioHistory[2].date, secondTradeDate);
    expect(data.portfolioHistory[2].valueCents, 1250);
    expect(data.portfolioHistory[3].valueCents, 1250);
  });

  test('considera variacao menor que um centavo no valor da posicao', () {
    final now = DateTime(2026, 5, 29, 12);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 1000,
          valorMedioCentavos: 46,
          precoAtualCentavos: 46,
          precoAtualPrecisoCentavos: 461300,
        ),
      ],
      periodStart: now.subtract(const Duration(days: 1)),
      now: now,
    );

    expect(data.summary.investedValueCents, 46000);
    expect(data.summary.currentValueCents, 46130);
    expect(data.summary.resultCents, 130);
  });

  test('considera custo medio preciso no valor investido', () {
    final now = DateTime(2026, 5, 29, 12);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 1000,
          valorMedioCentavos: 46,
          valorMedioPrecisoCentavos: 462000,
          precoAtualCentavos: 46,
          precoAtualPrecisoCentavos: 461300,
        ),
      ],
      periodStart: now.subtract(const Duration(days: 1)),
      now: now,
    );

    expect(data.summary.investedValueCents, 46200);
    expect(data.summary.currentValueCents, 46130);
    expect(data.summary.resultCents, -70);
  });

  test('soma lucro realizado quando usuario vende tokens', () {
    final now = DateTime(2026, 5, 29, 12);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 0,
          valorMedioCentavos: 0,
          precoAtualCentavos: 46,
        ),
      ],
      transacoes: [
        _transacao(
          id: 't1',
          startupId: 'startup_001',
          startupNome: 'Startup A',
          compradorUid: 'usuario_1',
          vendedorUid: 'startup:startup_001',
          quantidade: 1000,
          totalCentavos: 46000,
          criadoEm: DateTime(2026, 5, 28, 10),
        ),
        _transacao(
          id: 't2',
          startupId: 'startup_001',
          startupNome: 'Startup A',
          compradorUid: 'usuario_2',
          vendedorUid: 'usuario_1',
          quantidade: 1000,
          totalCentavos: 92000,
          criadoEm: DateTime(2026, 5, 29, 10),
        ),
      ],
      currentUid: 'usuario_1',
      periodStart: now.subtract(const Duration(days: 7)),
      now: now,
    );

    expect(data.hasPositions, isTrue);
    expect(data.summary.currentValueCents, 0);
    expect(data.summary.investedValueCents, 46000);
    expect(data.summary.resultCents, 46000);
    expect(data.summary.resultPercent, closeTo(100, 0.01));

    final startup = data.positions.single;
    expect(startup.quantity, 0);
    expect(startup.resultCents, 46000);
  });

  test('calcula perda do comprador no balcao contra preco atual', () {
    final now = DateTime(2026, 5, 29, 12);
    final data = DashboardCalculator.calculate(
      ativos: [
        _ativo(
          id: 'startup_001',
          nome: 'Startup A',
          quantidade: 1000,
          valorMedioCentavos: 92,
          valorMedioPrecisoCentavos: 920000,
          precoAtualCentavos: 49,
          precoAtualPrecisoCentavos: 494000,
        ),
      ],
      transacoes: [
        _transacao(
          id: 't1',
          startupId: 'startup_001',
          startupNome: 'Startup A',
          compradorUid: 'usuario_2',
          vendedorUid: 'usuario_1',
          quantidade: 1000,
          totalCentavos: 92000,
          criadoEm: DateTime(2026, 5, 29, 10),
        ),
      ],
      currentUid: 'usuario_2',
      periodStart: now.subtract(const Duration(days: 7)),
      now: now,
    );

    expect(data.summary.currentValueCents, 49400);
    expect(data.summary.investedValueCents, 92000);
    expect(data.summary.resultCents, -42600);
  });
}

AtivoModel _ativo({
  required String id,
  required String nome,
  required int quantidade,
  required int valorMedioCentavos,
  required int precoAtualCentavos,
  int? valorMedioPrecisoCentavos,
  int? precoAtualPrecisoCentavos,
  List<PricePoint> historicoPrecos = const [],
}) {
  return AtivoModel(
    startupId: id,
    startupNome: nome,
    quantidadeDisponivel: quantidade,
    quantidadeBloqueada: 0,
    valorMedioCentavos: valorMedioCentavos,
    valorMedioPrecisoCentavos:
        valorMedioPrecisoCentavos ?? valorMedioCentavos * pricePrecisionScale,
    precoAtualCentavos: precoAtualCentavos,
    precoPrimarioCentavos: valorMedioCentavos,
    precoAtualPrecisoCentavos:
        precoAtualPrecisoCentavos ?? precoAtualCentavos * pricePrecisionScale,
    precoPrimarioPrecisoCentavos: valorMedioCentavos * pricePrecisionScale,
    historicoPrecos: historicoPrecos,
  );
}

TransactionModel _transacao({
  required String id,
  required String startupId,
  required String startupNome,
  required String compradorUid,
  required String vendedorUid,
  required int quantidade,
  required int totalCentavos,
  required DateTime criadoEm,
}) {
  final unitPriceCentavos = (totalCentavos / quantidade).round();

  return TransactionModel(
    id: id,
    startupId: startupId,
    startupNome: startupNome,
    compradorUid: compradorUid,
    vendedorUid: vendedorUid,
    ofertaCompraId: '',
    ofertaVendaId: '',
    mercado: 'secundario',
    quantidade: quantidade,
    valorUnitario: unitPriceCentavos / 100,
    valorTotal: totalCentavos / 100,
    valorUnitarioPrecisoCentavos: unitPriceCentavos * pricePrecisionScale,
    valorTotalPrecisoCentavos: totalCentavos * pricePrecisionScale,
    criadoEm: criadoEm,
  );
}
