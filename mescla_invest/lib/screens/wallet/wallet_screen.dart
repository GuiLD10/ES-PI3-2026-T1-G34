// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Tela de Carteira do Investidor do MesclaInvest

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/session_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/wallet_service.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? _carteira;
  List<TransactionModel> _transacoes = [];
  bool _isLoading = true;
  String? _erro;

  // Adicionar saldo
  final TextEditingController _valorController = TextEditingController();
  bool _mostrandoQrCode = false;
  int _segundosRestantes = 0;
  Timer? _timer;
  bool _adicionandoSaldo = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final uid = SessionManager.uid;

      print('[WalletScreen] UID do usuário: $uid');

      if (uid == null || uid.isEmpty) {
        throw WalletServiceException('Usuário não autenticado.');
      }

      print('[WalletScreen] Carregando carteira e transações...');
      final carteira = await WalletService.buscarCarteira(uid);
      final transacoes = await WalletService.buscarTransacoes(uid);

      print('[WalletScreen] Carteira: ${carteira.patrimonioTotal}');
      print('[WalletScreen] Transações: ${transacoes.length}');

      if (!mounted) return;
      setState(() {
        _carteira = carteira;
        _transacoes = transacoes;
        _isLoading = false;
      });
    } on WalletServiceException catch (e) {
      print('❌ [WalletScreen] Erro: ${e.message}');
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ [WalletScreen] Erro desconhecido: $e');
      print('❌ [WalletScreen] Stack: $stackTrace');
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar carteira.';
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarSaldo() async {
    final texto = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insira um valor válido maior que zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = SessionManager.uid;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar QR Code com timer de 10 segundos
    setState(() {
      _mostrandoQrCode = true;
      _segundosRestantes = 10;
      _adicionandoSaldo = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _segundosRestantes--;
      });

      if (_segundosRestantes <= 0) {
        timer.cancel();
        _finalizarAdicaoSaldo(uid, valor);
      }
    });
  }

  Future<void> _finalizarAdicaoSaldo(String uid, double valor) async {
    try {
      await WalletService.adicionarSaldo(uid, valor);

      if (!mounted) return;

      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
        _valorController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo de ${_formatarReais(valor)} adicionado com sucesso!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // Recarregar dados para atualizar o saldo na tela
      await _carregarDados();
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mostrandoQrCode = false;
        _adicionandoSaldo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao adicionar saldo. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.catalog);
        break;
      case 1:
        // já está na carteira
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
            label: 'Catálogo',
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

            // Header: logo + avatar
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

            // Título
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

            // Conteúdo
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
        // Card de saldo
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
                'Patrimônio Total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
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
                        'Disponível',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
                          color: Colors.white.withOpacity(0.8),
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

        // Seção: Adicionar Saldo
        _buildAdicionarSaldo(),

        const SizedBox(height: 24),

        // Placeholder gráfico — próximo escopo
        Container(
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
                'Gráfico de Valorização',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Em breve',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Histórico de transações
        Text(
          'Histórico de Transações',
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
                'Nenhuma transação realizada.',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionar Saldo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Se estiver mostrando o QR Code
          if (_mostrandoQrCode) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    'Escaneie o QR Code para pagar',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/qr_code.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Timer circular
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: _segundosRestantes / 10,
                          strokeWidth: 3,
                          color: AppColors.primary,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Processando em $_segundosRestantes segundos...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Campo de valor e botão
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: InputDecoration(
                hintText: 'Ex: 100,00',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _adicionandoSaldo ? null : _adicionarSaldo,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Adicionar saldo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransacaoCard(TransactionModel transacao) {
    final uid = SessionManager.uid ?? '';
    final isCompra = transacao.compradorUid == uid;
    final tipo = isCompra ? 'Compra' : 'Venda';
    final corTipo = isCompra ? Colors.green.shade700 : Colors.red.shade700;

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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              Text(
                transacao.startupId,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
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
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}