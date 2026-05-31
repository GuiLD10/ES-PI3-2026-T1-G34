// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Testes basicos de conversao dos modelos usados pelo app.

import 'package:flutter_test/flutter_test.dart';
import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/models/startup_model.dart';
import 'package:mescla_invest/models/wallet_model.dart';

void main() {
  test('converte startup com socios, mentores e perguntas publicas', () {
    final startup = StartupModel.fromJson({
      'id': 'startup_001',
      'nome': 'MesclaPay',
      'descricao': 'Pagamentos simulados para startups.',
      'setor': 'Fintech',
      'estagio': 'Em operacao',
      'status': 'ativa',
      'capital_aportado': '150000',
      'tokens_emitidos': 10000,
      'preco_atual_centavos': 1250,
      'preco_primario_centavos': 1000,
      'preco_atual_preciso_centavos': 12500000,
      'preco_primario_preciso_centavos': 10000000,
      'video_demo': 'https://example.com/demo',
      'sumario_executivo': 'Resumo publico.',
      'plano_de_negocios': 'Plano publico.',
      'socios': [
        {'nome': 'Rafael', 'participacao': '60'},
        {'nome': 'Bruna', 'participacao': 40},
      ],
      'mentores_conselho': [
        {'nome': 'Mentor A', 'papel': 'Mentor'},
      ],
      'perguntas_respostas': [
        {
          'pergunta': 'Qual o mercado alvo?',
          'autor': 'Investidor',
          'resposta': [
            {
              'nome_autor': 'Fundador',
              'resposta': 'Universidades.',
            },
          ],
        },
      ],
    });

    expect(startup.id, 'startup_001');
    expect(startup.nome, 'MesclaPay');
    expect(startup.capitalAportado, 150000);
    expect(startup.tokensEmitidos, 10000);
    expect(startup.socios, hasLength(2));
    expect(startup.socios.first.participacao, 60);
    expect(startup.mentoresConselho.single.papel, 'Mentor');
    expect(startup.perguntasRespostas.single.respostas.single.resposta,
        'Universidades.');
  });

  test('converte carteira em centavos e calcula patrimonio total', () {
    final wallet = WalletModel.fromMap('usuario_001', {
      'saldo_disponivel_centavos': '12550',
      'saldo_bloqueado_centavos': 2500,
    });

    expect(wallet.uid, 'usuario_001');
    expect(wallet.saldoDisponivelCentavos, 12550);
    expect(wallet.saldoDisponivel, 125.50);
    expect(wallet.saldoBloqueadoCentavos, 2500);
    expect(wallet.saldoBloqueado, 25);
    expect(wallet.patrimonioTotal, 150.50);
  });

  test('converte order book do balcao com melhores ofertas', () {
    final orderBook = OrderBookBalcaoModel.fromJson({
      'startup_id': 'startup_001',
      'preco_atual_centavos': 1200,
      'melhor_compra': {
        'oferta_id': 'compra_001',
        'tipo': 'compra',
        'usuario_uid': 'usuario_001',
        'startup_id': 'startup_001',
        'quantidade_original': 10,
        'quantidade_restante': 4,
        'valor_unitario_centavos': 1100,
        'status': 'aberta',
      },
      'melhor_venda': {
        'oferta_id': 'venda_001',
        'tipo': 'venda',
        'usuario_uid': 'usuario_002',
        'startup_id': 'startup_001',
        'quantidade_original': 8,
        'quantidade_restante': 8,
        'valor_unitario_centavos': 1300,
        'status': 'aberta',
      },
      'compras': [],
      'vendas': [],
    });

    expect(orderBook.startupId, 'startup_001');
    expect(orderBook.precoAtualCentavos, 1200);
    expect(orderBook.melhorCompra?.id, 'compra_001');
    expect(orderBook.melhorCompra?.quantidadeRestante, 4);
    expect(orderBook.melhorVenda?.id, 'venda_001');
    expect(orderBook.compras, isEmpty);
    expect(orderBook.vendas, isEmpty);
  });
}
