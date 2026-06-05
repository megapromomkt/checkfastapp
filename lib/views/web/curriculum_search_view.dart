import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'dart:convert';
import '../../core/constants/premium_theme.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import '../../models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard_view.dart';

class CurriculumSearchView extends StatefulWidget {
  const CurriculumSearchView({super.key});

  @override
  State<CurriculumSearchView> createState() => _CurriculumSearchViewState();
}

class _CurriculumSearchViewState extends State<CurriculumSearchView> {
  final _api = RegisterService();
  bool _loading = true;
  List<AppUser> _promoters = [];
  List<AppDemand> _activeDemands = [];
  
  // Selected Job for Matching
  AppDemand? _selectedDemand;
  
  // Custom filter states
  bool _isFiltersExpanded = true;
  String _searchQuery = '';
  late final TextEditingController _searchQueryCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _redeCtrl;
  String _filterRole = 'Todos';
  String _filterCity = 'Todas';
  String _filterContract = 'Qualquer';
  bool _filterHasVehicle = false;
  String _filterCnh = 'Todos';
  double _minScore = 0.0;
  String _filterBrand = '';
  String _filterRede = '';
  late final ScrollController _mainScrollController;

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];
    if (_selectedDemand != null) {
      chips.add(_buildFilterChip('Vaga: ${_selectedDemand!.role}'));
    }
    if (_searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip('Busca: $_searchQuery'));
    }
    if (_filterRole != 'Todos') {
      chips.add(_buildFilterChip('Função: $_filterRole'));
    }
    if (_filterCity != 'Todas') {
      chips.add(_buildFilterChip('Cidade: $_filterCity'));
    }
    if (_filterContract != 'Qualquer') {
      chips.add(_buildFilterChip('Contrato: $_filterContract'));
    }
    if (_filterCnh != 'Todos') {
      chips.add(_buildFilterChip('CNH: $_filterCnh'));
    }
    if (_filterHasVehicle) {
      chips.add(_buildFilterChip('Veículo próprio'));
    }
    if (_minScore > 0.0) {
      chips.add(_buildFilterChip('Score min: ${_minScore.toStringAsFixed(1)}'));
    }
    if (_filterBrand.isNotEmpty) {
      chips.add(_buildFilterChip('Marca: $_filterBrand'));
    }
    if (_filterRede.isNotEmpty) {
      chips.add(_buildFilterChip('Rede: $_filterRede'));
    }
    return chips;
  }

  Widget _buildFilterChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchQueryCtrl = TextEditingController(text: _searchQuery);
    _searchQueryCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchQueryCtrl.text;
      });
    });
    _brandCtrl = TextEditingController(text: _filterBrand);
    _brandCtrl.addListener(() {
      setState(() {
        _filterBrand = _brandCtrl.text;
      });
    });
    _redeCtrl = TextEditingController(text: _filterRede);
    _redeCtrl.addListener(() {
      setState(() {
        _filterRede = _redeCtrl.text;
      });
    });
    _mainScrollController = ScrollController();
    _loadData();
  }

  @override
  void dispose() {
    _searchQueryCtrl.dispose();
    _brandCtrl.dispose();
    _redeCtrl.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load all users & demands
      final allUsers = await _api.getUsers();
      final allDemands = await _api.getDemands();
      
      // Filter only users of type 'prestador' or containing promoter profile
      final filteredPromoters = allUsers.where((u) => u.type == 'prestador' || u.role.toLowerCase() == 'worker' || u.curriculumResumo != null).toList();
      
      // Build dummy profiles if list is empty or small, to guarantee excellent display
      if (filteredPromoters.isEmpty || filteredPromoters.length < 3) {
        final mockPromoters = _generateMockPromoters();
        // Merge them, avoiding duplicate IDs/CPFs
        for (var mock in mockPromoters) {
          if (!filteredPromoters.any((p) => p.id == mock.id)) {
            filteredPromoters.add(mock);
          }
        }
      }

      setState(() {
        _promoters = filteredPromoters;
        _activeDemands = allDemands.where((d) => d.status == 'ABERTAS').toList();
        _loading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados de curriculos: $e');
      setState(() => _loading = false);
    }
  }

  List<AppUser> _generateMockPromoters() {
    return [
      AppUser(
        id: '43221002874', // Thabata Reco CPF
        name: 'Thabata Reco',
        email: 'thabata.reco@gmail.com',
        role: 'Promotora de Vendas',
        status: 'Ativo',
        type: 'prestador',
        curriculumResumo: 'Promotora de Vendas dedicada, com sólida experiência em merchandising, abastecimento de gôndolas, layout e precificação. Foco em resultados de vendas e manutenção de padrões de qualidade nas lojas.',
        curriculumExperiencias: 'Promotora de Vendas - Atacadão (1 ano)\n• Reposição e organização de gôndolas\n• Controle de validade (FIFO)\n• Precificação e ativação de material de merchandising.\n\nPromotora de Vendas - Assaí (6 meses)\n• Atendimento ao cliente e suporte no ponto de venda\n• Organização de estoque e contagem de inventário.',
        curriculumEscolaridade: 'Ensino Médio Completo',
        curriculumAttachedPdf: 'Curriculo_Thabata_Reco.pdf',
        curriculumCompletoDados: jsonEncode({
          'dados_pessoais': {
            'nome_social': 'Thabata Reco',
            'rg': '48.912.345-X',
            'orgao_emissor': 'SSP/SP',
            'data_nascimento': '25/08/1996',
            'idade': '29 anos',
            'sexo': 'Feminino',
            'estado_civil': 'Solteira',
            'nacionalidade': 'Brasileira',
            'naturalidade': 'São Paulo - SP',
            'whatsapp': '(11) 93066-6101',
            'linkedin': 'linkedin.com/in/thabatareco',
            'instagram': '@thabata_merchandising',
            'rua': 'Av. Nova Cantareira, 1500',
            'bairro': 'Guapira',
            'cidade': 'São Paulo',
            'estado': 'SP',
            'cep': '02263-001',
          },
          'documentacao': {
            'cnh': '05987123456',
            'cnh_categoria': 'B',
            'cnh_validade': '20/12/2029',
            'veiculo_proprio': true,
            'carro': true,
            'moto': false,
            'mei': true,
            'cnpj': '33.456.789/0001-22',
            'pis': '123.45678.90-1',
            'titulo_eleitor': '123456780123',
            'reservista': 'Não se aplica',
            'conta_bancaria': 'Banco Itaú - Ag 0150 CC 48950-2',
            'chave_pix': 'thabata.reco@gmail.com',
          },
          'disponibilidade': {
            'horarios': 'Período Integral',
            'finais_semana': true,
            'viagens': true,
            'pernoite': false,
            'acoes_temporarias': true,
            'clt': true,
            'pj': true,
            'freelancer': true,
            'imediata': true,
            'regiao': 'Zona Norte e Centro',
            'raio': 25.0,
            'PDV': true,
            'Eventos': true,
            'Sampling': true,
            'Degustação': true,
            'Auditoria': true,
            'Merchandising': true,
          },
          'dados_profissionais': {
            'objetivo': 'Atuar como promotora de trade marketing em grandes redes de varejo alimentar e farma.',
            'cargo_atual': 'Promotora de Vendas Freelancer',
            'ultimo_cargo': 'Repositora de Supermercado',
            'area_atuacao': 'Varejo Alimentar / Trade Marketing',
            'tempo_experiencia': '2 anos',
            'pretensao_salarial': 'R\$ 2.200,00',
            'ultimo_salario': 'R\$ 1.800,00',
            'tipo_contratacao': 'Freelancer / CLT',
            'nivel_profissional': 'Assistente',
          },
          'marcas_disponiveis': ['Cimed', 'Nestlé', 'Coca-Cola', 'Heineken', 'Ambev', 'Ypê', 'Baly', 'Plasútil', 'Omo'],
          'marcas_selecionadas': ['Nestlé', 'Coca-Cola', 'Ypê', 'Ambev', 'Omo'],
          'redes_flags': {
            'Atacadão': true,
            'Assaí': true,
            'Carrefour': true,
            'Pão de Açúcar': false,
            'Roldão': true,
            'Spani': false,
            'Dia': true,
          },
          'trade_flags': {
            'Reposição': true,
            'Abastecimento': true,
            'Layout': true,
            'FIFO': true,
            'Alimentar': true,
            'Farma': false,
            'Degustação': true,
          },
          'habilidades': {
            'Excel': true,
            'Canva': true,
            'Sistemas de coleta': true,
            'Negociação': true,
            'Comunicação': true,
          },
          'escolaridade': {
            'grau': 'Ensino Médio Completo',
            'curso': 'Ensino Médio',
            'instituicao': 'Colégio Estadual de São Paulo',
            'status': 'Completo',
            'ano': '2016',
          },
          'rh_score': 9.2,
          'rh_ranking': '#3 Regional',
          'rh_feedback': 'Candidata altamente pontual, comunicativa e proativa. Excelente histórico disciplinar em todas as diárias realizadas na região Norte.',
        })
      ),
      AppUser(
        id: '12345678901',
        name: 'Ricardo Silva',
        email: 'ricardo.silva@outlook.com',
        role: 'Promotor Especialista',
        status: 'Ativo',
        type: 'prestador',
        curriculumResumo: 'Promotor focado no canal Farma e Cosméticos, especialista em positivação de material POP e negociação de pontos extras. 4 anos de experiência no segmento.',
        curriculumExperiencias: 'Promotor de Trade - Cimed (2 anos)\n• Positivação de displays e material promocional\n• Treinamento básico de balconistas sobre produtos\n\nPromotor Alimentar - Heineken (1.5 anos)\n• Organização de ilhas e gôndolas premium.',
        curriculumEscolaridade: 'Ensino Superior Incompleto',
        curriculumCompletoDados: jsonEncode({
          'dados_pessoais': {
            'rg': '39.812.441-2',
            'data_nascimento': '12/03/1993',
            'idade': '33 anos',
            'sexo': 'Masculino',
            'estado_civil': 'Casado',
            'whatsapp': '(11) 98111-2222',
            'rua': 'Rua Augusta, 400',
            'bairro': 'Consolação',
            'cidade': 'São Paulo',
            'estado': 'SP',
            'cep': '01304-000',
          },
          'documentacao': {
            'cnh_categoria': 'AB',
            'veiculo_proprio': true,
            'carro': false,
            'moto': true,
            'mei': true,
          },
          'disponibilidade': {
            'horarios': 'Período Integral',
            'finais_semana': true,
            'viagens': false,
            'clt': true,
            'pj': true,
            'freelancer': true,
            'raio': 40.0,
            'PDV': true,
            'Sampling': true,
            'Auditoria': true,
            'Positivação': true,
            'Merchandising': true,
          },
          'dados_profissionais': {
            'cargo_atual': 'Promotor Farma',
            'ultimo_cargo': 'Promotor de Vendas',
            'tempo_experiencia': '4 anos',
            'pretensao_salarial': 'R\$ 2.800,00',
            'tipo_contratacao': 'Todas',
            'nivel_profissional': 'Analista',
          },
          'marcas_disponiveis': ['Cimed', 'Heineken', 'Coca-Cola', 'Ambev'],
          'marcas_selecionadas': ['Cimed', 'Heineken', 'Ambev'],
          'redes_flags': {
            'Carrefour': true,
            'Pão de Açúcar': true,
            'Roldão': false,
            'Assaí': false,
          },
          'trade_flags': {
            'Reposição': true,
            'Farma': true,
            'Alimentar': true,
            'Positivação': true,
            'Auditoria': true,
          },
          'habilidades': {
            'Excel': true,
            'Word': true,
            'Comunicação': true,
            'Negociação': true,
          },
          'escolaridade': {
            'grau': 'Ensino Superior Incompleto',
            'curso': 'Administração de Empresas',
            'instituicao': 'UNIP',
            'status': 'Trancado',
            'ano': '2019',
          },
          'rh_score': 9.5,
          'rh_ranking': '#1 Canal Farma',
          'rh_feedback': 'Profissional diferenciado, excelente vocabulário, possui moto própria facilitando grande deslocamento diário.',
        })
      ),
      AppUser(
        id: '98765432109',
        name: 'Ana Paula Souza',
        email: 'anapaula.souza@gmail.com',
        role: 'Degustadora / Demonstradora',
        status: 'Ativo',
        type: 'prestador',
        curriculumResumo: 'Demonstradora de produtos e degustadora com carisma excepcional. Especialista em conversão de vendas no punto de dose e ativação de marcas premium.',
        curriculumExperiencias: 'Degustadora - Nestlé (1 ano)\n• Ação de degustação de chocolates finos e cafés solúveis\n• Abordagem direta, oferta de brindes e aumento de 35% nas vendas locais\n\nPromotora de Sampling - Unilever (6 meses)\n• Distribuição de amostras grátis em redes de supermercados.',
        curriculumEscolaridade: 'Ensino Superior Completo',
        curriculumCompletoDados: jsonEncode({
          'dados_pessoais': {
            'whatsapp': '(11) 97333-4444',
            'cidade': 'Guarulhos',
            'estado': 'SP',
          },
          'documentacao': {
            'cnh_categoria': 'Não possui',
            'veiculo_proprio': false,
            'carro': false,
            'moto': false,
            'mei': false,
          },
          'disponibilidade': {
            'horarios': 'Tarde',
            'finais_semana': true,
            'viagens': false,
            'clt': false,
            'pj': false,
            'freelancer': true,
            'raio': 15.0,
            'Degustação': true,
            'Sampling': true,
            'Eventos': true,
          },
          'dados_profissionais': {
            'cargo_atual': 'Degustadora',
            'tempo_experiencia': '2 anos',
            'pretensao_salarial': 'R\$ 150/diária',
            'tipo_contratacao': 'Freelancer',
            'nivel_profissional': 'Assistente',
          },
          'marcas_disponiveis': ['Nestlé', 'Coca-Cola', 'Heineken'],
          'marcas_selecionadas': ['Nestlé', 'Coca-Cola'],
          'redes_flags': {
            'Carrefour': true,
            'GPA': true,
            'Pão de Açúcar': true,
            'Assaí': true,
          },
          'trade_flags': {
            'Degustação': true,
            'Alimentar': true,
          },
          'habilidades': {
            'Comunicação': true,
            'Negociação': true,
            'Vendas': true,
          },
          'rh_score': 8.8,
          'rh_ranking': 'Destaque Trade Sul',
          'rh_feedback': 'Muito simpática e ótima com metas. Ideal para ativações que exigem postura vendedora expressiva.',
        })
      )
    ];
  }

  // Matching Algorithm
  double _calculateMatchScore(AppUser promoter, AppDemand demand) {
    double score = 0.0;
    int criteriaChecked = 0;

    // Parse curriculum details
    Map<String, dynamic> cv = {};
    if (promoter.curriculumCompletoDados != null) {
      try {
        cv = jsonDecode(promoter.curriculumCompletoDados!);
      } catch (e) {
        // Fallback
      }
    }

    // 1. Role Match (Weight: 30%)
    criteriaChecked++;
    final userRole = (promoter.role ?? '').toLowerCase();
    final demandRole = (demand.role ?? '').toLowerCase();
    final professionalGoal = (cv['dados_profissionais']?['objetivo'] ?? '').toString().toLowerCase();
    final professionalCargo = (cv['dados_profissionais']?['cargo_atual'] ?? '').toString().toLowerCase();

    bool roleMatch = userRole.contains(demandRole) || 
                      demandRole.contains(userRole) || 
                      professionalGoal.contains(demandRole) ||
                      professionalCargo.contains(demandRole);
                      
    // Check Action types in Availability
    final actionTypeFlags = cv['disponibilidade'] ?? {};
    if (demandRole.contains('degust') && actionTypeFlags['Degustação'] == true) roleMatch = true;
    if (demandRole.contains('event') && actionTypeFlags['Eventos'] == true) roleMatch = true;
    if (demandRole.contains('merchand') && actionTypeFlags['Merchandising'] == true) roleMatch = true;
    if (demandRole.contains('audito') && actionTypeFlags['Auditoria'] == true) roleMatch = true;
    if (demandRole.contains('positiv') && actionTypeFlags['Positivação'] == true) roleMatch = true;

    if (roleMatch) {
      score += 30.0;
    }

    // 2. Brand Match (Weight: 20%)
    criteriaChecked++;
    final demandBrand = (demand.clientName ?? '').toLowerCase();
    final userSelectedBrands = (cv['marcas_selecionadas'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
    if (userSelectedBrands.isNotEmpty && demandBrand.isNotEmpty) {
      if (userSelectedBrands.any((brand) => brand.contains(demandBrand) || demandBrand.contains(brand))) {
        score += 20.0;
      } else if (promoter.curriculumResumo?.toLowerCase().contains(demandBrand) == true ||
                 promoter.curriculumExperiencias?.toLowerCase().contains(demandBrand) == true) {
        score += 15.0; // partial match in text
      }
    }

    // 3. Network/Rede Match (Weight: 20%)
    criteriaChecked++;
    final demandNetwork = (demand.network ?? '').toLowerCase();
    final demandStore = (demand.storeName ?? '').toLowerCase();
    final userRedesFlags = cv['redes_flags'] as Map?;
    bool redeMatch = false;

    if (userRedesFlags != null) {
      userRedesFlags.forEach((key, val) {
        final keyStr = key.toString().toLowerCase();
        if (val == true && (demandNetwork.contains(keyStr) || demandStore.contains(keyStr))) {
          redeMatch = true;
        }
      });
    }
    if (redeMatch) {
      score += 20.0;
    }

    // 4. Location/Region Match (Weight: 20%)
    criteriaChecked++;
    final demandCity = (demand.address ?? '').toLowerCase();
    final String rawCity = (promoter.addressCity != null && promoter.addressCity!.isNotEmpty)
        ? promoter.addressCity!
        : (cv['dados_pessoais']?['cidade'] ?? '').toString();
    final userCity = rawCity.toLowerCase();
    
    if (userCity.isNotEmpty && demandCity.contains(userCity)) {
      score += 20.0;
    } else if (promoter.curriculumResumo?.toLowerCase().contains(userCity) == true) {
      score += 10.0;
    }

    // 5. Intern Score Rating Bonus (Weight: 10%)
    criteriaChecked++;
    final double rating = (cv['rh_score'] ?? 5.0).toDouble();
    if (rating >= 9.0) {
      score += 10.0;
    } else if (rating >= 8.0) {
      score += 7.0;
    } else {
      score += (rating / 10.0) * 5.0;
    }

    return score;
  }

  // Action to link promoter to job
  Future<void> _vincularPromotorVaga(AppUser promoter, AppDemand demand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Vincular Promotor à Vaga', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('Deseja alocar ${promoter.name} para a diária no "${demand.storeName}" como "${demand.role}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('CONFIRMAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      // Update demand model properties by instantiating a new one
      final updated = AppDemand(
        id: demand.id,
        clientId: demand.clientId,
        projectId: demand.projectId,
        storeId: demand.storeId,
        roleId: demand.roleId,
        storeName: demand.storeName,
        network: demand.network,
        address: demand.address,
        role: demand.role,
        distance: demand.distance,
        timeRange: demand.timeRange,
        value: demand.value,
        date: demand.date,
        urgency: demand.urgency,
        status: (demand.filledVagas + 1 >= demand.totalVagas) ? 'PREENCHIDAS' : demand.status,
        assignedPromoter: promoter.name,
        clientName: demand.clientName,
        projectName: demand.projectName,
        totalVagas: demand.totalVagas,
        filledVagas: (demand.filledVagas + 1).clamp(0, demand.totalVagas),
        entryTime: demand.entryTime,
        exitTime: demand.exitTime,
        requiresCheckIn: demand.requiresCheckIn,
        requiresCheckOut: demand.requiresCheckOut,
        requiresPhoto: demand.requiresPhoto,
        requiresLocation: demand.requiresLocation,
        allowedRadius: demand.allowedRadius,
        maxPromoterDistance: demand.maxPromoterDistance,
        instructions: demand.instructions,
        priority: demand.priority,
        questionnaire: demand.questionnaire,
        requiredActivity: demand.requiredActivity,
        stepByStep: demand.stepByStep,
        minTime: demand.minTime,
        dressCode: demand.dressCode,
        requiredDocuments: demand.requiredDocuments,
        latitude: demand.latitude,
        longitude: demand.longitude,
      );
      
      // Save demand to Firestore
      await _api.saveDemand(updated);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${promoter.name} alocado(a) com sucesso na vaga da loja ${demand.storeName}!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh page data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alocar candidato: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // Build the curriculum detail dialogue
  void _verDetalhesCurriculo(AppUser promoter) {
    Map<String, dynamic> cv = {};
    if (promoter.curriculumCompletoDados != null) {
      try {
        cv = jsonDecode(promoter.curriculumCompletoDados!);
      } catch (e) {
        // Failed decoding
      }
    }

    final personal = cv['dados_pessoais'] ?? {};
    final docs = cv['documentacao'] ?? {};
    final disp = cv['disponibilidade'] ?? {};
    final prof = cv['dados_profissionais'] ?? {};
    final escolar = cv['escolaridade'] ?? {};
    final redes = cv['redes_flags'] ?? {};
    final trade = cv['trade_flags'] ?? {};
    final marcas = cv['marcas_selecionadas'] as List? ?? [];
    final score = cv['rh_score'] ?? 5.0;
    final feedback = cv['rh_feedback'] ?? 'Sem observações corporativas.';

    final scoreController = TextEditingController(text: score.toString());
    final feedbackController = TextEditingController(text: feedback.toString());

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 900,
            height: 800,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(
                        promoter.name[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promoter.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('${promoter.role} • ${(promoter.addressCity != null && promoter.addressCity!.isNotEmpty) ? promoter.addressCity! : (personal['cidade'] ?? 'Guarulhos')} - ${(promoter.addressUf != null && promoter.addressUf!.isNotEmpty) ? promoter.addressUf! : (personal['estado'] ?? 'SP')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.success, size: 18),
                          const SizedBox(width: 4),
                          Text('Score RH: $score', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.cardBorder),
                
                // Content Tab list
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick highlights
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildModalInfoCard('Resumo Profissional', promoter.curriculumResumo ?? 'Sem resumo cadastrado.'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildModalInfoCard('Contato e Redes', 
                                '📧 ${promoter.email}\n'
                                '📱 ${personal['whatsapp'] ?? 'Não informado'}\n'
                                '🔗 LinkedIn: ${personal['linkedin'] ?? 'Não cadastrado'}\n'
                                '📸 Instagram: ${personal['instagram'] ?? 'Não cadastrado'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Dados Pessoais & Documentos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Dados Pessoais', [
                                _buildKeyValue('Nome Social', personal['nome_social'] ?? '-'),
                                _buildKeyValue('Idade', personal['idade'] ?? '-'),
                                _buildKeyValue('Sexo', personal['sexo'] ?? '-'),
                                _buildKeyValue('RG', personal['rg'] ?? '-'),
                                _buildKeyValue('CPF', promoter.id),
                                _buildKeyValue('Endereço', '${personal['rua'] ?? ''}, ${personal['bairro'] ?? ''} - CEP: ${personal['cep'] ?? ''}'),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Documentação & Veículo', [
                                _buildKeyValue('CNH Categoria', docs['cnh_categoria'] ?? 'Não possui'),
                                _buildKeyValue('Validade CNH', docs['cnh_validade'] ?? '-'),
                                _buildKeyValue('Veículo Próprio', docs['veiculo_proprio'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Possui Carro', docs['carro'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Possui Moto', docs['moto'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Chave Pix', docs['chave_pix'] ?? '-'),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Profissional & Disponibilidade
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Dados Profissionais', [
                                _buildKeyValue('Cargo Atual', prof['cargo_atual'] ?? '-'),
                                _buildKeyValue('Último Cargo', prof['ultimo_cargo'] ?? '-'),
                                _buildKeyValue('Experiência', prof['tempo_experiencia'] ?? '-'),
                                _buildKeyValue('Pretensão Salarial', prof['pretensao_salarial'] ?? '-'),
                                _buildKeyValue('Escolaridade', escolar['grau'] ?? '-'),
                                _buildKeyValue('Curso/Habilitação', '${escolar['curso'] ?? ''} (${escolar['status'] ?? ''})'),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Disponibilidade de Trabalho', [
                                _buildKeyValue('Horário', disp['horarios'] ?? '-'),
                                _buildKeyValue('Raio Deslocamento', '${disp['raio'] ?? 20} KM'),
                                _buildKeyValue('Disponibilidade Imediata', disp['imediata'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Finais de Semana', disp['finais_semana'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Aceita CLT / PJ / Freelancer', '${disp['clt'] == true ? 'CLT ' : ''}${disp['pj'] == true ? 'PJ ' : ''}${disp['freelancer'] == true ? 'Freelancer' : ''}'),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Experiências por Redes, Marcas e Habilidades
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Marcas Preferidas', [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: marcas.map((m) => Chip(
                                    label: Text(m.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                    backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )).toList(),
                                )
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Experiência em Redes', [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: redes.entries.where((e) => e.value == true).map((e) => Chip(
                                    label: Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                    backgroundColor: Colors.purple.withOpacity(0.08),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )).toList(),
                                )
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Experiências Detalhadas & RH Feedback
                        _buildModalInfoCard('Histórico de Experiências Profissionais', promoter.curriculumExperiencias ?? 'Nenhum histórico detalhado inserido.'),
                        const SizedBox(height: 20),
                        
                        // Editable evaluation section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 AVALIAÇÃO E ANÁLISE DO RH', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('SCORE DO RH (0 A 10)', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: scoreController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('OBSERVAÇÕES E FEEDBACK DO RH', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: feedbackController,
                                          maxLines: 3,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            hintText: 'Digite aqui a análise corporativa...',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                const Divider(height: 32, color: AppColors.cardBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('FECHAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final double? newScore = double.tryParse(scoreController.text.replaceAll(',', '.'));
                        if (newScore == null || newScore < 0.0 || newScore > 10.0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, insira um score válido entre 0 e 10.')),
                          );
                          return;
                        }
                        
                        cv['rh_score'] = newScore;
                        cv['rh_feedback'] = feedbackController.text;
                        promoter.curriculumCompletoDados = jsonEncode(cv);
                        
                        await _api.saveUser(promoter);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        _loadData();
                      },
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text('SALVAR AVALIAÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    if (_selectedDemand != null) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _vincularPromotorVaga(promoter, _selectedDemand!);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('ALOCAR NESTA VAGA', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModalSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$key: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    // Rank promoters based on Selected Vaga (Demand)
    List<MapEntry<AppUser, double>> scoredPromoters = _promoters.map((p) {
      double score = 0.0;
      if (_selectedDemand != null) {
        score = _calculateMatchScore(p, _selectedDemand!);
      }
      return MapEntry(p, score);
    }).toList();

    // Sort: highest score first if demand selected, else sort alphabetically or by score
    if (_selectedDemand != null) {
      scoredPromoters.sort((a, b) => b.value.compareTo(a.value));
    }

    // Filter promoters based on screen criteria
    final filteredScored = scoredPromoters.where((entry) {
      final p = entry.key;
      Map<String, dynamic> cv = {};
      if (p.curriculumCompletoDados != null) {
        try {
          cv = jsonDecode(p.curriculumCompletoDados!);
        } catch (e) {}
      }

      // Search Query Match (Name, City, Resume)
      final name = p.name.toLowerCase();
      final String rawCity = (p.addressCity != null && p.addressCity!.isNotEmpty)
          ? p.addressCity!
          : (cv['dados_pessoais']?['cidade'] ?? '').toString();
      final city = rawCity.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty || name.contains(query) || city.contains(query) || (p.curriculumResumo ?? '').toLowerCase().contains(query);

      // Role filter
      final role = (p.role ?? '').toLowerCase();
      final filterRoleLower = _filterRole.toLowerCase();
      final matchesRole = _filterRole == 'Todos' || role.contains(filterRoleLower) || filterRoleLower.contains(role);

      // City filter
      final matchesCity = _filterCity == 'Todas' || city.contains(_filterCity.toLowerCase());

      // Contract filter
      final disp = cv['disponibilidade'] ?? {};
      bool matchesContract = true;
      if (_filterContract == 'CLT') matchesContract = disp['clt'] == true;
      if (_filterContract == 'PJ') matchesContract = disp['pj'] == true;
      if (_filterContract == 'Freelancer') matchesContract = disp['freelancer'] == true;

      // CNH
      final docs = cv['documentacao'] ?? {};
      final cnh = (docs['cnh_categoria'] ?? '').toString();
      final matchesCnh = _filterCnh == 'Todos' || cnh.contains(_filterCnh);

      // Vehicle
      final hasVehicle = docs['veiculo_proprio'] == true;
      final matchesVehicle = !_filterHasVehicle || hasVehicle;

      // Score
      final score = (cv['rh_score'] ?? 0.0).toDouble();
      final matchesScore = score >= _minScore;

      // Brand match
      final brands = (cv['marcas_selecionadas'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final matchesBrand = _filterBrand.isEmpty || brands.any((b) => b.contains(_filterBrand.toLowerCase()));

      // Rede match
      final redes = cv['redes_flags'] as Map? ?? {};
      bool matchesRede = _filterRede.isEmpty;
      if (_filterRede.isNotEmpty) {
        redes.forEach((key, val) {
          if (val == true && key.toString().toLowerCase().contains(_filterRede.toLowerCase())) {
            matchesRede = true;
          }
        });
      }

      return matchesQuery && matchesRole && matchesCity && matchesContract && matchesCnh && matchesVehicle && matchesScore && matchesBrand && matchesRede;
    }).toList();

    return Scrollbar(
      controller: _mainScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumHeader(
            title: 'Banco de Talentos & Currículos',
            subtitle: 'Encontre prestadores qualificados e identifique o match perfeito para suas diárias.',
          ),
          
          // Filters section spanning full width
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('FILTROS DE BUSCA E MAPEAMENTO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                      IconButton(
                        icon: Icon(
                          _isFiltersExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFiltersExpanded = !_isFiltersExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!_isFiltersExpanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      children: _buildActiveFilterChips().isEmpty
                          ? [const Text('Nenhum filtro ativo', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic))]
                          : _buildActiveFilterChips(),
                    ),
                  ],
                  if (_isFiltersExpanded) ...[
                    const SizedBox(height: 20),
                    
                    // Row 1: Vaga, Busca, Função
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SELECIONE A VAGA OPERACIONAL', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<AppDemand>(
                                value: _selectedDemand,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Selecione uma vaga aberta',
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                                items: _activeDemands.map((d) {
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      '${d.storeName} (${d.role})',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDemand = val;
                                  });
                                },
                              ),
                              if (_selectedDemand != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '🔍 Vaga: ${_selectedDemand!.role} • 🏢 Cliente: ${_selectedDemand!.clientName ?? 'Não informado'} • 📍 Loja: ${_selectedDemand!.storeName} • 📅 Data: ${_selectedDemand!.date}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                                        onPressed: () => setState(() => _selectedDemand = null),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PESQUISAR POR NOME OU RESUMO', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _searchQueryCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Pesquisar por nome ou resumo...',
                                  prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1, size: 16),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FUNÇÃO PRINCIPAL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _filterRole,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                                items: ['Todos', 'Promotor', 'Degustador', 'Repositor', 'Supervisor']
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _filterRole = val ?? 'Todos'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 2: Cidade, CNH, Marca
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CIDADE', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _filterCity,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                                items: ['Todas', 'São Paulo', 'Guarulhos', 'Osasco', 'Campinas']
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _filterCity = val ?? 'Todas'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CATEGORIA DE CNH', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _filterCnh,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                                items: ['Todos', 'A', 'B', 'AB', 'C', 'D']
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _filterCnh = val ?? 'Todos'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EXPERIÊNCIA EM MARCA', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _brandCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Ex: Nestlé, Coca-Cola...',
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 3: Rede, Veículo, Score
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EXPERIÊNCIA EM REDE/SUPERMERCADO', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _redeCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Ex: Atacadão, Assaí...',
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('VEÍCULO PRÓPRIO', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Exigir veículo próprio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Switch(
                                      value: _filterHasVehicle,
                                      onChanged: (val) => setState(() => _filterHasVehicle = val),
                                      activeColor: AppColors.primaryBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SCORE MÍNIMO DO RH: ${_minScore.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                  ),
                                  child: Slider(
                                    value: _minScore,
                                    min: 0.0,
                                    max: 10.0,
                                    divisions: 10,
                                    activeColor: AppColors.primaryBlue,
                                    onChanged: (val) => setState(() => _minScore = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Results list below filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESULTADOS ENCONTRADOS (${filteredScored.length})',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
              ),
              if (_selectedDemand != null)
                const Text(
                  'Classificado por % de Match com a vaga',
                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          filteredScored.isEmpty
              ? const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 80.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(IconsaxPlusLinear.user_remove, color: AppColors.textSecondary, size: 48),
                          SizedBox(height: 16),
                          Text('Nenhum currículo atende aos filtros atuais.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredScored.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final entry = filteredScored[index];
                    final promoter = entry.key;
                    final matchScore = entry.value;

                    Map<String, dynamic> cv = {};
                    if (promoter.curriculumCompletoDados != null) {
                      try {
                        cv = jsonDecode(promoter.curriculumCompletoDados!);
                      } catch (e) {}
                    }

                    final personal = cv['dados_pessoais'] ?? {};
                    final docs = cv['documentacao'] ?? {};
                    final disp = cv['disponibilidade'] ?? {};
                    final rhScore = cv['rh_score'] ?? 5.0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circular Match Meter
                            if (_selectedDemand != null) ...[
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue.withOpacity(0.04),
                                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 2),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${matchScore.toInt()}%', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 18)),
                                      const Text('MATCH', style: TextStyle(color: AppColors.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],

                            // Promoter Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(promoter.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          promoter.role ?? 'Promotor',
                                          style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: AppColors.success, size: 12),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Score RH: $rhScore',
                                              style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(IconsaxPlusLinear.location, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${(promoter.addressCity != null && promoter.addressCity!.isNotEmpty) ? promoter.addressCity! : (personal['cidade'] ?? 'Não informado')} - ${(promoter.addressUf != null && promoter.addressUf!.isNotEmpty) ? promoter.addressUf! : (personal['estado'] ?? '')} • CNH: ${docs['cnh_categoria'] ?? "Não possui"} • Veículo Próprio: ${docs['veiculo_proprio'] == true ? "Sim" : "Não"}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    promoter.curriculumResumo ?? 'Sem resumo cadastrado.',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildQuickTag(disp['horarios'] ?? 'Período Integral', IconsaxPlusLinear.clock, Colors.grey),
                                      if (disp['finais_semana'] == true)
                                        _buildQuickTag('Finais de Semana', IconsaxPlusLinear.calendar, Colors.orange),
                                      if (disp['viagens'] == true)
                                        _buildQuickTag('Viagens', IconsaxPlusLinear.airplane, Colors.blue),
                                      if (docs['carro'] == true)
                                        _buildQuickTag('Possui Carro', IconsaxPlusLinear.car, Colors.indigo),
                                      if (docs['moto'] == true)
                                        _buildQuickTag('Possui Moto', IconsaxPlusLinear.car, Colors.teal),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            // Action Buttons
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _verDetalhesCurriculo(promoter),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  child: const Text('VER DETALHES', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final adminState = context.findAncestorStateOfType<AdminDashboardViewState>();
                                    if (adminState != null) {
                                      adminState.switchToSupportChat(promoter.id);
                                    }
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primaryBlue),
                                  label: const Text('ENVIAR MENSAGEM', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                ),
                                if (_selectedDemand != null) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () => _vincularPromotorVaga(promoter, _selectedDemand!),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primaryBlue),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    ),
                                    child: const Text('ALOCAR VAGA', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
