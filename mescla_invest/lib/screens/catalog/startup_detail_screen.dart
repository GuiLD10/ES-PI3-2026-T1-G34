// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Tela de detalhes de uma startup do MesclaInvest

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/session_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/balcao_service.dart';
import '../../core/services/startup_service.dart';
import '../../core/services/wallet_service.dart';
import '../../models/startup_model.dart';
import '../../widgets/saldo_display.dart';
import '../../widgets/trade_operation_sheet.dart';

class StartupDetailScreen extends StatefulWidget {
  const StartupDetailScreen({super.key});

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  StartupModel? _startup;
  bool _isLoading = true;
  bool _isCompraMercadoLoading = false;
  bool _isVendaMercadoLoading = false;
  String? _erro;
  String? _startupId;
  final TextEditingController _perguntaController = TextEditingController();
  bool _isPrivateQuestion = false;
  bool _isInvestor = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final argument = ModalRoute.of(context)?.settings.arguments;
    final id = argument is String ? argument : '';

    if (_startupId == id) return;
    _startupId = id;
    _carregarStartup(id);
  }

  Future<void> _carregarStartup(String id) async {
    if (id.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _erro = 'Startup não informada.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final startup = await StartupService.buscarStartupPorId(id);

      final isInvestor = await StartupService.isUserInvestor(id);

      if (!mounted) return;
      setState(() {
        _startup = startup;
        _isInvestor = isInvestor;
        _isLoading = false;
      });
    } on StartupServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar detalhes da startup.';
        _isLoading = false;
      });
    }
  }

  // Responsavel por enviar pergunta para a startup
  Future<void> _enviarPergunta() async {
    final startupId = _startupId;

    if (startupId == null) {
      return;
    }

    try {
      await StartupService.criarPerguntaStartup(
        startupId: startupId,

        authorName: SessionManager.name.toString(),

        question: _perguntaController.text,

        questionType: _isPrivateQuestion ? 'privada' : 'publica',
      );

      // Limpa o campo
      _perguntaController.clear();

      // Atualiza os dados da startup
      await _carregarStartup(startupId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pergunta enviada com sucesso!')),
      );
    } on StartupServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _comprarAoPrecoMercado(StartupModel startup) async {
    if (_isCompraMercadoLoading) return;

    if (startup.tokensVendaDisponiveis <= 0) {
      _mostrarMensagem(
        'Nao ha tokens disponiveis para compra nesta startup.',
        Colors.redAccent,
      );
      return;
    }

    final resultadoOperacao = await showModalBottomSheet<TradeOperationResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return TradeOperationSheet(
          tipo: TradeOperationType.compra,
          startupNome: startup.nome,
          precoReferenciaCentavos: _precoMercadoCentavos(startup),
          precoReferenciaPrecisoCentavos: _precoMercadoPrecisoCentavos(startup),
          editarPreco: false,
          tokensDisponiveis: startup.tokensVendaDisponiveis,
        );
      },
    );

    if (resultadoOperacao == null || resultadoOperacao.quantidade <= 0) {
      return;
    }

    setState(() => _isCompraMercadoLoading = true);

    try {
      final resultado = await BalcaoService.comprarAoPrecoMercado(
        startupId: startup.id,
        quantidade: resultadoOperacao.quantidade,
      );
      await _carregarStartup(startup.id);

      if (!mounted) return;
      _mostrarMensagem(
        'Compra de ${resultado.quantidade} tokens realizada por '
        '${_formatarPrecisoCentavos(resultado.valorTotalPrecisoCentavos)}.',
        Colors.green,
      );
    } on BalcaoServiceException catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.message, Colors.redAccent);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao comprar tokens.', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isCompraMercadoLoading = false);
      }
    }
  }

  /// Busca a quantidade de tokens disponíveis do usuário para uma startup específica.
  Future<int?> _buscarTokensDisponiveis(String startupId) async {
    try {
      final uid = AuthService.currentUid;
      if (uid == null || uid.isEmpty) return null;

      final ativos = await WalletService.buscarPortfolio(uid);
      final ativo = ativos.where((a) => a.startupId == startupId).firstOrNull;
      return ativo?.quantidadeDisponivel;
    } catch (_) {
      return null;
    }
  }

  Future<void> _venderAoPrecoMercado(StartupModel startup) async {
    if (_isVendaMercadoLoading) return;

    final tokensDisponiveis = await _buscarTokensDisponiveis(startup.id);

    if (!mounted) return;

    final resultadoOperacao = await showModalBottomSheet<TradeOperationResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return TradeOperationSheet(
          tipo: TradeOperationType.venda,
          startupNome: startup.nome,
          precoReferenciaCentavos: _precoMercadoCentavos(startup),
          precoReferenciaPrecisoCentavos: _precoMercadoPrecisoCentavos(startup),
          editarPreco: false,
          tokensDisponiveis: tokensDisponiveis,
        );
      },
    );

    if (resultadoOperacao == null || resultadoOperacao.quantidade <= 0) {
      return;
    }

    setState(() => _isVendaMercadoLoading = true);

    try {
      final resultado = await BalcaoService.venderAoPrecoMercado(
        startupId: startup.id,
        quantidade: resultadoOperacao.quantidade,
      );
      await _carregarStartup(startup.id);

      if (!mounted) return;
      _mostrarMensagem(
        'Venda de ${resultado.quantidade} tokens realizada por '
        '${_formatarPrecisoCentavos(resultado.valorTotalPrecisoCentavos)}.',
        Colors.green,
      );
    } on BalcaoServiceException catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.message, Colors.redAccent);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao vender tokens.', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isVendaMercadoLoading = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem, Color cor) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final id = _startupId;
                  if (id != null) await _carregarStartup(id);
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                  child: _buildConteudo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 32, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/logo.png',
            width: 100,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const SaldoDisplay(),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_erro != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    final id = _startupId;
                    if (id != null) _carregarStartup(id);
                  },
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
              ),
            ],
          ),
        ),
      );
    }

    final startup = _startup;
    if (startup == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Text(
            'Startup não encontrada.',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResumo(startup),
        const SizedBox(height: 12),
        _buildAcoesStartup(startup),
        const SizedBox(height: 16),
        _buildSecao(
          titulo: 'Descrição',
          child: Text(
            startup.descricao,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        if (startup.sumarioExecutivo.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSecao(
            titulo: 'Sumário executivo',
            child: _buildTextoFormatado(startup.sumarioExecutivo),
          ),
        ],
        if (startup.planoDeNegocios.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSecao(
            titulo: 'Plano de negócios',
            child: _buildTextoFormatado(startup.planoDeNegocios),
          ),
        ],
        const SizedBox(height: 12),
        _buildSocios(startup.socios),
        const SizedBox(height: 12),
        _buildMentores(startup.mentoresConselho),
        const SizedBox(height: 12),
        _buildFormularioPergunta(),
        const SizedBox(height: 12),
        _buildPerguntas(startup.perguntasRespostas),
        if (startup.videoDemo.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSecao(
            titulo: 'Vídeo demonstrativo',
            child: GestureDetector(
              onTap: () async {
                final url = Uri.tryParse(startup.videoDemo);
                if (url != null) {
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    // URL inválida ou não pode ser aberta
                  }
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      startup.videoDemo,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcoesStartup(StartupModel startup) {
    final compraIndisponivel = startup.tokensVendaDisponiveis <= 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isCompraMercadoLoading || compraIndisponivel
                ? null
                : () => _comprarAoPrecoMercado(startup),
            icon: _isCompraMercadoLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: const Text('Comprar ao preço de mercado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF138A5B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF138A5B,
              ).withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isVendaMercadoLoading
                ? null
                : () => _venderAoPrecoMercado(startup),
            icon: _isVendaMercadoLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.remove_shopping_cart_rounded, size: 18),
            label: const Text('Vender ao preço de mercado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0394A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFFC0394A,
              ).withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.balcao,
                arguments: startup.id,
              );
            },
            icon: const Icon(Icons.show_chart_rounded, size: 18),
            label: const Text('Abrir balcão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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

  Widget _buildResumo(StartupModel startup) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  startup.nome,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildTag(startup.estagio),
            ],
          ),
          if (startup.setor.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              startup.setor,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetrica(
                  label: 'Capital aportado',
                  value: _formatarMoeda(startup.capitalAportado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetrica(
                  label: 'Tokens emitidos',
                  value: _formatarNumero(startup.tokensEmitidos),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetrica(
            label: 'Preco de mercado',
            value: _formatarPrecisoCentavos(
              _precoMercadoPrecisoCentavos(startup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 115),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetrica({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSecao({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSocios(List<SocioModel> socios) {
    if (socios.isEmpty) {
      return _buildSecao(
        titulo: 'Estrutura societária',
        child: _buildTextoVazio('Nenhum sócio cadastrado.'),
      );
    }

    return _buildSecao(
      titulo: 'Estrutura societária',
      child: Column(
        children: socios.map((socio) {
          return _buildLinhaInfo(
            titulo: socio.nome,
            subtitulo: '${socio.participacao}% de participacao',
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMentores(List<MentorConselhoModel> mentores) {
    if (mentores.isEmpty) {
      return _buildSecao(
        titulo: 'Mentores e conselho',
        child: _buildTextoVazio('Nenhum mentor ou conselheiro cadastrado.'),
      );
    }

    return _buildSecao(
      titulo: 'Mentores e conselho',
      child: Column(
        children: mentores.map((mentor) {
          return _buildLinhaInfo(titulo: mentor.nome, subtitulo: mentor.papel);
        }).toList(),
      ),
    );
  }

  Widget _buildPerguntas(List<PerguntaRespostaModel> perguntas) {
    if (perguntas.isEmpty) {
      return _buildSecao(
        titulo: 'Perguntas e respostas',
        child: _buildTextoVazio('Nenhuma pergunta pública cadastrada.'),
      );
    }

    return _buildSecao(
      titulo: 'Perguntas e respostas',
      child: Column(
        children: perguntas.map((item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PERGUNTA
                Text(
                  item.pergunta,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // RESPOSTAS
                if (item.respostas.isEmpty)
                  Text(
                    'Nenhuma resposta ainda.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),

                ...item.respostas.map((resposta) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOME
                        Text(
                          resposta.nome,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // RESPOSTA
                        Text(
                          resposta.resposta,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormularioPergunta() {
    return _buildSecao(
      titulo: 'Enviar pergunta',

      child: Column(
        children: [
          if (_isInvestor)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Public',
                    style: TextStyle(
                      color: !_isPrivateQuestion
                          ? AppColors.primary
                          : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isPrivateQuestion,
                    onChanged: (value) {
                      setState(() {
                        _isPrivateQuestion = value;
                      });
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                  Text(
                    'Private',
                    style: TextStyle(
                      color: _isPrivateQuestion
                          ? AppColors.primary
                          : AppColors.textHint,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Campo da pergunta
          TextField(
            controller: _perguntaController,

            maxLines: 4,

            decoration: const InputDecoration(
              hintText: 'Digite sua pergunta',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // Botao de envio
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: _enviarPergunta,

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),

              child: const Text('Enviar pergunta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaInfo({required String titulo, required String subtitulo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              subtitulo,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextoVazio(String texto) {
    return Text(
      texto,
      style: TextStyle(color: AppColors.textHint, fontSize: 13),
    );
  }

  /// Formata texto bruto do Firebase em widgets com títulos em negrito,
  /// bullets e parágrafos separados.
  /// Lida tanto com texto já separado por \n quanto com texto inline
  /// onde palavras-chave aparecem no meio da string.
  Widget _buildTextoFormatado(String texto) {
    // Palavras-chave que devem ser tratadas como títulos de seção
    final titulosConhecidos = [
      'Problema',
      'Solução',
      'Solucao',
      'Público-Alvo',
      'Publico-Alvo',
      'Diferenciais',
      'Modelo de Receita',
      'Recursos-Chave',
      'Parceiros-Chave',
      'Estratégia de Marketing',
      'Estrategia de Marketing',
    ];

    // Normaliza: insere \n antes de títulos conhecidos que apareçam inline
    String textoNormalizado = texto;
    for (final titulo in titulosConhecidos) {
      // Busca case-insensitive pelo título seguido opcionalmente de ':'
      final pattern = RegExp(
        r'(?<!\n)\s+(' + RegExp.escape(titulo) + r':?\s)',
        caseSensitive: false,
      );
      textoNormalizado = textoNormalizado.replaceAllMapped(pattern, (m) {
        return '\n${m.group(1)}';
      });
    }

    // Normaliza bullets inline: "- texto" precedido de espaço vira \n- texto
    textoNormalizado = textoNormalizado.replaceAllMapped(
      RegExp(r'(?<!\n)\s+- '),
      (m) => '\n- ',
    );

    final linhas = textoNormalizado.split('\n');
    final widgets = <Widget>[];

    // Set lowercase para checagem
    final titulosLower = titulosConhecidos
        .map((t) => t.toLowerCase())
        .toSet();

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i].trim();
      if (linha.isEmpty) continue;

      // Verifica se é um título conhecido (com ou sem ':')
      final linhaLower = linha.toLowerCase().replaceAll(':', '').trim();
      final ehTitulo = titulosLower.contains(linhaLower);

      if (ehTitulo) {
        // Adiciona espaçamento antes do título (exceto o primeiro widget)
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 14));
        }
        widgets.add(
          Text(
            linha.endsWith(':') ? linha : '$linha:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 4));
      } else if (linha.startsWith('- ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    linha.substring(2),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Parágrafo normal
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 6));
        }
        widgets.add(
          Text(
            linha,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _formatarMoeda(int valor) {
    return 'R\$ ${_formatarNumero(valor)}';
  }

  int _precoMercadoCentavos(StartupModel startup) {
    if (startup.precoAtualCentavos > 0) {
      return startup.precoAtualCentavos;
    }

    return startup.precoPrimarioCentavos;
  }

  int _precoMercadoPrecisoCentavos(StartupModel startup) {
    if (startup.precoAtualPrecisoCentavos > 0) {
      return startup.precoAtualPrecisoCentavos;
    }

    if (startup.precoAtualCentavos > 0) {
      return startup.precoAtualCentavos * pricePrecisionScale;
    }

    if (startup.precoPrimarioPrecisoCentavos > 0) {
      return startup.precoPrimarioPrecisoCentavos;
    }

    return startup.precoPrimarioCentavos * pricePrecisionScale;
  }

  String _formatarPrecisoCentavos(int precisoCentavos) {
    final reais = precisoCentavos / (100 * pricePrecisionScale);
    return 'R\$ ${reais.toStringAsFixed(4).replaceAll('.', ',')}';
  }

  String _formatarNumero(int valor) {
    final texto = valor.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < texto.length; i++) {
      final posicaoRestante = texto.length - i;
      buffer.write(texto[i]);

      if (posicaoRestante > 1 && posicaoRestante % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    super.dispose();
  }
}

const int pricePrecisionScale = 10000;
