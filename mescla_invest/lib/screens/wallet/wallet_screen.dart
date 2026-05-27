// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Tela de Carteira do Investidor do MesclaInvest

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/wallet_service.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../models/ativo_model.dart';
import '../../widgets/token_valorizacao_chart.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? _carteira;
  List<TransactionModel> _transacoes = [];
  List<AtivoModel> _ativos = [];
  bool _isLoading = true;
  String? _erro;
  String? _portfolioErro;
  final TextEditingController _valorController = TextEditingController();
  Timer? _saldoTimer;
  bool _mostrandoQrCode = false;
  bool _adicionandoSaldo = false;
  int _segundosRestantes = 0;

  static const int _tempoConfirmacaoSaldoSegundos = 10;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _saldoTimer?.cancel();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _erro = null;
      _portfolioErro = null;
    });

    try {
      final uid = AuthService.currentUid;
      if (uid == null || uid.isEmpty) {
        throw WalletServiceException('Usuario nao autenticado.');
      }

      final carteira = await WalletService.buscarCarteira(uid);
      final transacoes = await WalletService.buscarTransacoes(uid);

      List<AtivoModel> ativos = [];
      String? portfolioErro;
      try {
        ativos = await WalletService.buscarPortfolio(uid);
      } on WalletServiceException catch (e) {
        portfolioErro = e.message;
      } catch (_) {
        portfolioErro = 'Erro ao carregar ativos da carteira.';
      }

      if (!mounted) return;
      setState(() {
        _carteira = carteira;
        _transacoes = transacoes;
        _ativos = ativos;
        _portfolioErro = portfolioErro;
        _isLoading = false;
      });
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar carteira.';
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarSaldo() async {
    if (_adicionandoSaldo) return;

    final valor = _parseValorReais(_valorController.text);
    if (valor == null) {
      _mostrarMensagem('Informe um valor valido maior que zero.', Colors.red);
      return;
    }

    final uid = AuthService.currentUid;
    if (uid == null || uid.isEmpty) {
      _mostrarMensagem('Usuario nao autenticado.', Colors.red);
      return;
    }

    _saldoTimer?.cancel();
    setState(() {
      _mostrandoQrCode = true;
      _adicionandoSaldo = true;
      _segundosRestantes = _tempoConfirmacaoSaldoSegundos;
    });

    _saldoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final segundos = _segundosRestantes - 1;
      setState(() => _segundosRestantes = segundos);

      if (segundos <= 0) {
        timer.cancel();
        _finalizarAdicaoSaldo(valor);
      }
    });
  }

  Future<void> _finalizarAdicaoSaldo(double valor) async {
    try {
      await WalletService.adicionarSaldo(valor);

      if (!mounted) return;
      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
        _valorController.clear();
      });

      _mostrarMensagem(
        'Saldo de ${_formatarReais(valor)} adicionado com sucesso.',
        Colors.green,
      );
      await _carregarDados();
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
      });
      _mostrarMensagem(e.message, Colors.red);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
      });
      _mostrarMensagem('Erro ao adicionar saldo.', Colors.red);
    }
  }

  double? _parseValorReais(String text) {
    var normalized = text.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (normalized.isEmpty) return null;

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    final valor = double.tryParse(normalized);
    if (valor == null || valor <= 0) return null;

    return valor;
  }

  void _mostrarMensagem(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.catalog);
        break;
      case 1:
        break;
    }
  }

  String _formatarReais(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Catalogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Carteira',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Carteira do Investidor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregarDados,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : _erro != null
                      ? _buildErro()
                      : _buildConteudo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    final carteira = _carteira!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patrimonio Total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatarReais(carteira.patrimonioTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponivel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatarReais(carteira.saldoDisponivel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bloqueado',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatarReais(carteira.saldoBloqueado),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildAdicionarSaldo(),
        const SizedBox(height: 24),
        if (_portfolioErro != null) ...[
          _buildPortfolioErro(_portfolioErro!),
          const SizedBox(height: 12),
        ],
        TokenValorizacaoChart(ativos: _ativos),
        const SizedBox(height: 24),
        Text(
          'Historico de Transacoes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_transacoes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Nenhuma transacao realizada.',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
            ),
          )
        else
          ..._transacoes.map((t) => _buildTransacaoCard(t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdicionarSaldo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _mostrandoQrCode
          ? _buildQrCodeSaldo()
          : _buildFormularioAdicionarSaldo(),
    );
  }

  Widget _buildPortfolioErro(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        mensagem,
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
      ),
    );
  }

  Widget _buildFormularioAdicionarSaldo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adicionar Saldo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _valorController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
          ],
          decoration: InputDecoration(
            hintText: 'Ex: 100,00',
            prefixText: 'R\$ ',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _adicionandoSaldo ? null : _adicionarSaldo,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Adicionar saldo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeSaldo() {
    return Column(
      children: [
        Text(
          'Escaneie o QR Code para pagar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/images/qr_code.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: _segundosRestantes / _tempoConfirmacaoSaldoSegundos,
                strokeWidth: 3,
                color: AppColors.primary,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Processando em $_segundosRestantes segundos...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransacaoCard(TransactionModel transacao) {
    final uid = AuthService.currentUid ?? '';
    final isCompra = transacao.compradorUid == uid;
    final tipo = isCompra ? 'Compra' : 'Venda';
    final corTipo = isCompra ? Colors.green.shade700 : Colors.red.shade700;
    final startupLabel = transacao.startupNome.isNotEmpty
        ? transacao.startupNome
        : transacao.startupId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tipo,
                style: TextStyle(
                  color: corTipo,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transacao.quantidade} tokens',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              Text(
                startupLabel,
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatarReais(transacao.valorTotal),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${transacao.criadoEm.day.toString().padLeft(2, '0')}/'
                '${transacao.criadoEm.month.toString().padLeft(2, '0')}/'
                '${transacao.criadoEm.year}',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
