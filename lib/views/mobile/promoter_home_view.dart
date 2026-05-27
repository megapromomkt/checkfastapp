import 'dart:ui';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/utils/responsive.dart';
import 'daily_execution_view.dart';
import 'check_in_tab_view.dart';
import 'store_detail_view.dart';
import 'task_timeline_view.dart';
import 'payment_details_view.dart';
import 'edit_profile_view.dart';
import 'pix_key_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/demand_onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';
import '../../core/services/register_service.dart';

class PromoterHomeView extends StatefulWidget {
  const PromoterHomeView({super.key});

  @override
  State<PromoterHomeView> createState() => _PromoterHomeViewState();
}

class _PromoterHomeViewState extends State<PromoterHomeView> {
  int _selectedIndex = 0;
  String _userName = 'Ricardo Silva';
  String _userCpf = '123.456.789-00';
  String _userCity = '';
  String _userBairro = '';
  String _userCep = '';
  final _api = RegisterService();
  List<AppDemand> _realDemands = [];
  bool _isLoadingDemands = true;

  int _opportunityCount = 12;
  
  String _tarefasHoje = '02';
  String _horasTotais = '42h';
  String _ganhosMes = 'R\$ 1.280,00';
  String _proximoPagamento = '30/04';
  
  String _aReceber = 'R\$ 390,00';
  String _pagoNoMes = 'R\$ 780,00';
  String _emAnalise = 'R\$ 130,00';

  int _calculateSumOfDigits(String str) {
    final clean = str.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return 45; // Fallback se o CPF for vazio
    return clean.split('').map(int.parse).reduce((a, b) => a + b);
  }

  final List<Map<String, dynamic>> _allOpportunities = [
    {'name': 'ATACADÃO LAPA', 'network': 'REDE ATACADÃO', 'distance': '1.2 KM', 'value': 'R\$ 150,00', 'status': 'HOJE', 'color': AppColors.success, 'city': 'São Paulo', 'lat': -23.52, 'lon': -46.70},
    {'name': 'CARREFOUR OSASCO', 'network': 'CARREFOUR BR', 'distance': '4.5 KM', 'value': 'R\$ 180,00', 'status': 'AMANHÃ', 'color': AppColors.warning, 'city': 'Osasco', 'lat': -23.53, 'lon': -46.79},
    {'name': 'PÃO DE AÇÚCAR', 'network': 'GPA S/A', 'distance': '0.8 KM', 'value': 'R\$ 160,00', 'status': 'URGENTE', 'color': Colors.redAccent, 'city': 'São Paulo', 'lat': -23.56, 'lon': -46.70},
    {'name': 'BIG BOMPREÇO', 'network': 'WALMART BR', 'distance': '2.1 KM', 'value': 'R\$ 145,00', 'status': 'HOJE', 'color': AppColors.success, 'city': 'São Paulo', 'lat': -23.52, 'lon': -46.70},
    {'name': 'EXTRA GUARULHOS', 'network': 'GPA S/A', 'distance': '15.0 KM', 'value': 'R\$ 170,00', 'status': 'HOJE', 'color': AppColors.success, 'city': 'Guarulhos', 'lat': -23.45, 'lon': -46.53},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  double _userLat = 0.0;
  double _userLon = 0.0;
  double _selectedRadius = 10.0;

  String _userUf = '';
  String _userRua = '';
  String _userEmail = '';
  String _userPhone = '';

  // --- VARIÁVEIS DO CHAT DE SUPORTE (MENSAGENS) ---
  final _chatMessageController = TextEditingController();
  final _chatScrollController = ScrollController();
  String _chatTopic = 'Operacional';

  // --- NOVAS VARIÁVEIS DO CURRÍCULO COMPLETO ---
  
  // 1. Dados Pessoais
  final _resumoController = TextEditingController(text: "Promotora de Vendas dedicada, com sólida experiência em merchandising, abastecimento de gôndolas, layout e precificação. Foco em resultados de vendas e manutenção de padrões de qualidade nas lojas.");
  final _experienciasController = TextEditingController(text: "Promotora de Vendas - Atacadão (1 ano)\n• Reposição e organização de gôndolas\n• Controle de validade (FIFO)\n• Precificação e ativação de material de merchandising.\n\nPromotora de Vendas - Assaí (6 meses)\n• Atendimento ao cliente e suporte no ponto de venda\n• Organização de estoque e contagem de inventário.");
  final _nomeSocialController = TextEditingController(text: "");
  final _rgController = TextEditingController(text: "50.123.456-7");
  final _orgaoEmissorController = TextEditingController(text: "SSP/SP");
  final _nascimentoController = TextEditingController(text: "27/04/1998");
  final _idadeController = TextEditingController(text: "28");
  final _sexoController = TextEditingController(text: "Feminino");
  final _estadoCivilController = TextEditingController(text: "Solteira");
  final _nacionalidadeController = TextEditingController(text: "Brasileira");
  final _naturalidadeController = TextEditingController(text: "São Paulo - SP");
  final _telSecundarioController = TextEditingController(text: "");
  final _whatsappController = TextEditingController(text: "(11) 93066-6101");
  final _linkedinController = TextEditingController(text: "linkedin.com/in/thabata-reco");
  final _instagramController = TextEditingController(text: "@thabata_trade");

  // 2. Documentação
  final _cnhController = TextEditingController(text: "12345678901");
  String _cnhCategoria = "B";
  final _cnhValidadeController = TextEditingController(text: "12/12/2030");
  bool _possuiVeiculoProprio = false;
  String _tipoVeiculo = "Nenhum";
  final _docVeiculoController = TextEditingController(text: "");
  bool _possuiMoto = false;
  bool _possuiCarro = false;
  bool _possuiMei = true;
  bool _possuiCnpj = false;
  final _pisController = TextEditingController(text: "120.12345.67.8");
  final _tituloEleitorController = TextEditingController(text: "1234 5678 9012");
  final _reservistaController = TextEditingController(text: "");
  final _contaBancariaController = TextEditingController(text: "Banco Itaú - Ag: 1234 CC: 56789-0");
  final _chavePixController = TextEditingController(text: "thabata.reco@gmail.com");

  // 3. Disponibilidade
  String _disponibilidadeHorario = "Período Integral";
  bool _dispFinaisSemana = true;
  bool _dispViagens = true;
  bool _dispPernoite = false;
  bool _dispAcoesTemporarias = true;
  bool _dispClt = true;
  bool _dispPj = true;
  bool _dispFreelancer = true;
  bool _dispImediata = true;
  final _regiaoAtuacaoController = TextEditingController(text: "Zona Norte e Centro de São Paulo");
  double _raioDeslocamento = 15.0; // km
  
  final Map<String, bool> _tiposAcoesFlags = {
    'PDV': true,
    'Eventos': true,
    'Feiras': true,
    'Sampling': true,
    'Degustação': true,
    'Auditoria': true,
    'Pesquisa': true,
    'Live marketing': true,
    'Positivação': true,
    'Merchandising': true,
    'Promotoria compartilhada': true,
    'Promotoria exclusiva': false,
  };

  // 4. Dados Profissionais
  final _objetivoProfissionalController = TextEditingController(text: "Atuar como promotora de trade marketing em grandes redes de varejo alimentar e farma.");
  final _cargoAtualController = TextEditingController(text: "Promotora de Vendas Freelancer");
  final _ultimoCargoController = TextEditingController(text: "Repositora de Supermercado");
  final _areaAtuacaoController = TextEditingController(text: "Varejo Alimentar / Trade Marketing");
  final _tempoExperienciaController = TextEditingController(text: "2 anos");
  final _pretensaoSalarialController = TextEditingController(text: "R\$ 2.200,00");
  final _ultimoSalarioController = TextEditingController(text: "R\$ 1.800,00");
  String _tipoContratacaoDesejada = "Freelancer / CLT";
  String _nivelProfissional = "Assistente";

  // 5. Experiências Profissionais (Repeatable)
  List<Map<String, String>> _experienciasLista = [
    {
      'empresa': 'Mega Trade Agência',
      'cargo': 'Promotora de Merchandising',
      'segmento': 'Alimentar',
      'dataEntrada': '01/01/2025',
      'dataSaida': 'Emprego Atual',
      'isAtual': 'Sim',
      'tipoContratacao': 'Freelancer',
      'atividades': 'Reposição de produtos, ativação de material promocional e conquista de pontos extras.',
      'resultados': 'Aumento de 15% nas vendas da marca nos PDVs atendidos.',
      'motivoSaida': '',
      'gestor': 'Renato Souza',
      'contatoGestor': '(11) 98888-7777',
    }
  ];

  // 6. Experiência em Trade Marketing (Flags)
  final Map<String, bool> _tradeMarketingFlags = {
    'Reposição': true,
    'Abastecimento': true,
    'Layoutização': true,
    'Planograma': true,
    'FIFO': true,
    'Precificação': true,
    'Ponto extra': true,
    'Ilha': true,
    'Ponta de gôndola': true,
    'Auditoria': true,
    'Pesquisa': true,
    'Coleta de preços': true,
    'Degustação': true,
    'Sampling': true,
    'Abordagem': true,
    'Venda': true,
    'Live marketing': true,
    'Eventos': true,
    'Merchandising': true,
    'Positivação': true,
    'Home center': false,
    'Farma': false,
    'Alimentar': true,
    'Atacado': true,
    'Varejo': true,
    'Canal indireto': false,
  };

  // 7. Experiência por Redes (Flags)
  final Map<String, bool> _redesFlags = {
    'Atacadão': true,
    'Assaí': true,
    'Carrefour': true,
    'Extra': true,
    'Pão de Açúcar': false,
    'Roldão': true,
    'Tenda': false,
    'Spani': false,
    'Dia': true,
    'Coop': false,
    'Oba Hortifruti': false,
    'Sam’s Club': false,
    'Makro': false,
    'Grupo Mateus': false,
    'GPA': false,
    'BIG': false,
  };

  // 8. Experiência por Marcas
  List<String> _marcasDisponiveis = ['Cimed', 'Nestlé', 'Coca-Cola', 'Heineken', 'Ambev', 'Ypê', 'Baly', 'Plasútil'];
  List<String> _marcasSelecionadas = ['Nestlé', 'Coca-Cola', 'Ypê', 'Ambev'];

  // 9. Escolaridade Completa
  String _escolaridadeSelecionada = "Ensino Médio Completo";
  final _cursoController = TextEditingController(text: "Ensino Médio Completo");
  final _instituicaoController = TextEditingController(text: "Colégio Estadual de São Paulo");
  String _escolaridadeStatus = "Completo";
  final _anoConclusaoController = TextEditingController(text: "2016");

  // 10. Cursos e Certificações
  final _cursoNomeController = TextEditingController(text: "Técnicas de Merchandising Avançado");
  final _cursoInstController = TextEditingController(text: "Sebrae SP");
  final _cursoCargaController = TextEditingController(text: "20 horas");
  final _cursoConclusaoController = TextEditingController(text: "15/03/2024");
  bool _certificadoAnexado = true;

  // 11. Habilidades
  final Map<String, bool> _habilidadesTecnicas = {
    'Excel': true,
    'Power BI': false,
    'Canva': true,
    'Word': true,
    'PowerPoint': true,
    'Sistemas de coleta': true,
    'CRM': false,
    'Salesforce': false,
    'Google Sheets': true,
  };
  
  final Map<String, bool> _habilidadesComportamentais = {
    'Comunicação': true,
    'Liderança': false,
    'Organização': true,
    'Proatividade': true,
    'Negociação': true,
    'Atendimento ao cliente': true,
    'Gestão de conflitos': true,
  };

  // 12. Idiomas
  List<Map<String, String>> _idiomasLista = [
    {'idioma': 'Português', 'nivel': 'Fluente'},
    {'idioma': 'Espanhol', 'nivel': 'Básico'}
  ];

  // 13. Anexos Extra
  String _attachedFileName = "Curriculo_Thabata_Reco.pdf";
  String _anexoFotoProfissional = "foto_profissional.jpg";
  String _anexoCnh = "cnh_thabata.pdf";
  String _anexoCertificados = "certificado_sebrae.pdf";
  String _anexoResidencia = "comprovante_luz.pdf";
  String _anexoPortfolio = "";
  String _anexoVideo = "apresentacao.mp4";

  // 14. Avaliação Interna (Fictício para Visualização de Uso da Empresa)
  final double _scoreCandidato = 9.2;
  final String _rankingCandidato = "#3 Regional";
  final String _avaliacaoRh = "Candidata altamente pontual, comunicativa e proativa. Excelente histórico disciplinar em todas as diárias realizadas na região Norte.";
  final String _avaliacaoGestor = "Thabata se destaca pela atenção aos detalhes no planograma e FIFO. Perfil recomendado para ativações premium e ações compartilhadas.";
  final String _ultimaEntrevista = "10/04/2026";
  final bool _recontratavel = true;
  final bool _blacklist = false;
  final String _notaComportamental = "10.0";
  final String _notaTecnica = "9.5";
  final String _statusCandidato = "Banco de talentos";

  // 15. Campos Inteligentes Generator
  List<String> _gerarTagsInteligentes() {
    final List<String> tags = [];
    if (_tradeMarketingFlags['Alimentar'] == true) tags.add('🍎 Promotor Alimentar');
    if (_tradeMarketingFlags['Farma'] == true) tags.add('💊 Promotor Farma');
    if (_flagsOperacionais['Já liderou equipe'] == true || _nivelProfissional == 'Supervisor' || _nivelProfissional == 'Coordenador') {
      tags.add('👑 Supervisor Regional');
    }
    if (_tradeMarketingFlags['Degustação'] == true) tags.add('🍇 Degustadora');
    if (_dispFreelancer == true) tags.add('⚡ Freelancer');
    if (_dispImediata == true) tags.add('🕒 Disponibilidade Imediata');
    if (_possuiCarro == true || _tipoVeiculo == 'Carro') tags.add('🚗 Possui Carro');
    if (_possuiMoto == true || _tipoVeiculo == 'Moto') tags.add('🏍️ Possui Moto');
    if (_scoreCandidato >= 9.0) tags.add('🏆 Alta Performance');
    if (_redesFlags['Atacadão'] == true || _redesFlags['Assaí'] == true) tags.add('🏢 Já trabalhou na Mega');
    if (_recontratavel == true && _blacklist == false) tags.add('⭐ Recontratação Prioritária');
    return tags;
  }

  // 16. Flags Operacionais
  final Map<String, bool> _flagsOperacionais = {
    'Aceita ações noturnas': false,
    'Aceita ações em finais de semana': true,
    'Aceita cobertura emergencial': true,
    'Disponível para viagens': true,
    'Possui smartphone': true,
    'Possui internet móvel': true,
    'Possui notebook': false,
    'Possui uniforme preto': true,
    'Possui sapato social': true,
    'Possui experiência em shopping': true,
    'Experiência em eventos grandes': true,
    'Já liderou equipe': false,
    'Possui experiência com ruptura': true,
    'Experiência com abastecimento pesado': true,
  };

  int _activeAccordionIndex = 0;
  bool _isUploadingPdf = false;
  double _uploadProgress = 0.0;
  bool _hasSavedCv = false;

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Ricardo Silva';
      _userCpf = prefs.getString('user_cpf') ?? '123.456.789-00';
      _userCity = prefs.getString('user_city') ?? '';
      _userBairro = prefs.getString('user_bairro') ?? '';
      _userCep = prefs.getString('user_cep') ?? '';
      _userUf = prefs.getString('user_uf') ?? '';
      _userRua = prefs.getString('user_rua') ?? '';
      _userEmail = prefs.getString('user_email') ?? 'thabata.reco@gmail.com';
      _userPhone = prefs.getString('user_phone') ?? '(11) 93066-6101';

      final dynamicMarcas = prefs.getStringList('marcas_disponiveis');
      if (dynamicMarcas != null) {
        _marcasDisponiveis = dynamicMarcas;
      }
      final selectedMarcas = prefs.getStringList('marcas_selecionadas');
      if (selectedMarcas != null) {
        _marcasSelecionadas.clear();
        _marcasSelecionadas.addAll(selectedMarcas);
      }

      _tarefasHoje = '00';
      _horasTotais = '0h';
      _ganhosMes = 'R\$ 0,00';
      _proximoPagamento = '--/--';
      
      _aReceber = 'R\$ 0,00';
      _pagoNoMes = 'R\$ 0,00';
      _emAnalise = 'R\$ 0,00';
    });

    // Carrega imediatamente as demandas usando o filtro textual por cidade (enquanto a geocodificação roda em background)
    _updateOpportunityCount();

    if (_userCity.isNotEmpty) {
      _geocodeUserAddress(_userCity, _userBairro, _userCep, _userUf, _userRua);
    }
  }

  void _geocodeUserAddress(String city, String bairro, String cep, String uf, String rua) async {
    if (city.isEmpty) return;
    
    // Tenta 1: Geocodificar por Rua + Cidade + Estado + Brasil (Altamente preciso e imune a divergências de nomes de bairros do OSM)
    if (rua.isNotEmpty) {
      final String ufSegment = uf.isNotEmpty ? '$uf, ' : '';
      final query = '$rua, $city, $ufSegment"Brasil"';
      final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
      try {
        final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            // Garantir que a coordenada resolvida é perto do estado correto (SP) se o UF for SP
            if (uf != 'SP' || (lat < -20.0 && lat > -26.0)) {
              setState(() {
                _userLat = lat;
                _userLon = lon;
              });
              print('📍 Geocodificação bem sucedida por Rua + Cidade: ($_userLat, $_userLon)');
              _updateOpportunityCount();
              return;
            }
          }
        }
      } catch (e) {
        print('Erro ao geocodificar por Rua + Cidade: $e');
      }
    }

    // Tenta 2: Geocodificar por Rua + Bairro + Cidade + Estado (Com Bairro como fallback se o primeiro falhar)
    if (bairro.isNotEmpty && rua.isNotEmpty) {
      final String ufSegment = uf.isNotEmpty ? '$uf, ' : '';
      final query = '$rua, $bairro, $city, $ufSegment"Brasil"';
      final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
      try {
        final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            if (uf != 'SP' || (lat < -20.0 && lat > -26.0)) {
              setState(() {
                _userLat = lat;
                _userLon = lon;
              });
              print('📍 Geocodificação bem sucedida por Rua + Bairro + Cidade: ($_userLat, $_userLon)');
              _updateOpportunityCount();
              return;
            }
          }
        }
      } catch (e) {
        print('Erro ao geocodificar por Rua + Bairro + Cidade: $e');
      }
    }

    // Tenta 3: Consultar ViaCEP (API brasileira ultra-precisa) para achar o endereço real do CEP e geocodificar no Nominatim
    if (cep.isNotEmpty) {
      final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
      if (cleanCep.length == 8) {
        try {
          final viaCepUrl = 'https://viacep.com.br/ws/$cleanCep/json/';
          final viaCepRes = await http.get(Uri.parse(viaCepUrl));
          if (viaCepRes.statusCode == 200) {
            final viaCepData = jsonDecode(viaCepRes.body);
            if (viaCepData['erro'] != true) {
              final vRua = viaCepData['logradouro'] ?? '';
              final vBairro = viaCepData['bairro'] ?? '';
              final vCity = viaCepData['localidade'] ?? '';
              final vUf = viaCepData['uf'] ?? '';
              
              final String streetSegment = vRua.isNotEmpty ? '$vRua, ' : '';
              final query = '$streetSegment$vCity, $vUf, Brasil';
              final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
              
              final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                if (data.isNotEmpty) {
                  setState(() {
                    _userLat = double.parse(data[0]['lat']);
                    _userLon = double.parse(data[0]['lon']);
                  });
                  print('📍 Geocodificação bem sucedida por ViaCEP + Nominatim: ($_userLat, $_userLon)');
                  _updateOpportunityCount();
                  return;
                }
              }
            }
          }
        } catch (e) {
          print('Erro no fallback ViaCEP: $e');
        }
      }
    }

    // Tenta 4: Bairro + Cidade + Estado (Sem Rua)
    if (bairro.isNotEmpty) {
      final String ufSegment = uf.isNotEmpty ? '$uf, ' : '';
      final query = '$bairro, $city, $ufSegment"Brasil"';
      final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
      try {
        final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            if (uf != 'SP' || (lat < -20.0 && lat > -26.0)) {
              setState(() {
                _userLat = lat;
                _userLon = lon;
              });
              print('📍 Geocodificação bem sucedida por Bairro + Cidade: ($_userLat, $_userLon)');
              _updateOpportunityCount();
              return;
            }
          }
        }
      } catch (e) {
        print('Erro ao geocodificar por Bairro + Cidade: $e');
      }
    }
    
    // Tenta 5: Apenas Cidade como último recurso
    final query = '$city, ${uf.isNotEmpty ? uf + ", " : ""}Brasil';
    final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    try {
      final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _userLat = double.parse(data[0]['lat']);
            _userLon = double.parse(data[0]['lon']);
          });
          print('📍 Geocodificação bem sucedida por Cidade: ($_userLat, $_userLon)');
          _updateOpportunityCount();
        }
      }
    } catch (e) {
      print('Erro ao geocodificar por cidade: $e');
      _updateOpportunityCount();
    }
  }

  void _updateOpportunityCount() async {
    try {
      final demands = await _api.getDemands();
      final List<AppDemand> filtered = [];
      
      for (var d in demands) {
        if (d.status != 'ABERTAS') continue;
        
        bool isWithinRange = false;
        double dist = 99999.0;
        
        // 1. Se ambos têm coordenadas válidas (não nulas e não zero), calculamos o raio geográfico com base no raio selecionado
        if (d.latitude != null && d.longitude != null && d.latitude != 0.0 && d.longitude != 0.0 &&
            _userLat != 0.0 && _userLon != 0.0) {
          dist = _calculateDistance(_userLat, _userLon, d.latitude!, d.longitude!);
          isWithinRange = (dist <= _selectedRadius);
        } else {
          // 2. Fallback textual por Cidade: se não houver coordenadas, filtramos comparando com o endereço cadastrado
          if (_userCity.isNotEmpty) {
            final cleanUserCity = _userCity.toLowerCase().trim();
            final cleanDemandAddress = d.address.toLowerCase().trim();
            final cleanStoreName = d.storeName.toLowerCase().trim();
            
            final bool matchesCity = cleanDemandAddress.contains(cleanUserCity) || cleanStoreName.contains(cleanUserCity);
            
            // Se for São Paulo (cidade gigante), e tivermos o bairro cadastrado, filtramos de forma mais restrita para evitar falsos positivos
            // Se o usuário selecionou um raio maior que 30km, removemos a restrição de bairro para mostrar todas as vagas
            if (matchesCity && cleanUserCity == 'são paulo' && _userBairro.isNotEmpty && _selectedRadius < 30.0) {
              final cleanBairro = _userBairro.toLowerCase().trim();
              isWithinRange = cleanDemandAddress.contains(cleanBairro) || cleanStoreName.contains(cleanBairro);
            } else {
              isWithinRange = matchesCity;
            }
          } else {
            // Se o usuário não tem cidade no cadastro, mostramos como fallback
            isWithinRange = true;
          }
        }
        
        if (isWithinRange) {
          final distanceStr = dist < 9999.0 ? '${dist.toStringAsFixed(1)} KM' : '---';
          filtered.add(AppDemand(
            id: d.id,
            storeName: d.storeName,
            network: d.network,
            address: d.address,
            role: d.role,
            distance: distanceStr,
            timeRange: d.timeRange,
            value: d.value,
            date: d.date,
            urgency: d.urgency,
            status: d.status,
            clientId: d.clientId,
            projectId: d.projectId,
            storeId: d.storeId,
            roleId: d.roleId,
            clientName: d.clientName,
            projectName: d.projectName,
            totalVagas: d.totalVagas,
            filledVagas: d.filledVagas,
            entryTime: d.entryTime,
            exitTime: d.exitTime,
            requiresCheckIn: d.requiresCheckIn,
            requiresCheckOut: d.requiresCheckOut,
            requiresPhoto: d.requiresPhoto,
            requiresLocation: d.requiresLocation,
            allowedRadius: d.allowedRadius,
            instructions: d.instructions,
            priority: d.priority,
            requiredActivity: d.requiredActivity,
            stepByStep: d.stepByStep,
            minTime: d.minTime,
            dressCode: d.dressCode,
            requiredDocuments: d.requiredDocuments,
            latitude: d.latitude,
            longitude: d.longitude,
          ));
        }
      }

      // Ordenar as demandas da mais próxima para a mais longe
      filtered.sort((a, b) {
        final double distA = double.tryParse(a.distance.split(' ').first) ?? 99999.0;
        final double distB = double.tryParse(b.distance.split(' ').first) ?? 99999.0;
        return distA.compareTo(distB);
      });

      setState(() {
        _realDemands = filtered;
        _opportunityCount = _realDemands.length;
        _isLoadingDemands = false;
      });
    } catch (e) {
      print('Erro ao atualizar oportunidades: $e');
      setState(() {
        _isLoadingDemands = false;
      });
    }
  }



  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = math.cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: _buildPerfilTab(false),
      ),
    );
  }

  Widget _buildGlobalHeader(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final hPad = Responsive.value<double>(context, mobile: 16, tablet: 24, desktop: 30);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: mobile ? 14 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_userName.split(' ').first}!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: mobile ? 22 : 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  mobile ? 'Bons negócios hoje!' : 'Segunda-feira, 27 de Abril • Bons negócios hoje!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: mobile ? 12 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(mobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(IconsaxPlusLinear.notification, color: AppColors.textPrimary, size: mobile ? 20 : 24),
              ),
              SizedBox(width: mobile ? 10 : 16),
              InkWell(
                onTap: () => _showProfileModal(context),
                child: CircleAvatar(
                  radius: mobile ? 18 : 24,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    _getInitials(_userName),
                    style: TextStyle(color: Colors.white, fontSize: mobile ? 11 : 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget body = IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeTab(isDesktop),
        _buildLojasTab(isDesktop),
        _buildTarefasTab(isDesktop),
        _buildCheckInTab(isDesktop),
        _buildFinanceiroTab(isDesktop),
        _buildCurriculoTab(isDesktop),
        _buildMensagensTab(isDesktop),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false, 
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
      body: isDesktop 
        ? Row(
            children: [
              _buildDesktopSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildGlobalHeader(context),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          )
        : SafeArea(
            child: Column(
              children: [
                _buildGlobalHeader(context),
                Expanded(child: body),
              ],
            ),
          ),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.home_2), activeIcon: Icon(IconsaxPlusBold.home_2), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.shop), activeIcon: Icon(IconsaxPlusBold.shop), label: 'Diárias'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.task_square), activeIcon: Icon(IconsaxPlusBold.task_square), label: 'Tarefas'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.location), activeIcon: Icon(IconsaxPlusBold.location), label: 'Check-in'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.wallet_2), activeIcon: Icon(IconsaxPlusBold.wallet_2), label: 'Ganhos'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.document_text), activeIcon: Icon(IconsaxPlusBold.document_text), label: 'Currículo'),
          BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.message_2), activeIcon: Icon(IconsaxPlusBold.message_2), label: 'Mensagens'),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Row(
              children: [
                Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 32),
                SizedBox(width: 12),
                Text('CheckFast', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),
          _buildSidebarItem(0, IconsaxPlusLinear.home_2, 'Painel Geral'),
          _buildSidebarItem(1, IconsaxPlusLinear.shop, 'Diárias e Oportunidades'),
          _buildSidebarItem(2, IconsaxPlusLinear.task_square, 'Minhas Tarefas'),
          _buildSidebarItem(3, IconsaxPlusLinear.location, 'Jornada'),
          _buildSidebarItem(4, IconsaxPlusLinear.wallet_2, 'Financeiro'),
          _buildSidebarItem(5, IconsaxPlusLinear.document_text, 'Meu Currículo'),
          _buildSidebarItem(6, IconsaxPlusLinear.message_2, 'Mensagens'),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(IconsaxPlusBold.cup, color: AppColors.primaryBlue, size: 24),
                const SizedBox(height: 12),
                const Text('Aumente sua Renda', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Aceite mais diárias e ganhe bônus por produtividade.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, size: 22),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, 
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
                fontSize: 14
              )),
            ],
          ),
        ),
      ),
    );
  }

  // 1. TELA HOME
  Widget _buildHomeTab(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Hero Banner
        Builder(builder: (context) {
          final mobile = Responsive.isMobile(context);
          final heroPad = Responsive.value<double>(context, mobile: 24, tablet: 36, desktop: 48);
          final heroContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Você tem ', style: TextStyle(color: Colors.white, fontSize: mobile ? 20 : 28, fontWeight: FontWeight.w600)),
                TextSpan(text: '$_opportunityCount', style: TextStyle(color: Colors.white, fontSize: mobile ? 24 : 32, fontWeight: FontWeight.w900)),
                TextSpan(text: ' oportunidades\npróximas de você agora.', style: TextStyle(color: Colors.white, fontSize: mobile ? 20 : 28, fontWeight: FontWeight.w600, height: 1.2)),
              ])),
              SizedBox(height: mobile ? 20 : 32),
              ElevatedButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: mobile ? 14 : 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  mobile ? 'VER DIÁRIAS' : 'EXPLORAR DIÁRIAS DISPONÍVEIS',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              )
            ],
          );
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(heroPad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, Color(0xFF0052CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))
              ],
            ),
            child: _isLoadingDemands 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : mobile
                ? heroContent
                : Row(
                    children: [
                      Expanded(child: heroContent),
                      Icon(IconsaxPlusLinear.map_1, color: Colors.white.withOpacity(0.2), size: 120),
                    ],
                  ),
          );
        }),

            
            const SizedBox(height: 40),
            const Text('Resumo rápido', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            
            // Stats Grid
            Builder(builder: (context) {
              final mobile = Responsive.isMobile(context);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 4 : 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: mobile ? 1.8 : 2.2,
                children: [
                  _buildNewStatCard(IconsaxPlusLinear.task_square, 'Tarefas hoje', _tarefasHoje, 'Em andamento', AppColors.primaryBlue),
                  _buildNewStatCard(IconsaxPlusLinear.timer_1, 'Horas totais', _horasTotais, 'Registradas', AppColors.success),
                  _buildNewStatCard(IconsaxPlusLinear.wallet_2, 'Ganhos do mês', _ganhosMes, 'Total acumulado', Colors.purpleAccent),
                  _buildNewStatCard(IconsaxPlusLinear.calendar_1, 'Próximo pagamento', _proximoPagamento, 'Quarta-feira', AppColors.warning),
                ],
              );
            }),
            
            const SizedBox(height: 40),
            const Text('Avisos importantes', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            _buildNewAlertCard('Tudo em dia!', 'Você não possui check-outs pendentes hoje.', AppColors.success, 'Ver tarefas', () => setState(() => _selectedIndex = 2)),
            const SizedBox(height: 10),
            _buildNewAlertCard('Pronto para começar!', 'Aceite uma diária próxima a você para começar a faturar.', AppColors.primaryBlue, 'Ver diárias', () => setState(() => _selectedIndex = 1)),

            const SizedBox(height: 40),
            const Text('Ações rápidas', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 5 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionCard(IconsaxPlusLinear.shop, 'Diárias disponíveis', 'Ver oportunidades', AppColors.primaryBlue, 1),
                _buildQuickActionCard(IconsaxPlusLinear.task_square, 'Minhas tarefas', 'Ver tarefas aceitas', AppColors.primaryBlue, 2),
                _buildQuickActionCard(IconsaxPlusLinear.location, 'Check-in', 'Registrar presença', AppColors.success, 3),
                _buildQuickActionCard(IconsaxPlusLinear.wallet_2, 'Meus ganhos', 'Ver pagamentos', Colors.purpleAccent, 4),
                _buildQuickActionCard(IconsaxPlusLinear.document_text, 'Meu Currículo', 'Gerenciar currículo', Colors.orangeAccent, 5),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNewStatCard(IconData icon, String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNewAlertCard(String title, String subtitle, Color color, String btnText, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;
        final inner = [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(IconsaxPlusBold.info_circle, color: Colors.white, size: 20),
          ),
          SizedBox(width: narrow ? 0 : 24, height: narrow ? 12 : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              narrow
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: inner)
                  : Row(children: inner),
              SizedBox(height: narrow ? 16 : 0),
              Align(
                alignment: narrow ? Alignment.centerLeft : Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String subtitle, Color color, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.textSecondary, size: 18)
          ],
        ),
      ),
    );
  }

  // 2. TELA LOJAS (DIÁRIAS)
  Widget _buildLojasTab(bool isDesktop) {
    if (_isLoadingDemands) return const Center(child: CircularProgressIndicator());

    final radiusSelector = Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(IconsaxPlusLinear.location, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Endereço: ${_userBairro.isNotEmpty ? '$_userBairro, ' : ''}$_userCity (CEP $_userCep)',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('FILTRAR DIÁRIAS POR DISTÂNCIA:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRadiusChip(10.0, 'Até 10 km'),
                _buildRadiusChip(15.0, 'Até 15 km'),
                _buildRadiusChip(20.0, 'Até 20 km'),
                _buildRadiusChip(50.0, 'Até 50 km'),
                _buildRadiusChip(99999.0, 'Ver todas'),
              ],
            ),
          ),
        ],
      ),
    );

    final storeCards = _realDemands.map((d) {
      return _buildStoreCard(
        d.storeName, 
        d.network, 
        d.distance, 
        'R\$ ${d.value.toStringAsFixed(2)}', 
        d.urgency, 
        AppColors.success,
        demand: d,
      );
    }).toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumHeader(
                  title: 'DIÁRIAS DISPONÍVEIS', 
                  subtitle: 'Encontre e aceite oportunidades próximas a você.',
                ),
                const SizedBox(height: 25),
                radiusSelector,
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.neonCyan,
                    backgroundColor: AppColors.cardDark,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      _updateOpportunityCount();
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: storeCards.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: _buildEmptyStateCard(),
                            ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: storeCards,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusChip(double radius, String label) {
    final isSelected = _selectedRadius == radius;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedRadius = radius;
            });
            _updateOpportunityCount();
          }
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppColors.primaryBlue.withOpacity(0.1),
        labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.primaryBlue.withOpacity(0.3) : Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(IconsaxPlusLinear.location_slash, size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma diária em até ${_selectedRadius < 9999.0 ? '${_selectedRadius.toInt()} km' : 'seu raio'}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Você está em ${_userBairro.isNotEmpty ? '$_userBairro, ' : ''}$_userCity (CEP $_userCep).\nNo momento, não há diárias ativas dentro deste limite geográfico.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          if (_selectedRadius < 50.0)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRadius = 50.0;
                });
                _updateOpportunityCount();
              },
              icon: const Icon(Icons.zoom_out_map, size: 18),
              label: const Text('EXPANDIR RAIO PARA 50 KM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRadius = 99999.0;
              });
              _updateOpportunityCount();
            },
            child: const Text('MOSTRAR TODAS AS DIÁRIAS DO PAINEL', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          )
        ],
      ),
    );
  }


  // 3. TELA TAREFAS
  Widget _buildTarefasTab(bool isDesktop) {
    return _buildListTab(
      isDesktop,
      'MINHAS TAREFAS', 
      'Acompanhe suas tarefas e status de execução.', 
      []
    );
  }

  // 4. TELA CHECK-IN (CRÍTICA)
  Widget _buildCheckInTab(bool isDesktop) {
    return CheckInTabView(isDesktop: isDesktop, userCpf: _userCpf);
  }

  // 5. RECEBIMENTOS (FINANCEIRO)
  Widget _buildFinanceiroTab(bool isDesktop) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const PremiumHeader(title: 'Extrato Geral', subtitle: 'Acompanhe os pagamentos das suas diárias.'),
            const SizedBox(height: 30),
            
            // BI DASHBOARD (GRID)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _buildBICard(_aReceber, 'A receber', AppColors.primaryBlue),
                _buildBICard(_pagoNoMes, 'Pago no mês', AppColors.success),
                _buildBICard(_emAnalise, 'Em análise', AppColors.warning),
                _buildBICard('R\$ 0,00', 'Não apto', Colors.redAccent),
              ],
            ),
            
            const SizedBox(height: 30),
            _buildSectionHeader('FILTRAR POR'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              child: Row(
                children: ['Todos', 'A receber', 'Pagos', 'Em análise'].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 10), 
                  child: ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 11)), 
                    selected: f == 'Todos', 
                    onSelected: (_) {}, 
                    backgroundColor: AppColors.background, 
                    selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                    labelStyle: TextStyle(color: f == 'Todos' ? AppColors.primaryBlue : AppColors.textSecondary),
                  )
                )).toList()
              )
            ),
            
            const SizedBox(height: 25),
            _buildSectionHeader('LISTA DE RECEBIMENTOS'),
            Expanded(
              child: ListView(
                children: [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'Nenhum recebimento registrado ainda.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildBICard(String value, String label, Color color) => PremiumCard(
    padding: const EdgeInsets.all(24), 
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)), 
        const SizedBox(height: 8), 
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8))
      ]
    )
  );
  
  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16), 
    child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2))
  );

  // 6. PERFIL
  Widget _buildPerfilTab(bool isDesktop) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
          children: [
            CircleAvatar(
              radius: 48, 
              backgroundColor: AppColors.lightBlue, 
              child: Text(_getInitials(_userName), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 32, fontWeight: FontWeight.w900))
            ),
            const SizedBox(height: 24),
            Text(_userName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Text('CPF: $_userCpf • Nível Diamante', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            _buildProfileItem(IconsaxPlusLinear.edit, 'Editar Meus Dados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView())).then((_) => _loadUserData())),
            _buildProfileItem(IconsaxPlusLinear.card_receive, 'Minha Chave PIX', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PixKeyView()))),
            _buildProfileItem(IconsaxPlusLinear.support, 'Suporte CheckFast', onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'suporte@checkfast.com',
                queryParameters: {'subject': 'Suporte CheckFast - Ricardo Souza'}
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }
            }),
            const Spacer(),
            _buildProfileItem(IconsaxPlusLinear.logout, 'Sair do Aplicativo', color: Colors.redAccent, onTap: () => Navigator.pushReplacementNamed(context, '/')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    )));
  }

  // AUXILIARES DE UI
  Widget _buildListTab(bool isDesktop, String title, String subtitle, List<Widget> children) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 25),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.neonCyan,
                backgroundColor: AppColors.cardDark,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: children.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'Nenhum item encontrado.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: children
                      ),
              ),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 15),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStoreCard(String name, String network, String dist, String val, String tag, Color color, {AppDemand? demand}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(network, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(demand?.address ?? 'Rua Gago Coutinho, 350 - Lapa, SP', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSimpleInfo(IconsaxPlusLinear.location, dist),
                _buildSimpleInfo(IconsaxPlusLinear.briefcase, demand?.role ?? 'Promotor'),
                _buildSimpleInfo(IconsaxPlusLinear.timer_1, demand?.timeRange ?? '08h-14h'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.cardBorder, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(val, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreDetailView(demand: demand))), 
                      child: const Text('DETALHES', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800))
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (demand != null) {
                          DemandOnboardingFlow.show(
                            context,
                            demand: demand,
                            userCpf: _userCpf,
                          );
                        }
                      }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue, 
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ), 
                      child: const Text('ACEITAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSimpleInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: AppColors.primaryBlue, size: 14), 
      const SizedBox(width: 6), 
      Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))
    ]
  );

  Widget _buildTaskCard(String loc, String network, String date, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          if (status == 'AGENDADA') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreDetailView()));
          } else if (status != 'CANCELADA') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TaskTimelineView(storeName: loc, status: status)));
          }
        },

        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('$network • $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary.withOpacity(0.3), size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String loc, String date, String val, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentDetailsView(storeName: loc, status: status, value: val, date: date))),
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Projeto: Reposição Verão', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Executado em: $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  const Text('Prev: 05/05', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    final textColor = color ?? AppColors.textPrimary;
    final iconColor = color ?? AppColors.primaryBlue;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 20),
              Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Icon(IconsaxPlusLinear.arrow_right_3, color: textColor.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculoTab(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(IconsaxPlusBold.document_text, color: Colors.orangeAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meu Currículo Profissional',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mantenha seu perfil de promotor atualizado para as marcas parceiras e receba diárias exclusivas.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Layout Responsivo
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCurriculoFormCard(context, isDesktop)),
                        const SizedBox(width: 30),
                        Expanded(flex: 2, child: _buildCurriculoPreviewCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildCurriculoFormCard(context, isDesktop),
                        const SizedBox(height: 30),
                        _buildCurriculoPreviewCard(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculoFormCard(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão de Salvar Rápido Superior
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _salvarCurriculoCompleto(context),
              icon: const Icon(IconsaxPlusBold.document_text, color: Colors.white, size: 20),
              label: const Text('SALVAR TODAS AS SEÇÕES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),

        // 1. Dados Pessoais
        _buildAccordionSection(0, '1. Dados Pessoais', IconsaxPlusLinear.user, Column(
          children: [
            _buildField('Nome Completo', TextEditingController(text: _userName), readOnly: true),
            _buildField('Nome Social', _nomeSocialController),
            _buildField('CPF', TextEditingController(text: _userCpf), readOnly: true),
            Row(
              children: [
                Expanded(child: _buildField('RG', _rgController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Órgão Emissor', _orgaoEmissorController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildField('Data de Nascimento', _nascimentoController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Idade', _idadeController, type: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildField('Sexo', _sexoController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Estado Civil', _estadoCivilController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildField('Nacionalidade', _nacionalidadeController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Naturalidade', _naturalidadeController)),
              ],
            ),
            _buildField('E-mail', TextEditingController(text: _userEmail), readOnly: true),
            Row(
              children: [
                Expanded(child: _buildField('Telefone Principal', TextEditingController(text: _userPhone), readOnly: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Telefone Secundário', _telSecundarioController)),
              ],
            ),
            _buildField('WhatsApp', _whatsappController),
            _buildField('LinkedIn', _linkedinController),
            _buildField('Instagram Profissional', _instagramController),
            const SizedBox(height: 12),
            const Text('Endereço Residencial', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            _buildField('CEP', TextEditingController(text: _userCep), readOnly: true),
            _buildField('Rua / Logradouro', TextEditingController(text: _userRua), readOnly: true),
            Row(
              children: [
                Expanded(child: _buildField('Bairro', TextEditingController(text: _userBairro), readOnly: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Cidade', TextEditingController(text: _userCity), readOnly: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('UF', TextEditingController(text: _userUf), readOnly: true)),
              ],
            ),
          ],
        )),

        // 2. Documentação
        _buildAccordionSection(1, '2. Documentação', IconsaxPlusLinear.card, Column(
          children: [
            _buildField('CNH', _cnhController),
            _buildDropdownField('Categoria CNH', _cnhCategoria, ['A', 'B', 'AB', 'C', 'D', 'E', 'Não possui'], (val) {
              if (val != null) setState(() => _cnhCategoria = val);
            }),
            _buildField('Validade CNH', _cnhValidadeController),
            const SizedBox(height: 10),
            _buildSwitchField('Possui Veículo Próprio', _possuiVeiculoProprio, (val) => setState(() => _possuiVeiculoProprio = val)),
            if (_possuiVeiculoProprio) ...[
              _buildDropdownField('Tipo de Veículo', _tipoVeiculo, ['Moto', 'Carro', 'Ambos'], (val) {
                if (val != null) setState(() => _tipoVeiculo = val);
              }),
              _buildField('Documento do Veículo', _docVeiculoController),
            ],
            _buildSwitchField('Possui Moto', _possuiMoto, (val) => setState(() => _possuiMoto = val)),
            _buildSwitchField('Possui Carro', _possuiCarro, (val) => setState(() => _possuiCarro = val)),
            _buildSwitchField('Possui MEI', _possuiMei, (val) => setState(() => _possuiMei = val)),
            _buildSwitchField('Possui CNPJ', _possuiCnpj, (val) => setState(() => _possuiCnpj = val)),
            _buildField('Número do PIS', _pisController),
            _buildField('Título de Eleitor', _tituloEleitorController),
            _buildField('Certificado de Reservista', _reservistaController),
            _buildField('Dados Bancários', _contaBancariaController),
            _buildField('Chave PIX', _chavePixController),
          ],
        )),

        // 3. Disponibilidade
        _buildAccordionSection(2, '3. Disponibilidade', IconsaxPlusLinear.clock, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField('Disponibilidade de Horário', _disponibilidadeHorario, ['Período Integral', 'Manhã', 'Tarde', 'Noite', 'Finais de Semana'], (val) {
              if (val != null) setState(() => _disponibilidadeHorario = val);
            }),
            const SizedBox(height: 10),
            _buildSwitchField('Finais de Semana', _dispFinaisSemana, (val) => setState(() => _dispFinaisSemana = val)),
            _buildSwitchField('Viagens', _dispViagens, (val) => setState(() => _dispViagens = val)),
            _buildSwitchField('Pernoite', _dispPernoite, (val) => setState(() => _dispPernoite = val)),
            _buildSwitchField('Ações Temporárias', _dispAcoesTemporarias, (val) => setState(() => _dispAcoesTemporarias = val)),
            _buildSwitchField('Disponibilidade para CLT', _dispClt, (val) => setState(() => _dispClt = val)),
            _buildSwitchField('Disponibilidade para PJ', _dispPj, (val) => setState(() => _dispPj = val)),
            _buildSwitchField('Disponibilidade para Freelancer', _dispFreelancer, (val) => setState(() => _dispFreelancer = val)),
            _buildSwitchField('Disponibilidade Imediata', _dispImediata, (val) => setState(() => _dispImediata = val)),
            _buildField('Região de Atuação', _regiaoAtuacaoController),
            const SizedBox(height: 10),
            Text('Raio de Deslocamento: ${_raioDeslocamento.toInt()} KM', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            Slider(
              value: _raioDeslocamento,
              min: 5.0,
              max: 100.0,
              divisions: 19,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _raioDeslocamento = val),
            ),
            const SizedBox(height: 15),
            const Text('Aceita Atuar Em:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _buildCheckboxGrid(_tiposAcoesFlags, cols: 2),
          ],
        )),

        // 4. Dados Profissionais
        _buildAccordionSection(3, '4. Dados Profissionais', IconsaxPlusLinear.briefcase, Column(
          children: [
            _buildField('Objetivo Profissional', _objetivoProfissionalController),
            _buildField('Cargo Atual', _cargoAtualController),
            _buildField('Último Cargo', _ultimoCargoController),
            _buildField('Área de Atuação', _areaAtuacaoController),
            _buildField('Tempo de Experiência', _tempoExperienciaController),
            Row(
              children: [
                Expanded(child: _buildField('Pretensão Salarial', _pretensaoSalarialController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Último Salário', _ultimoSalarioController)),
              ],
            ),
            _buildDropdownField('Tipo de Contratação Desejada', _tipoContratacaoDesejada, ['Freelancer', 'CLT', 'PJ', 'Freelancer / CLT', 'Todas'], (val) {
              if (val != null) setState(() => _tipoContratacaoDesejada = val);
            }),
            _buildDropdownField('Nível Profissional', _nivelProfissional, ['Auxiliar', 'Assistente', 'Analista', 'Supervisor', 'Coordenador', 'Gerente', 'Diretor'], (val) {
              if (val != null) setState(() => _nivelProfissional = val);
            }),
          ],
        )),

        // 5. Experiências Profissionais
        _buildAccordionSection(4, '5. Experiências Profissionais', IconsaxPlusLinear.archive, Column(
          children: [
            ..._experienciasLista.asMap().entries.map((entry) {
              final index = entry.key;
              final exp = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Experiência #${index + 1}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.trash, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() {
                              _experienciasLista.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildListItemField(exp, 'empresa', 'Empresa'),
                    _buildListItemField(exp, 'cargo', 'Cargo'),
                    _buildListItemField(exp, 'segmento', 'Segmento'),
                    Row(
                      children: [
                        Expanded(child: _buildListItemField(exp, 'dataEntrada', 'Entrada')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildListItemField(exp, 'dataSaida', 'Saída')),
                      ],
                    ),
                    _buildListItemField(exp, 'tipoContratacao', 'Contratação'),
                    _buildListItemField(exp, 'atividades', 'Principais Atividades'),
                    _buildListItemField(exp, 'resultados', 'Resultados Alcançados'),
                    _buildListItemField(exp, 'motivoSaida', 'Motivo da Saída'),
                    _buildListItemField(exp, 'gestor', 'Nome do Gestor'),
                    _buildListItemField(exp, 'contatoGestor', 'Contato do Gestor'),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _experienciasLista.add({
                      'empresa': '',
                      'cargo': '',
                      'segmento': '',
                      'dataEntrada': '',
                      'dataSaida': '',
                      'tipoContratacao': '',
                      'atividades': '',
                      'resultados': '',
                      'motivoSaida': '',
                      'gestor': '',
                      'contatoGestor': '',
                    });
                  });
                },
                icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                label: const Text('ADICIONAR EXPERIÊNCIA', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        )),

        // 6. Experiência em Trade Marketing
        _buildAccordionSection(5, '6. Experiência em Trade Marketing', IconsaxPlusLinear.star, Column(
          children: [
            _buildCheckboxGrid(_tradeMarketingFlags, cols: isDesktop ? 3 : 2),
          ],
        )),

        // 7. Experiência por Redes
        _buildAccordionSection(6, '7. Experiência por Redes', IconsaxPlusLinear.shop, Column(
          children: [
            _buildCheckboxGrid(_redesFlags, cols: isDesktop ? 3 : 2),
          ],
        )),

        // 8. Experiência por Marcas
        _buildAccordionSection(7, '8. Experiência por Marcas', IconsaxPlusLinear.medal, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecione as marcas com as quais já realizou ações:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._marcasDisponiveis.map((brand) {
                  final isSelected = _marcasSelecionadas.contains(brand);
                  return ChoiceChip(
                    label: Text(brand, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.background,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _marcasSelecionadas.add(brand);
                        } else {
                          _marcasSelecionadas.remove(brand);
                        }
                      });
                    },
                  );
                }).toList(),
                ActionChip(
                  avatar: const Icon(Icons.add, color: AppColors.primaryBlue, size: 16),
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.05),
                  side: const BorderSide(color: AppColors.primaryBlue, width: 0.8),
                  label: const Text('CADASTRAR MARCA', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12)),
                  onPressed: () => _mostrarDialogoCadastrarMarca(context),
                ),
              ],
            ),
          ],
        )),

        // 9. Escolaridade
        _buildAccordionSection(8, '9. Escolaridade', IconsaxPlusLinear.teacher, Column(
          children: [
            _buildDropdownField('Grau de Escolaridade', _escolaridadeSelecionada, [
              'Ensino Fundamental Completo',
              'Ensino Médio Incompleto',
              'Ensino Médio Completo',
              'Ensino Superior Incompleto',
              'Ensino Superior Completo',
            ], (val) {
              if (val != null) setState(() => _escolaridadeSelecionada = val);
            }),
            _buildField('Curso / Habilitação', _cursoController),
            _buildField('Instituição de Ensino', _instituicaoController),
            Row(
              children: [
                Expanded(child: _buildDropdownField('Status', _escolaridadeStatus, ['Completo', 'Cursando', 'Trancado'], (val) {
                  if (val != null) setState(() => _escolaridadeStatus = val);
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Ano de Conclusão', _anoConclusaoController)),
              ],
            ),
          ],
        )),

        // 10. Cursos e Certificações
        _buildAccordionSection(9, '10. Cursos e Certificações', IconsaxPlusLinear.document_favorite, Column(
          children: [
            _buildField('Nome do Curso', _cursoNomeController),
            _buildField('Instituição', _cursoInstController),
            Row(
              children: [
                Expanded(child: _buildField('Carga Horária', _cursoCargaController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Data de Conclusão', _cursoConclusaoController)),
              ],
            ),
            _buildSwitchField('Certificado Anexado', _certificadoAnexado, (val) => setState(() => _certificadoAnexado = val)),
          ],
        )),

        // 11. Habilidades
        _buildAccordionSection(10, '11. Habilidades', IconsaxPlusLinear.setting_4, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Habilidades Técnicas', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 10),
            _buildCheckboxGrid(_habilidadesTecnicas, cols: 2),
            const SizedBox(height: 20),
            const Text('Habilidades Comportamentais', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 10),
            _buildCheckboxGrid(_habilidadesComportamentais, cols: 2),
          ],
        )),

        // 12. Idiomas
        _buildAccordionSection(11, '12. Idiomas', IconsaxPlusLinear.global, Column(
          children: [
            ..._idiomasLista.asMap().entries.map((entry) {
              final index = entry.key;
              final lang = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildListItemField(lang, 'idioma', 'Idioma'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField('Nível', lang['nivel'] ?? 'Básico', ['Básico', 'Intermediário', 'Avançado', 'Fluente'], (val) {
                        if (val != null) {
                          setState(() {
                            lang['nivel'] = val;
                          });
                        }
                      }),
                    ),
                    IconButton(
                      icon: const Icon(IconsaxPlusLinear.trash, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          _idiomasLista.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _idiomasLista.add({'idioma': '', 'nivel': 'Básico'});
                });
              },
              icon: const Icon(Icons.add, color: AppColors.primaryBlue),
              label: const Text('ADICIONAR IDIOMA', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        )),

        // 13. Anexos
        _buildAccordionSection(12, '13. Anexos', IconsaxPlusLinear.paperclip, Column(
          children: [
            _buildAttachmentRow('Currículo PDF', _attachedFileName, (name) => setState(() => _attachedFileName = name)),
            _buildAttachmentRow('Foto Profissional', _anexoFotoProfissional, (name) => setState(() => _anexoFotoProfissional = name)),
            _buildAttachmentRow('CNH', _anexoCnh, (name) => setState(() => _anexoCnh = name)),
            _buildAttachmentRow('Certificados', _anexoCertificados, (name) => setState(() => _anexoCertificados = name)),
            _buildAttachmentRow('Comprovante de Residência', _anexoResidencia, (name) => setState(() => _anexoResidencia = name)),
            _buildAttachmentRow('Portfólio', _anexoPortfolio, (name) => setState(() => _anexoPortfolio = name)),
            _buildAttachmentRow('Vídeo Apresentação', _anexoVideo, (name) => setState(() => _anexoVideo = name)),
          ],
        )),

        // 14. Avaliação Interna (Uso da Empresa)
        _buildAccordionSection(13, '14. Avaliação Interna (RH)', IconsaxPlusLinear.shield_security, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score Geral do Candidato', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                        child: Text('$_scoreCandidato / 10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ranking Geral', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text(_rankingCandidato, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('AVALIAÇÃO DO RH', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Text(_avaliacaoRh, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            const Text('AVALIAÇÃO DO GESTOR', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Text(_avaliacaoGestor, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildBadgeDetail('Entrevista', _ultimaEntrevista)),
                const SizedBox(width: 12),
                Expanded(child: _buildBadgeDetail('Recontratável', _recontratavel ? 'Sim' : 'Não', isSuccess: _recontratavel)),
                const SizedBox(width: 12),
                Expanded(child: _buildBadgeDetail('Blacklist', _blacklist ? 'Sim' : 'Não', isDanger: _blacklist)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildBadgeDetail('Nota Comportamental', _notaComportamental)),
                const SizedBox(width: 12),
                Expanded(child: _buildBadgeDetail('Nota Técnica', _notaTecnica)),
              ],
            ),
            const SizedBox(height: 15),
            _buildBadgeDetail('Status Interno', _statusCandidato.toUpperCase(), isSuccess: _statusCandidato == 'Aprovado' || _statusCandidato == 'Contratado'),
          ],
        )),

        // 15. Campos Inteligentes
        _buildAccordionSection(14, '15. Campos Inteligentes (Automatizados)', IconsaxPlusLinear.flash, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tags geradas de forma inteligente com base no perfil:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _gerarTagsInteligentes().map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        )),

        // 16. Flags Operacionais
        _buildAccordionSection(15, '16. Flags Operacionais', IconsaxPlusLinear.setting, Column(
          children: [
            _buildCheckboxGrid(_flagsOperacionais, cols: isDesktop ? 2 : 1),
          ],
        )),
      ],
    );
  }

  Widget _buildCurriculoPreviewCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ficha do Candidato', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PREVIEW', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Divider(height: 30, color: AppColors.cardBorder),

          // Foto fictícia e Cabeçalho do CV
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text(
                  _getInitials(_userName),
                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('$_nivelProfissional • $_userCity', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Informações de Contato
          const Text('CONTATO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.call, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 10),
              Text(_userPhone, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.sms, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 10),
              Text(_userEmail, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.location, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 10),
              Text('$_userBairro, $_userCity - $_userUf', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),

          // Escolaridade
          const Text('ESCOLARIDADE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(_escolaridadeSelecionada, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          // Resumo
          const Text('RESUMO PROFISSIONAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(
            _resumoController.text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // Experiências
          const Text('EXPERIÊNCIAS ANTERIORES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(
            _experienciasController.text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // Marcas Selecionadas
          if (_marcasSelecionadas.isNotEmpty) ...[
            const Text('MARCAS COM EXPERIÊNCIA', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _marcasSelecionadas.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                  child: Text(m, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w700)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES E WIDGETS DO NOVO CURRÍCULO COMPLETO ---

  Widget _buildAccordionSection(int index, String title, IconData icon, Widget content) {
    final isOpen = _activeAccordionIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOpen ? AppColors.primaryBlue.withOpacity(0.5) : AppColors.cardBorder),
          boxShadow: isOpen
              ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _activeAccordionIndex = isOpen ? -1 : index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.primaryBlue.withOpacity(0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: isOpen ? AppColors.primaryBlue : AppColors.textSecondary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isOpen ? AppColors.primaryBlue : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      isOpen ? IconsaxPlusLinear.arrow_up_2 : IconsaxPlusLinear.arrow_down_1,
                      color: isOpen ? AppColors.primaryBlue : AppColors.textSecondary.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen) ...[
              const Divider(height: 1, color: AppColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool readOnly = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: type,
            style: TextStyle(color: readOnly ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              fillColor: readOnly ? AppColors.background : Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
            onChanged: (val) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                onChanged: onChanged,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGrid(Map<String, bool> flags, {int cols = 2}) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final itemWidth = width / cols - 10;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: flags.keys.map((key) {
          final isChecked = flags[key] == true;
          return SizedBox(
            width: itemWidth,
            child: InkWell(
              onTap: () {
                setState(() {
                  flags[key] = !isChecked;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() {
                        flags[key] = val == true;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(key, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildListItemField(Map<String, String> item, String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: item[key])..selection = TextSelection.fromPosition(TextPosition(offset: (item[key] ?? "").length)),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
            onChanged: (val) {
              item[key] = val;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(String label, String fileName, ValueChanged<String> onUploaded) {
    final hasFile = fileName.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? fileName : 'Nenhum arquivo anexado',
                    style: TextStyle(color: hasFile ? AppColors.success : AppColors.textSecondary, fontSize: 12, fontWeight: hasFile ? FontWeight.w800 : FontWeight.normal),
                  ),
                ],
              ),
            ),
            hasFile
                ? TextButton(
                    onPressed: () => onUploaded(""),
                    child: const Text('REMOVER', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 12)),
                  )
                : ElevatedButton(
                    onPressed: () {
                      onUploaded("Anexo_${label.replaceAll(' ', '_')}.pdf");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📄 $label anexado com sucesso!'), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue.withOpacity(0.1), elevation: 0),
                    child: const Text('ANEXAR', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeDetail(String label, String value, {bool isSuccess = false, bool isDanger = false}) {
    Color bg = AppColors.background;
    Color fg = AppColors.textPrimary;
    if (isSuccess) {
      bg = AppColors.success.withOpacity(0.1);
      fg = AppColors.success;
    } else if (isDanger) {
      bg = Colors.redAccent.withOpacity(0.1);
      fg = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _salvarCurriculoCompleto(BuildContext context) async {
    setState(() => _hasSavedCv = true);
    // Salvar currículo no Firestore
    try {
      final url = Uri.parse('https://firestore.googleapis.com/v1/projects/checkfast-28a72/databases/(default)/documents/users/$_userCpf');
      final res = await http.patch(
        Uri.parse('$url?updateMask.fieldPaths=curriculum_resumo&updateMask.fieldPaths=curriculum_experiencias&updateMask.fieldPaths=curriculum_escolaridade&updateMask.fieldPaths=curriculum_attached_pdf&updateMask.fieldPaths=curriculum_completo_dados'),
        body: jsonEncode({
          'fields': {
            'curriculum_resumo': {'stringValue': _resumoController.text},
            'curriculum_experiencias': {'stringValue': _experienciasController.text},
            'curriculum_escolaridade': {'stringValue': _escolaridadeSelecionada},
            'curriculum_attached_pdf': {'stringValue': _attachedFileName},
            'curriculum_completo_dados': {'stringValue': jsonEncode({
              'dados_pessoais': {
                'nome_social': _nomeSocialController.text,
                'rg': _rgController.text,
                'orgao_emissor': _orgaoEmissorController.text,
                'whatsapp': _whatsappController.text,
                'linkedin': _linkedinController.text,
                'instagram': _instagramController.text,
              },
              'documentacao': {
                'cnh': _cnhController.text,
                'cnh_categoria': _cnhCategoria,
                'veiculo_proprio': _possuiVeiculoProprio,
                'carro': _possuiCarro,
                'moto': _possuiMoto,
                'mei': _possuiMei,
              },
              'disponibilidade': {
                'horarios': _disponibilidadeHorario,
                'raio': _raioDeslocamento,
                'imediata': _dispImediata,
              },
              'marcas_disponiveis': _marcasDisponiveis,
              'marcas_selecionadas': _marcasSelecionadas,
            })}
          }
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Currículo salvo e atualizado com sucesso no Firestore!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Erro ao salvar CV no Firestore: $e');
    }
  }

  void _mostrarDialogoCadastrarMarca(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(IconsaxPlusBold.medal, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Nova Marca', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cadastre uma marca customizada para deixar salva no seu perfil.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Nome da Marca',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (!_marcasDisponiveis.contains(name)) {
                      _marcasDisponiveis.add(name);
                    }
                    if (!_marcasSelecionadas.contains(name)) {
                      _marcasSelecionadas.add(name);
                    }
                  });
                  // Salvar localmente
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setStringList('marcas_disponiveis', _marcasDisponiveis);
                    prefs.setStringList('marcas_selecionadas', _marcasSelecionadas);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ Marca "$name" cadastrada e selecionada!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CADASTRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMensagensTab(bool isDesktop) {
    final cleanCPF = _userCpf.replaceAll(RegExp(r'\D'), '');

    // Reset unread count for promoter when opening messages
    FirebaseFirestore.instance
        .collection('support_chats')
        .doc(cleanCPF)
        .update({'unreadCountPromoter': 0}).catchError((_) {});

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suporte CheckFast',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isDesktop ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fale diretamente com nossa equipe de suporte.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              // Topic selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _chatTopic,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'Operacional', child: Text('Canal: Operacional')),
                      DropdownMenuItem(value: 'Financeiro', child: Text('Canal: Financeiro')),
                      DropdownMenuItem(value: 'RH', child: Text('Canal: Recursos Humanos')),
                      DropdownMenuItem(value: 'Suporte Técnico', child: Text('Canal: Suporte Técnico')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _chatTopic = val);
                        FirebaseFirestore.instance
                            .collection('support_chats')
                            .doc(cleanCPF)
                            .set({'topic': val}, SetOptions(merge: true));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chat body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Stream Builder of messages
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('support_chats')
                            .doc(cleanCPF)
                            .collection('messages')
                            .orderBy('createdAt')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                          }
                          final docs = snapshot.data?.docs ?? [];
                          
                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconsaxPlusLinear.message_2, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  const Text('Inicie sua conversa', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  const Text('Envie uma mensagem para falar com o suporte.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            );
                          }

                          // Trigger auto scroll to bottom on new messages
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());

                          return ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final role = data['senderRole'] ?? '';
                              final text = data['text'] ?? '';
                              final isMe = role == 'promoter';
                              final senderName = data['senderName'] ?? 'Suporte';
                              final timeStr = _formatMessageTime(data['createdAt']);

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primaryBlue : AppColors.background,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    border: isMe ? null : Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          senderName,
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      if (!isMe) const SizedBox(height: 4),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.textPrimary,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Composer bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: TextField(
                                controller: _chatMessageController,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendChatMessage(),
                                decoration: const InputDecoration(
                                  hintText: 'Digite sua mensagem...',
                                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _sendChatMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Icon(IconsaxPlusBold.send_1, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage() async {
    final text = _chatMessageController.text.trim();
    if (text.isEmpty) return;
    _chatMessageController.clear();
    
    final cleanCPF = _userCpf.replaceAll(RegExp(r'\D'), '');
    final now = DateTime.now().toIso8601String();
    
    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(cleanCPF)
          .collection('messages')
          .add({
        'senderId': cleanCPF,
        'senderName': _userName,
        'senderRole': 'promoter',
        'text': text,
        'createdAt': now,
        'read': false,
      });
      
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(cleanCPF)
          .set({
        'id': cleanCPF,
        'promoterCpf': cleanCPF,
        'promoterName': _userName,
        'topic': _chatTopic,
        'lastMessage': text,
        'lastMessageTime': now,
        'lastSenderRole': 'promoter',
        'unreadCountAdmin': FieldValue.increment(1),
        'unreadCountPromoter': 0,
        'updatedAt': now,
      }, SetOptions(merge: true));
      
      _scrollChatToBottom();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }

  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }
}
