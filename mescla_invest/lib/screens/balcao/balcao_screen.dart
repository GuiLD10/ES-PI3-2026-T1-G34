import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/balcao_service.dart';
import '../../core/services/startup_service.dart';
import '../../models/balcao_model.dart';
import '../../models/startup_model.dart';

class BalcaoScreen extends StatefulWidget {
  const BalcaoScreen({super.key});

  @override
  State<BalcaoScreen> createState() => _BalcaoScreenState();
}

class _BalcaoScreenState extends State<BalcaoScreen> {
  List<StartupModel> _startups = [];
  List<OfertaBalcaoModel> _minhasOfertas = [];
  List<TransacaoBalcaoModel> _transacoes = [];
  OrderBookBalcaoModel? _orderBook;
  StartupModel? _startupSelecionada;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _erro;
  String? _startupInicialId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _startupInicialId ??= ModalRoute.of(context)?.settings.arguments is String
        ? ModalRoute.of(context)?.settings.arguments as String
        : null;

    if (_startups.isEmpty && _isLoading) {
      _carregarDadosIniciais();
    }
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final startups = await StartupService.listarStartups();
      final selecionada = _selecionarStartupInicial(startups);

      if (!mounted) return;
      setState(() {
        _startups = startups;
        _startupSelecionada = selecionada;
        _isLoading = selecionada != null;
      });

      if (selecionada != null) {
        await _carregarBalcao(selecionada.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  StartupModel? _selecionarStartupInicial(List<StartupModel> startups) {
    if (startups.isEmpty) return null;

    final startupId = _startupInicialId;
    if (startupId == null || startupId.isEmpty) return startups.first;

    return startups.firstWhere(
      (startup) => startup.id == startupId,
      orElse: () => startups.first,
    );
  }

  Future<void> _carregarBalcao(String startupId) async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final results = await Future.wait([
        BalcaoService.buscarOrderBook(startupId),
        BalcaoService.listarMinhasOfertas(),
        BalcaoService.listarTransacoes(startupId),
      ]);

      if (!mounted) return;
      setState(() {
        _orderBook = results[0] as OrderBookBalcaoModel;
        _minhasOfertas = results[1] as List<OfertaBalcaoModel>;
        _transacoes = results[2] as List<TransacaoBalcaoModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarStartup(String? startupId) async {
    if (startupId == null) return;

    final startup = _startups.firstWhere((item) => item.id == startupId);
    setState(() => _startupSelecionada = startup);
    await _carregarBalcao(startup.id);
  }

  Future<void> _cancelarOferta(OfertaBalcaoModel oferta) async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      await BalcaoService.cancelarOferta(oferta.id);
      await _recarregarStartupAtual();
      _mostrarMensagem('Oferta cancelada com sucesso.', Colors.green);
    } catch (e) {
      _mostrarMensagem(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _recarregarStartupAtual() async {
    final startup = _startupSelecionada;
    if (startup != null) {
      await _carregarBalcao(startup.id);
    }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: AppColors.primary),
                tooltip: 'Voltar',
              ),
              Expanded(child: _buildStartupDropdown()),
              IconButton(
                onPressed: _recarregarStartupAtual,
                icon: Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Atualizar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildResumoPreco(),
        ],
      ),
    );
  }

  Widget _buildStartupDropdown() {
    if (_startups.isEmpty) {
      return Text(
        'Balcao',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _startupSelecionada?.id,
      isExpanded: true,
      decoration: const InputDecoration(border: InputBorder.none),
      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      items: _startups.map((startup) {
        return DropdownMenuItem(
          value: startup.id,
          child: Text(startup.nome, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _selecionarStartup,
    );
  }

  Widget _buildResumoPreco() {
    final orderBook = _orderBook;

    return Row(
      children: [
        Expanded(
          child: _buildResumoItem(
            label: 'Preco atual',
            value: orderBook == null
                ? '-'
                : _formatarCentavos(orderBook.precoAtualCentavos),
          ),
        ),
        Expanded(
          child: _buildResumoItem(
            label: 'Melhor compra',
            value: orderBook?.melhorCompra == null
                ? '-'
                : _formatarCentavos(
                    orderBook!.melhorCompra!.valorUnitarioCentavos,
                  ),
          ),
        ),
        Expanded(
          child: _buildResumoItem(
            label: 'Melhor venda',
            value: orderBook?.melhorVenda == null
                ? '-'
                : _formatarCentavos(
                    orderBook!.melhorVenda!.valorUnitarioCentavos,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return TabBar(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textHint,
      indicatorColor: AppColors.primary,
      tabs: const [
        Tab(text: 'Livro'),
        Tab(text: 'Minhas Ofertas'),
        Tab(text: 'Historico'),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_erro != null) {
      return _buildErro();
    }

    return TabBarView(
      children: [
        _buildOrderBookTab(),
        _buildMinhasOfertasTab(),
        _buildHistoricoTab(),
      ],
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDadosIniciais,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderBookTab() {
    final orderBook = _orderBook;

    if (orderBook == null) {
      return _buildEmpty('Nenhum livro de ofertas disponivel.');
    }

    return RefreshIndicator(
      onRefresh: _recarregarStartupAtual,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildBookHeader(),
          const SizedBox(height: 8),
          _buildBookRows(orderBook),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _abrirModalOferta('compra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF138A5B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Comprar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _abrirModalOferta('venda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0394A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Vender'),
          ),
        ),
      ],
    );
  }

  Widget _buildBookHeader() {
    return Row(
      children: [
        Expanded(child: _buildHeaderText('Qtd compra')),
        Expanded(child: _buildHeaderText('Compra')),
        Expanded(child: _buildHeaderText('Venda')),
        Expanded(child: _buildHeaderText('Qtd venda', alignRight: true)),
      ],
    );
  }

  Widget _buildHeaderText(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: AppColors.textHint,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBookRows(OrderBookBalcaoModel orderBook) {
    final total = orderBook.compras.length > orderBook.vendas.length
        ? orderBook.compras.length
        : orderBook.vendas.length;

    if (total == 0) {
      return _buildEmpty('Nenhuma oferta aberta para esta startup.');
    }

    return Column(
      children: List.generate(total, (index) {
        final compra = index < orderBook.compras.length
            ? orderBook.compras[index]
            : null;
        final venda = index < orderBook.vendas.length
            ? orderBook.vendas[index]
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: _bookText(compra?.quantidadeRestante)),
              Expanded(
                child: _bookPrice(compra?.valorUnitarioCentavos, Colors.green),
              ),
              Expanded(
                child: _bookPrice(venda?.valorUnitarioCentavos, Colors.red),
              ),
              Expanded(
                child: _bookText(venda?.quantidadeRestante, alignRight: true),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bookText(int? value, {bool alignRight = false}) {
    return Text(
      value == null ? '-' : value.toString(),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
    );
  }

  Widget _bookPrice(int? value, Color color) {
    return Text(
      value == null ? '-' : _formatarCentavos(value),
      style: TextStyle(
        color: value == null ? AppColors.textHint : color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMinhasOfertasTab() {
    if (_minhasOfertas.isEmpty) {
      return _buildEmpty('Voce ainda nao possui ofertas.');
    }

    return RefreshIndicator(
      onRefresh: _recarregarStartupAtual,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _minhasOfertas.length,
        itemBuilder: (context, index) {
          final oferta = _minhasOfertas[index];
          return _buildOfertaCard(oferta);
        },
      ),
    );
  }

  Widget _buildOfertaCard(OfertaBalcaoModel oferta) {
    final podeCancelar =
        oferta.status == 'aberta' || oferta.status == 'parcial';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${oferta.tipo.toUpperCase()} - ${oferta.status}',
                  style: TextStyle(
                    color: oferta.tipo == 'compra' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${oferta.quantidadeRestante}/'
                  '${oferta.quantidadeOriginal} tokens',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                Text(
                  _formatarCentavos(oferta.valorUnitarioCentavos),
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          if (podeCancelar)
            TextButton(
              onPressed: _isActionLoading
                  ? null
                  : () => _cancelarOferta(oferta),
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_transacoes.isEmpty) {
      return _buildEmpty('Nenhuma transacao registrada.');
    }

    return RefreshIndicator(
      onRefresh: _recarregarStartupAtual,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _transacoes.length,
        itemBuilder: (context, index) {
          final transacao = _transacoes[index];
          return _buildTransacaoCard(transacao);
        },
      ),
    );
  }

  Widget _buildTransacaoCard(TransacaoBalcaoModel transacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${transacao.quantidade} tokens',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatarCentavos(transacao.valorUnitarioCentavos),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
      ),
    );
  }

  void _abrirModalOferta(String tipo) {
    final startup = _startupSelecionada;
    if (startup == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _OfertaBottomSheet(
          tipo: tipo,
          startupNome: startup.nome,
          onSubmit: (quantidade, valorUnitario) async {
            return _criarOferta(tipo, quantidade, valorUnitario);
          },
        );
      },
    );
  }

  Future<bool> _criarOferta(
    String tipo,
    int quantidade,
    double valorUnitario,
  ) async {
    final startup = _startupSelecionada;
    if (startup == null || _isActionLoading) return false;

    setState(() => _isActionLoading = true);

    try {
      final resultado = await BalcaoService.criarOferta(
        startupId: startup.id,
        tipo: tipo,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
      );
      await _carregarBalcao(startup.id);
      _mostrarMensagem(
        'Oferta ${resultado.status}. Executados: '
        '${resultado.quantidadeExecutada}',
        Colors.green,
      );
      return true;
    } catch (e) {
      _mostrarMensagem(e.toString(), Colors.redAccent);
      return false;
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _formatarCentavos(int centavos) {
    final reais = centavos / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _OfertaBottomSheet extends StatefulWidget {
  final String tipo;
  final String startupNome;
  final Future<bool> Function(int quantidade, double valorUnitario) onSubmit;

  const _OfertaBottomSheet({
    required this.tipo,
    required this.startupNome,
    required this.onSubmit,
  });

  @override
  State<_OfertaBottomSheet> createState() => _OfertaBottomSheetState();
}

class _OfertaBottomSheetState extends State<_OfertaBottomSheet> {
  final _quantidadeController = TextEditingController();
  final _valorController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final quantidade = int.tryParse(_quantidadeController.text.trim());
    final valor = double.tryParse(
      _valorController.text.trim().replaceAll(',', '.'),
    );

    if (quantidade == null || quantidade <= 0 || valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe quantidade e preco validos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final sucesso = await widget.onSubmit(quantidade, valor);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (sucesso) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isCompra = widget.tipo == 'compra';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCompra ? 'Oferta de compra' : 'Oferta de venda',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(widget.startupNome, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          _buildField(_quantidadeController, 'Quantidade'),
          const SizedBox(height: 10),
          _buildField(_valorController, 'Preco unitario'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompra
                    ? const Color(0xFF138A5B)
                    : const Color(0xFFC0394A),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmar oferta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
