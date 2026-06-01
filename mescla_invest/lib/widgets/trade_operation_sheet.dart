// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

enum TradeOperationType { compra, venda }

class TradeOperationResult {
  final int quantidade;
  final double valorUnitario;

  const TradeOperationResult({
    required this.quantidade,
    required this.valorUnitario,
  });

  int get valorUnitarioCentavos => (valorUnitario * 100).round();
}

class TradeOperationSheet extends StatefulWidget {
  final TradeOperationType tipo;
  final String startupNome;
  final int precoReferenciaCentavos;
  final int? precoReferenciaPrecisoCentavos;
  final bool editarPreco;
  final int? precoMinimoCentavos;
  final int? precoMaximoCentavos;
  final int? tokensDisponiveis;

  const TradeOperationSheet({
    super.key,
    required this.tipo,
    required this.startupNome,
    required this.precoReferenciaCentavos,
    this.precoReferenciaPrecisoCentavos,
    required this.editarPreco,
    this.precoMinimoCentavos,
    this.precoMaximoCentavos,
    this.tokensDisponiveis,
  });

  @override
  State<TradeOperationSheet> createState() => _TradeOperationSheetState();
}

class _TradeOperationSheetState extends State<TradeOperationSheet> {
  final _quantidadeController = TextEditingController();
  final _precoController = TextEditingController();
  int _quantidade = 0;
  double? _precoEditado;

  bool get _isCompra => widget.tipo == TradeOperationType.compra;

  Color get _corAcao =>
      _isCompra ? const Color(0xFF138A5B) : const Color(0xFFC0394A);

  int get _precoUnitarioCentavos {
    if (!widget.editarPreco) {
      return widget.precoReferenciaCentavos;
    }

    return ((_precoEditado ?? 0) * 100).round();
  }

  int get _precoUnitarioPrecisoCentavos {
    if (widget.editarPreco) {
      return _precoUnitarioCentavos * pricePrecisionScale;
    }

    final precoPreciso = widget.precoReferenciaPrecisoCentavos ?? 0;
    if (precoPreciso > 0) {
      return precoPreciso;
    }

    return widget.precoReferenciaCentavos * pricePrecisionScale;
  }

  int get _totalPrecisoCentavos => _quantidade * _precoUnitarioPrecisoCentavos;

  int get _totalCentavos =>
      (_totalPrecisoCentavos / pricePrecisionScale).round();

  @override
  void initState() {
    super.initState();

    if (widget.editarPreco && widget.precoReferenciaCentavos > 0) {
      _precoEditado = widget.precoReferenciaCentavos / 100;
      _precoController.text = _formatarEntradaCentavos(
        widget.precoReferenciaCentavos,
      );
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            _titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(widget.startupNome, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          _buildResumo(
            'Preço de mercado',
            _formatarPrecisoCentavos(_precoUnitarioPrecisoCentavos),
          ),
          if (widget.editarPreco) ...[
            const SizedBox(height: 8),
            _buildFaixaPermitida(),
            const SizedBox(height: 14),
            _buildPrecoField(),
          ],
          const SizedBox(height: 14),
          if (widget.tokensDisponiveis != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.token_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCompra
                        ? 'Tokens disponíveis: '
                        : 'Seus tokens disponíveis: ',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${widget.tokensDisponiveis}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          _buildQuantidadeField(),
          const SizedBox(height: 16),
          _buildResumo(_totalLabel, _formatarCentavos(_totalCentavos)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _corAcao,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _corAcao.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_botaoTexto),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecoField() {
    return TextField(
      controller: _precoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      onChanged: (value) {
        setState(() => _precoEditado = _parseValor(value));
      },
      decoration: _inputDecoration(
        'Preço unitário da oferta (R\$)',
        'Ex: 10,50',
      ),
    );
  }

  Widget _buildQuantidadeField() {
    return TextField(
      controller: _quantidadeController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        setState(() => _quantidade = int.tryParse(value) ?? 0);
      },
      decoration: _inputDecoration('Quantidade de tokens', 'Ex: 100'),
    );
  }

  Widget _buildFaixaPermitida() {
    final min = widget.precoMinimoCentavos;
    final max = widget.precoMaximoCentavos;

    if (min == null || max == null) {
      return const SizedBox.shrink();
    }

    return Text(
      'Faixa permitida: ${_formatarCentavos(min)} a '
      '${_formatarCentavos(max)} por token.',
      style: TextStyle(color: AppColors.textHint, fontSize: 12),
    );
  }

  Widget _buildResumo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: TextStyle(color: AppColors.textHint)),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _submit() {
    if (_quantidade <= 0) {
      _mostrarErro('Informe uma quantidade valida.');
      return;
    }

    if (_precoUnitarioCentavos <= 0) {
      _mostrarErro('Informe um preço unitário válido.');
      return;
    }

    final tokensDisponiveis = widget.tokensDisponiveis;

    if (tokensDisponiveis != null && _quantidade > tokensDisponiveis) {
      _mostrarErro(
        _isCompra
            ? 'Quantidade maior que os tokens disponíveis.'
            : 'Quantidade maior que seus tokens disponíveis.',
      );
      return;
    }

    final min = widget.precoMinimoCentavos;
    final max = widget.precoMaximoCentavos;

    if (widget.editarPreco && min != null && _precoUnitarioCentavos < min) {
      _mostrarErro('Preço abaixo da faixa permitida.');
      return;
    }

    if (widget.editarPreco && max != null && _precoUnitarioCentavos > max) {
      _mostrarErro('Preço acima da faixa permitida.');
      return;
    }

    Navigator.pop(
      context,
      TradeOperationResult(
        quantidade: _quantidade,
        valorUnitario: _precoUnitarioCentavos / 100,
      ),
    );
  }

  void _mostrarErro(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  double? _parseValor(String text) {
    final value = text.trim().replaceAll(' ', '');

    if (value.isEmpty) return null;

    String normalized = value;
    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');

    if (hasComma && hasDot) {
      final lastComma = normalized.lastIndexOf(',');
      final lastDot = normalized.lastIndexOf('.');
      final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
      final integerPart = normalized
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[,.]'), '');
      final decimalPart = normalized
          .substring(decimalIndex + 1)
          .replaceAll(RegExp(r'[,.]'), '');

      normalized = '$integerPart.$decimalPart';
    } else if (hasComma) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      final dotCount = '.'.allMatches(normalized).length;

      if (dotCount > 1) {
        final lastDot = normalized.lastIndexOf('.');
        normalized =
            '${normalized.substring(0, lastDot).replaceAll('.', '')}.'
            '${normalized.substring(lastDot + 1)}';
      }
    }

    return double.tryParse(normalized);
  }

  String get _titulo {
    final operacao = _isCompra ? 'Compra' : 'Venda';
    return widget.editarPreco
        ? 'Oferta de ${operacao.toLowerCase()}'
        : '$operacao ao preço de mercado';
  }

  String get _botaoTexto {
    if (widget.editarPreco) {
      return 'Confirmar oferta';
    }

    return _isCompra ? 'Confirmar compra' : 'Confirmar venda';
  }

  String get _totalLabel {
    if (widget.editarPreco && _isCompra) {
      return 'Valor que sera bloqueado';
    }

    if (widget.editarPreco && !_isCompra) {
      return 'Valor estimado se executar';
    }

    return _isCompra ? 'Voce pagara agora' : 'Voce recebera agora';
  }

  String _formatarCentavos(int centavos) {
    final reais = centavos / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarPrecisoCentavos(int precisoCentavos) {
    final reais = precisoCentavos / (100 * pricePrecisionScale);
    return 'R\$ ${reais.toStringAsFixed(4).replaceAll('.', ',')}';
  }

  String _formatarEntradaCentavos(int centavos) {
    final reais = centavos / 100;
    return reais.toStringAsFixed(2).replaceAll('.', ',');
  }
}

const int pricePrecisionScale = 10000;
