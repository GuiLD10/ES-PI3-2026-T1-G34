// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Tela de detalhes de uma startup do MesclaInvest

import 'package:flutter/material.dart';
import '../../core/services/session_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/startup_service.dart';
import '../../models/startup_model.dart';

class StartupDetailScreen extends StatefulWidget {
  const StartupDetailScreen({super.key});

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  StartupModel? _startup;
  bool _isLoading = true;
  String? _erro;
  String? _startupId;
  final TextEditingController _perguntaController = TextEditingController();

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
        _erro = 'Startup nao informada.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final startup = await StartupService.buscarStartupPorId(id);

      if (!mounted) return;
      setState(() {
        _startup = startup;
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

        questionType: 'publica',
      );

      // Limpa o campo
      _perguntaController.clear();

      // Atualiza os dados da startup
      await _carregarStartup(startupId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pergunta enviada com sucesso!'),
        ),
      );

    } on StartupServiceException catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    }
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
            'Startup nao encontrada.',
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
        _buildBalcaoButton(startup),
        const SizedBox(height: 16),
        _buildSecao(
          titulo: 'Descricao',
          child: Text(
            startup.descricao,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
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
            titulo: 'Video demonstrativo',
            child: Text(
              startup.videoDemo,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalcaoButton(StartupModel startup) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.balcao, arguments: startup.id);
        },
        icon: const Icon(Icons.show_chart_rounded, size: 18),
        label: const Text('Abrir balcao'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
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
        titulo: 'Estrutura societaria',
        child: _buildTextoVazio('Nenhum socio cadastrado.'),
      );
    }

    return _buildSecao(
      titulo: 'Estrutura societaria',
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
        child: _buildTextoVazio('Nenhuma pergunta publica cadastrada.'),
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
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
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

  String _formatarMoeda(int valor) {
    return 'R\$ ${_formatarNumero(valor)}';
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
