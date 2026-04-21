// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tela de Catálogo de Startups do MesclaInvest

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/startup_model.dart';
import '../../widgets/startup_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _buscaController = TextEditingController();

  // Lista vazia — será preenchida com dados do Firebase na integração
  final List<StartupModel> _todasStartups = [];

  // Filtros de estágio
  final Map<String, bool> _filtros = {
    'Nova': false,
    'Em operação': false,
    'Em expansão': false,
  };

  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Retorna startups filtradas por busca e estágio
  List<StartupModel> get _startupsFiltradas {
    final filtrosAtivos =
        _filtros.entries.where((e) => e.value).map((e) => e.key).toList();

    return _todasStartups.where((s) {
      final buscaOk =
          _busca.isEmpty || s.nome.toLowerCase().contains(_busca.toLowerCase());
      final estagioOk =
          filtrosAtivos.isEmpty || filtrosAtivos.contains(s.estagio);
      return buscaOk && estagioOk;
    }).toList();
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

            // Header: logo + ícone de perfil na mesma linha
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
                    onTap: () => Navigator.pushNamed(context, '/profile'),
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    // TODO: substituir [usuário] pelo nome real do usuário logado
                    Text(
                      'Bem-vindo, [usuário]',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Barra de busca
                    TextField(
                      controller: _buscaController,
                      onChanged: (v) => setState(() => _busca = v),
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar Startup',
                        hintStyle: TextStyle(
                            color: AppColors.textHint, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: Icon(Icons.search,
                            color: AppColors.primary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filtros por estágio
                    Text(
                      'Filtro por estágio:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _filtros.keys.map((estagio) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _filtros[estagio],
                                onChanged: (v) => setState(
                                    () => _filtros[estagio] = v ?? false),
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
                            const SizedBox(width: 12),
                          ],
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Label lista
                    Text(
                      'Startups',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Lista de startups — vazia até integração com Firebase
                    if (_startupsFiltradas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'Nenhuma startup disponível.',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._startupsFiltradas.map((startup) {
                        return StartupCard(
                          startup: startup,
                          onVerDetalhes: () {
                            // TODO: passar o id da startup para a tela de detalhe
                            Navigator.pushNamed(context, '/startup-detail');
                          },
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}