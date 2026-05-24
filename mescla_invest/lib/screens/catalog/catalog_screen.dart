// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Tela de Catalogo de Startups do MesclaInvest

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/startup_service.dart';
import '../../models/startup_model.dart';
import '../../widgets/startup_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _buscaController = TextEditingController();

  List<StartupModel> _todasStartups = [];
  bool _isLoading = true;
  String? _erro;

  final Map<String, bool> _filtros = {
    'Nova': false,
    'Em operacao': false,
    'Em expansao': false,
  };

  String _busca = '';

  // Índice da aba selecionada na navbar: 0 = Catálogo, 1 = Carteira, 2 = Configurações
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarStartups();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarStartups() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final startups = await StartupService.listarStartups();

      if (!mounted) return;
      setState(() {
        _todasStartups = startups;
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
        _erro = 'Erro ao carregar startups.';
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);

    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.wallet);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
    }
  }

  List<StartupModel> get _startupsFiltradas {
    final filtrosAtivos =
        _filtros.entries.where((e) => e.value).map((e) => e.key).toList();
    final buscaNormalizada = _normalizarTexto(_busca);

    return _todasStartups.where((startup) {
      final buscaOk =
          buscaNormalizada.isEmpty ||
          _normalizarTexto(startup.nome).contains(buscaNormalizada) ||
          _normalizarTexto(startup.descricao).contains(buscaNormalizada) ||
          _normalizarTexto(startup.setor).contains(buscaNormalizada);
      final estagioOk =
          filtrosAtivos.isEmpty ||
          filtrosAtivos
              .map(_normalizarTexto)
              .contains(_normalizarTexto(startup.estagio));

      return buscaOk && estagioOk;
    }).toList();
  }

  String _normalizarTexto(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('à', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregarStartups,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSaudacao(),
                      const SizedBox(height: 12),
                      _buildBusca(),
                      const SizedBox(height: 12),
                      _buildFiltros(),
                      const SizedBox(height: 12),
                      _buildTituloLista(),
                      const SizedBox(height: 8),
                      _buildConteudoLista(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Navbar inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 100,
            fit: BoxFit.contain,
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaudacao() {
    return Text(
      'Bem-vindo, usuario',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBusca() {
    return TextField(
      controller: _buscaController,
      onChanged: (v) => setState(() => _busca = v),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar startup',
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtro por estagio:',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: _filtros.keys.map((estagio) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _filtros[estagio],
                    onChanged: (v) =>
                        setState(() => _filtros[estagio] = v ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  estagio,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTituloLista() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Startups',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!_isLoading && _erro == null)
          Text(
            '${_startupsFiltradas.length} encontradas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildConteudoLista() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
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
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Column(
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _carregarStartups,
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

    if (_startupsFiltradas.isEmpty) {
      final mensagem = _todasStartups.isEmpty
          ? 'Nenhuma startup disponivel.'
          : 'Nenhuma startup encontrada para os filtros selecionados.';

      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _startupsFiltradas.map((startup) {
        return StartupCard(
          startup: startup,
          onVerDetalhes: () {
            Navigator.pushNamed(
              context,
              AppRoutes.startupDetail,
              arguments: startup.id,
            );
          },
        );
      }).toList(),
    );
  }
}