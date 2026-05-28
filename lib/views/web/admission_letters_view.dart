import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import '../../core/constants/premium_theme.dart';
import '../../models/register_models.dart';
import '../../models/app_models.dart';

class AdmissionLettersView extends StatefulWidget {
  const AdmissionLettersView({super.key});

  @override
  State<AdmissionLettersView> createState() => _AdmissionLettersViewState();
}

class ActiveAllocation {
  final String applicationId;
  final AppUser promoter;
  final AppDemand demand;
  final String status;

  ActiveAllocation({
    required this.applicationId,
    required this.promoter,
    required this.demand,
    required this.status,
  });
}

class _AdmissionLettersViewState extends State<AdmissionLettersView> {
  bool _loading = true;
  bool _isAutoMode = true;
  bool _isTrainingModeLetter = true;

  List<AppUser> _promoters = [];
  List<AppDemand> _demands = [];
  List<ActiveAllocation> _allAllocations = [];
  List<ActiveAllocation> _allocations = [];

  ActiveAllocation? _selectedAllocation;
  AppUser? _selectedPromoter;
  AppDemand? _selectedDemand;

  // Editable fields based on Megapromo's letter template
  final _companyNameController = TextEditingController(text: 'MEGA WORLD SERVICOS DE TERCEIRIZACAO E MARKETING LTDA');
  final _recipientController = TextEditingController(text: 'Atacadão S/A');
  
  final _promoterNameController = TextEditingController();
  final _promoterCpfController = TextEditingController();
  final _promoterRgController = TextEditingController();
  
  final _roleController = TextEditingController(text: 'OPERADOR DE CAIXA AUTÔNOMO');
  final _roleShortController = TextEditingController(text: 'OPERADOR DE CAIXA');
  
  final _cityDateController = TextEditingController(text: 'Barueri');

  // Stamp Box details
  final _stampCnpjController = TextEditingController(text: '60.970.093/0001-09');
  final _stampCompanyController = TextEditingController(text: 'MEGA WORLD SERVIÇOS DE TERCEIRIZAÇÃO\nE MARKETING LTDA');
  final _stampAddressController = TextEditingController(text: 'AV MARCOS PENTEADO DE ULHOA RODRIGUES, 939 - TAMBORÉ\nBARUERI / SP - 06.460-040');

  // Signature
  final _signatureTitleController = TextEditingController(text: 'MEGA WORLD SERVICOS DE TERCEIRIZACAO\nE MARKETING LTDA');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _recipientController.dispose();
    _promoterNameController.dispose();
    _promoterCpfController.dispose();
    _promoterRgController.dispose();
    _roleController.dispose();
    _roleShortController.dispose();
    _cityDateController.dispose();
    _stampCnpjController.dispose();
    _stampCompanyController.dispose();
    _stampAddressController.dispose();
    _signatureTitleController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getCurriculumData(AppUser user) {
    if (user.curriculumCompletoDados == null || user.curriculumCompletoDados!.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(user.curriculumCompletoDados!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch Promoters
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'prestador')
          .get();
      final promoters = userSnapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();

      // 2. Fetch Demands
      final demandSnapshot = await FirebaseFirestore.instance.collection('demands').get();
      final demands = demandSnapshot.docs.map((doc) => AppDemand.fromMap(doc.data()..['id'] = doc.id)).toList();

      // 3. Fetch Applications with relevant statuses
      final appSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('status', whereIn: ['treinamento', 'tarefa_aprovada', 'aprovado', 'selecionado'])
          .get();

      final List<ActiveAllocation> allAllocations = [];
      for (var doc in appSnapshot.docs) {
        final appData = doc.data();
        final String promoterCpf = appData['promoterCpf'] ?? '';
        final String demandId = appData['demandId'] ?? '';
        final String status = appData['status'] ?? '';

        final promoter = promoters.firstWhere((p) => p.id == promoterCpf, orElse: () => AppUser(id: promoterCpf, name: 'Promotor ($promoterCpf)', email: ''));
        final demand = demands.firstWhere((d) => d.id == demandId, orElse: () => AppDemand(
          id: demandId,
          storeName: 'Loja Não Encontrada ($demandId)',
          network: '',
          address: 'Endereço não disponível',
          role: 'Promotor',
          distance: '0.0 KM',
          timeRange: '',
          value: 0.0,
          date: '',
          urgency: '',
          status: '',
        ));

        allAllocations.add(ActiveAllocation(
          applicationId: doc.id,
          promoter: promoter,
          demand: demand,
          status: status,
        ));
      }

      setState(() {
        _promoters = promoters;
        _demands = demands;
        _allAllocations = allAllocations;
        _loading = false;

        if (_isTrainingModeLetter) {
          _allocations = _allAllocations.where((alloc) => alloc.status == 'treinamento').toList();
        } else {
          _allocations = _allAllocations.where((alloc) => alloc.status == 'tarefa_aprovada' || alloc.status == 'aprovado' || alloc.status == 'selecionado').toList();
        }

        if (_allocations.isNotEmpty) {
          _selectedAllocation = _allocations.first;
          _onAllocationSelected(_allocations.first);
        } else {
          _selectedAllocation = null;
        }
      });
    } catch (e) {
      print('Erro ao carregar dados de cartas: $e');
      setState(() => _loading = false);
    }
  }

  void _updateFilteredAllocations() {
    setState(() {
      if (_isTrainingModeLetter) {
        _allocations = _allAllocations.where((alloc) => alloc.status == 'treinamento').toList();
      } else {
        _allocations = _allAllocations.where((alloc) => alloc.status == 'tarefa_aprovada' || alloc.status == 'aprovado' || alloc.status == 'selecionado').toList();
      }

      if (_allocations.isNotEmpty) {
        _selectedAllocation = _allocations.first;
        _onAllocationSelected(_allocations.first);
      } else {
        _selectedAllocation = null;
        _promoterNameController.clear();
        _promoterCpfController.clear();
        _promoterRgController.clear();
      }
    });
  }

  void _onAllocationSelected(ActiveAllocation alloc) {
    setState(() {
      _selectedAllocation = alloc;
      _recipientController.text = alloc.demand.storeName;
      _promoterNameController.text = alloc.promoter.name;
      
      // Formatting CPF
      String rawCpf = alloc.promoter.id;
      if (rawCpf.length == 11) {
        _promoterCpfController.text = '${rawCpf.substring(0, 3)}.${rawCpf.substring(3, 6)}.${rawCpf.substring(6, 9)}-${rawCpf.substring(9)}';
      } else {
        _promoterCpfController.text = rawCpf;
      }

      final cv = _getCurriculumData(alloc.promoter);
      final String rg = cv['dados_pessoais']?['rg'] ?? '';
      _promoterRgController.text = rg.isNotEmpty ? rg : 'Não informado';

      // Setting role
      String roleUpper = alloc.demand.role.toUpperCase();
      _roleController.text = roleUpper.contains('AUTÔNOMO') ? roleUpper : '$roleUpper AUTÔNOMO';
      _roleShortController.text = roleUpper.replaceAll(' AUTÔNOMO', '').trim();

      // Setting city from promoter address or fallback
      final String city = alloc.promoter.addressCity ?? cv['dados_pessoais']?['cidade'] ?? 'Barueri';
      _cityDateController.text = city;
    });
  }

  void _onManualPromoterSelected(AppUser? promoter) {
    if (promoter == null) return;
    setState(() {
      _selectedPromoter = promoter;
      _promoterNameController.text = promoter.name;
      
      String rawCpf = promoter.id;
      if (rawCpf.length == 11) {
        _promoterCpfController.text = '${rawCpf.substring(0, 3)}.${rawCpf.substring(3, 6)}.${rawCpf.substring(6, 9)}-${rawCpf.substring(9)}';
      } else {
        _promoterCpfController.text = rawCpf;
      }

      final cv = _getCurriculumData(promoter);
      final String rg = cv['dados_pessoais']?['rg'] ?? '';
      _promoterRgController.text = rg.isNotEmpty ? rg : 'Não informado';

      final String city = promoter.addressCity ?? cv['dados_pessoais']?['cidade'] ?? 'Barueri';
      _cityDateController.text = city;
    });
  }

  void _onManualDemandSelected(AppDemand? demand) {
    if (demand == null) return;
    setState(() {
      _selectedDemand = demand;
      _recipientController.text = demand.storeName;
      
      String roleUpper = demand.role.toUpperCase();
      _roleController.text = roleUpper.contains('AUTÔNOMO') ? roleUpper : '$roleUpper AUTÔNOMO';
      _roleShortController.text = roleUpper.replaceAll(' AUTÔNOMO', '').trim();
    });
  }

  void _printLetter() {
    final String formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.now());
    final String activityText = _isTrainingModeLetter
        ? "Treinamento Obrigatório Frente de Caixa"
        : "Operações de Frente de Caixa / Diárias de Atendimento";
    
    // Replace newlines with <br> for HTML printing
    final String stampCompanyHtml = _stampCompanyController.text.replaceAll('\n', '<br>');
    final String stampAddressHtml = _stampAddressController.text.replaceAll('\n', '<br>');
    final String signatureTitleHtml = _signatureTitleController.text.replaceAll('\n', '<br>');

    final String printHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Carta de Apresentação — ${_promoterNameController.text}</title>
  <style>
    @media print {
      body {
        margin: 0;
        padding: 1.5cm;
        font-family: Arial, sans-serif;
        color: #000000;
        background-color: #ffffff;
      }
      .no-print {
        display: none;
      }
    }
    body {
      padding: 2cm;
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      line-height: 1.5;
      color: #000000;
    }
    .header-container {
      display: flex;
      justify-content: flex-end;
      margin-bottom: 0.5cm;
    }
    .logo-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 95px;
      height: 95px;
      border: 3.5px solid #E37A24;
      border-radius: 50%;
      font-family: 'Arial Black', Impact, sans-serif;
    }
    .logo-cart {
      color: #E37A24;
      font-size: 20px;
      margin-bottom: 2px;
      line-height: 1;
    }
    .logo-text-1 {
      color: #E37A24;
      font-size: 9px;
      font-weight: 900;
      text-align: center;
      margin: 1px 0;
      letter-spacing: 0.3px;
    }
    .logo-text-2 {
      color: #1A3C70;
      font-size: 6.5px;
      font-weight: 900;
      text-align: center;
      letter-spacing: 0.2px;
    }
    .recipient {
      margin-top: 1cm;
      margin-bottom: 0.8cm;
      font-size: 14px;
    }
    .recipient p {
      margin: 0;
    }
    .recipient .salutation {
      margin-top: 15px;
    }
    .body-content {
      font-size: 14px;
      text-align: justify;
    }
    .body-content p {
      margin-top: 0;
      margin-bottom: 1.2em;
    }
    .body-content p.indent {
      text-indent: 2.5em;
    }
    .bottom-section {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-top: 1.2cm;
    }
    .date-location {
      font-size: 14px;
      margin-top: 15px;
    }
    .stamp-box {
      border: 2px solid #5d2596;
      padding: 8px 12px;
      width: 250px;
      text-align: center;
      font-family: Arial, sans-serif;
      font-size: 8.5px;
      color: #5d2596;
      border-radius: 3px;
      line-height: 1.3;
    }
    .stamp-box strong {
      font-size: 11px;
      display: block;
      margin-bottom: 4px;
      letter-spacing: 0.5px;
    }
    .signature-area {
      margin-top: 1.8cm;
      text-align: center;
    }
    .signature-svg {
      height: 60px;
      display: block;
      margin: 0 auto -5px auto;
    }
    .signature-line {
      width: 350px;
      border-top: 1.2px solid #000000;
      margin: 0 auto 5px auto;
    }
    .signature-title {
      font-size: 12px;
      text-transform: uppercase;
      font-weight: bold;
      color: #333333;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div class="header-container">
    <div class="logo-container">
      <div class="logo-cart">🛒</div>
      <div class="logo-text-1">MEGA PROMO</div>
      <div class="logo-text-2">MERCHANDISING</div>
    </div>
  </div>
  <div class="recipient">
    <p>Ao</p>
    <p><strong>${_recipientController.text}</strong></p>
    <p class="salutation">Prezados Senhores,</p>
  </div>
  <div class="body-content">
    <p class="indent"><strong>${_companyNameController.text}</strong>, vem por meio desta, comunicar que nosso prestador de serviço Sr. (a) <strong>${_promoterNameController.text}</strong>, registrado com contrato de prestação de serviço e portador (a) do CPF <strong>${_promoterCpfController.text}</strong> devidamente habilitado para o cargo de <strong>${_roleController.text}</strong>, será alocado(a) para realizar as atribuições de <strong>$activityText</strong>, dentro do estabelecimento acima mencionado.</p>
    
    <p class="indent">Informamos que o referido prestador de serviço autônomo participou do treinamento referente ao uso do(s) EPI(s) e às Normas de Segurança do Trabalho, e está ciente do uso obrigatório dos Equipamentos de Proteção Individual, conforme Lei n.º 514, de 22/12/77, artigo 157.</p>
    
    <p class="indent">Declaramos que o referido autônomo acima citado exercerá exclusivamente as atividades inerentes ao cargo de <strong>${_roleController.text}</strong> da(o) <strong>${_companyNameController.text}</strong>, não possuindo qualquer vínculo empregatício com a empresa de V.S.a., sendo de inteira responsabilidade da(o) <strong>${_companyNameController.text}</strong> todos os encargos trabalhistas, previdenciários, securitários ou qualquer que venha a existir.</p>
    
    <p class="indent">A(o) <strong>${_companyNameController.text}</strong>, garante ainda que, caso v.empresa venha a sofrer qualquer fiscalização do Ministério do Trabalho, encaminhará todos os documentos necessários do <strong>${_roleShortController.text}</strong> em referência, tais como contrato de prestação de serviço, etc. para comprovar a regularização e conformidade com a legislação trabalhista.</p>
    
    <p>Sendo o que nos apresenta, subscrevemo-nos</p>
    <p>Atenciosamente,</p>
  </div>
  
  <div class="bottom-section">
    <div class="date-location">
      ${_cityDateController.text}, $formattedDate
    </div>
    <div class="stamp-box">
      <strong>${_stampCnpjController.text}</strong>
      $stampCompanyHtml<br><br>
      Endereço: $stampAddressHtml
    </div>
  </div>
  
  <div class="signature-area">
    <svg class="signature-svg" width="200" height="50" viewBox="0 0 200 50">
      <path d="M 25 35 Q 45 5 70 25 T 115 15 T 155 35 T 185 20 M 35 15 L 175 40" fill="none" stroke="#2A48AD" stroke-width="1.8" stroke-linecap="round" />
    </svg>
    <div class="signature-line"></div>
    <div class="signature-title">$signatureTitleHtml</div>
  </div>
  
  <script>
    window.onload = function() {
      window.print();
    }
  </script>
</body>
</html>
''';

    final blob = html.Blob([printHtml], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.now());
    final String activityText = _isTrainingModeLetter
        ? "Treinamento Obrigatório Frente de Caixa"
        : "Operações de Frente de Caixa / Diárias de Atendimento";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumHeader(
                    title: 'Cartas de Entrada',
                    subtitle: 'Gere cartas de autorização para prestadores em lojas físicas baseadas no modelo homologado.',
                    actions: [
                      ElevatedButton.icon(
                        onPressed: _printLetter,
                        icon: const Icon(Icons.print, color: Colors.white, size: 18),
                        label: const Text('IMPRIMIR CARTA (A4)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildTabButton('CARTA DE TREINAMENTO', _isTrainingModeLetter, () {
                        setState(() {
                          _isTrainingModeLetter = true;
                          _updateFilteredAllocations();
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('CARTA DE DIÁRIA (NORMAL)', !_isTrainingModeLetter, () {
                        setState(() {
                          _isTrainingModeLetter = false;
                          _updateFilteredAllocations();
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Customizations (flex 4)
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.cardBorder),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DADOS DO VÍNCULO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Center(child: Text('Vínculo Ativo (Auto)')),
                                          selected: _isAutoMode,
                                          selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                                          labelStyle: TextStyle(
                                            color: _isAutoMode ? AppColors.primaryBlue : AppColors.textSecondary,
                                            fontWeight: _isAutoMode ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          onSelected: (val) {
                                            setState(() {
                                              _isAutoMode = true;
                                              if (_allocations.isNotEmpty) {
                                                _onAllocationSelected(_allocations.first);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Center(child: Text('Personalizado (Manual)')),
                                          selected: !_isAutoMode,
                                          selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                                          labelStyle: TextStyle(
                                            color: !_isAutoMode ? AppColors.primaryBlue : AppColors.textSecondary,
                                            fontWeight: !_isAutoMode ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          onSelected: (val) {
                                            setState(() {
                                              _isAutoMode = false;
                                              _selectedPromoter = null;
                                              _selectedDemand = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  if (_isAutoMode) ...[
                                    const Text('Selecione o Vínculo Operacional *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<ActiveAllocation>(
                                          value: _selectedAllocation,
                                          isExpanded: true,
                                          hint: const Text('Selecione uma alocação ativa...'),
                                          dropdownColor: Colors.white,
                                          items: _allocations.map((alloc) {
                                            return DropdownMenuItem(
                                              value: alloc,
                                              child: Text(
                                                '${alloc.promoter.name} ➔ ${alloc.demand.storeName} (${alloc.demand.clientName ?? ''})',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (alloc) {
                                            if (alloc != null) {
                                              _onAllocationSelected(alloc);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const Text('Selecione o Prestador (Promotor) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<AppUser>(
                                          value: _selectedPromoter,
                                          isExpanded: true,
                                          hint: const Text('Selecione um prestador cadastrado...'),
                                          dropdownColor: Colors.white,
                                          items: _promoters.map((p) {
                                            return DropdownMenuItem(
                                              value: p,
                                              child: Text(p.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                            );
                                          }).toList(),
                                          onChanged: _onManualPromoterSelected,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Selecione a Loja / Demanda *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<AppDemand>(
                                          value: _selectedDemand,
                                          isExpanded: true,
                                          hint: const Text('Selecione uma loja / demanda...'),
                                          dropdownColor: Colors.white,
                                          items: _demands.map((d) {
                                            return DropdownMenuItem(
                                              value: d,
                                              child: Text(
                                                '${d.storeName} (${d.clientName ?? ''}) - ${d.role}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: _onManualDemandSelected,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  const Divider(color: AppColors.cardBorder),
                                  const SizedBox(height: 24),

                                  const Text('DADOS DO DOCUMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                                  const SizedBox(height: 16),

                                  _buildFieldInput('Razão Social (Remetente)', _companyNameController, 'Razão social da agência'),
                                  const SizedBox(height: 16),
                                  _buildFieldInput('Destinatário da Carta (Loja)', _recipientController, 'Ex: Atacadão S/A'),
                                  const SizedBox(height: 16),

                                  _buildFieldInput('Nome Completo do Prestador', _promoterNameController, 'Ex: João Silva'),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildFieldInput('CPF', _promoterCpfController, '000.000.000-00')),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildFieldInput('RG', _promoterRgController, '00.000.000-0')),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(child: _buildFieldInput('Cargo no Contrato', _roleController, 'Ex: OPERADOR DE CAIXA AUTÔNOMO')),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildFieldInput('Cargo Abreviado (Fiscalização)', _roleShortController, 'Ex: OPERADOR DE CAIXA')),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _buildFieldInput('Cidade da Carta', _cityDateController, 'Ex: Barueri'),
                                  const SizedBox(height: 24),
                                  
                                  const Text('CARIMBO DA EMPRESA (CNPJ & ENDEREÇO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                                  const SizedBox(height: 16),
                                  
                                  _buildFieldInput('CNPJ do Carimbo', _stampCnpjController, '00.000.000/0000-00'),
                                  const SizedBox(height: 16),
                                  _buildFieldInput('Razão Social do Carimbo', _stampCompanyController, 'Razão Social no Carimbo', maxLines: 2),
                                  const SizedBox(height: 16),
                                  _buildFieldInput('Endereço do Carimbo', _stampAddressController, 'Endereço completo no carimbo', maxLines: 3),
                                  const SizedBox(height: 24),

                                  const Text('ASSINATURA RESPONSÁVEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                                  const SizedBox(height: 16),
                                  _buildFieldInput('Texto da Assinatura', _signatureTitleController, 'Nome/Cargo responsável', maxLines: 2),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Right Column: Live A4 Preview (flex 5)
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Container(
                                  width: 650,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Megapromo Circular Logo Header
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFE37A24), width: 3),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.shopping_cart_outlined, color: Color(0xFFE37A24), size: 22),
                                              SizedBox(height: 1),
                                              Text(
                                                'MEGA PROMO', 
                                                style: TextStyle(color: Color(0xFFE37A24), fontSize: 8, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
                                              ),
                                              Text(
                                                'MERCHANDISING', 
                                                style: TextStyle(color: Color(0xFF1A3C70), fontSize: 6, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Recipient
                                      const Text('Ao', style: TextStyle(fontSize: 13, color: Colors.black)),
                                      Text(
                                        _recipientController.text.isNotEmpty ? _recipientController.text : '[Nome da Loja]',
                                        style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Prezados Senhores,', style: TextStyle(fontSize: 13, color: Colors.black)),
                                      const SizedBox(height: 16),

                                      // Body Text
                                      RichText(
                                        textAlign: TextAlign.justify,
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 13, color: Colors.black, height: 1.5, fontFamily: 'Inter'),
                                          children: [
                                            const TextSpan(text: '      '), // Indent
                                            TextSpan(
                                              text: _companyNameController.text.isNotEmpty ? _companyNameController.text : '[Razão Social Agência]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', vem por meio desta, comunicar que nosso prestador de serviço Sr. (a) '),
                                            TextSpan(
                                              text: _promoterNameController.text.isNotEmpty ? _promoterNameController.text : '[Nome do Prestador]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', registrado com contrato de prestação de serviço e portador (a) do CPF '),
                                            TextSpan(
                                              text: _promoterCpfController.text.isNotEmpty ? _promoterCpfController.text : '[CPF]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ' devidamente habilitado para o cargo de '),
                                            TextSpan(
                                              text: _roleController.text.isNotEmpty ? _roleController.text : '[Cargo/Função]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', será alocado(a) para realizar as atribuições de '),
                                            TextSpan(
                                              text: activityText,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', dentro do estabelecimento acima mencionado.'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '      Informamos que o referido prestador de serviço autônomo participou do treinamento referente ao uso do(s) EPI(s) e às Normas de Segurança do Trabalho, e está ciente do uso obrigatório dos Equipamentos de Proteção Individual, conforme Lei n.º 514, de 22/12/77, artigo 157.',
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(fontSize: 13, color: Colors.black, height: 1.5),
                                      ),
                                      const SizedBox(height: 16),
                                      RichText(
                                        textAlign: TextAlign.justify,
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 13, color: Colors.black, height: 1.5, fontFamily: 'Inter'),
                                          children: [
                                            const TextSpan(text: '      Declaramos que o referido autônomo acima citado exercerá exclusivamente as atividades inerentes ao cargo de '),
                                            TextSpan(
                                              text: _roleController.text.isNotEmpty ? _roleController.text : '[Cargo/Função]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ' da(o) '),
                                            TextSpan(
                                              text: _companyNameController.text.isNotEmpty ? _companyNameController.text : '[Razão Social Agência]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', não possuindo qualquer vínculo empregatício com a empresa de V.S.a., sendo de inteira responsabilidade da(o) '),
                                            TextSpan(
                                              text: _companyNameController.text.isNotEmpty ? _companyNameController.text : '[Razão Social Agência]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ' todos os encargos trabalhistas, previdenciários, securitários ou qualquer que venha a existir.'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      RichText(
                                        textAlign: TextAlign.justify,
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 13, color: Colors.black, height: 1.5, fontFamily: 'Inter'),
                                          children: [
                                            const TextSpan(text: '      A(o) '),
                                            TextSpan(
                                              text: _companyNameController.text.isNotEmpty ? _companyNameController.text : '[Razão Social Agência]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ', garante ainda que, caso v.empresa venha a sofrer qualquer fiscalização do Ministério do Trabalho, encaminhará todos os documentos necessários do '),
                                            TextSpan(
                                              text: _roleShortController.text.isNotEmpty ? _roleShortController.text : '[Cargo Abreviado]',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ' em referência, tais como contrato de prestação de serviço, etc. para comprovar a regularização e conformidade com a legislação trabalhista.'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Sendo o que nos apresenta, subscrevemo-nos',
                                        style: TextStyle(fontSize: 13, color: Colors.black),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Atenciosamente,',
                                        style: TextStyle(fontSize: 13, color: Colors.black),
                                      ),
                                      const SizedBox(height: 24),

                                      // Stamp and Date Location
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: Text(
                                              '${_cityDateController.text}, $formattedDate',
                                              style: const TextStyle(fontSize: 13, color: Colors.black),
                                            ),
                                          ),
                                          // Stamp Simulation Box
                                          Container(
                                            width: 250,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFF5D2596), width: 1.5),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  _stampCnpjController.text,
                                                  style: const TextStyle(color: Color(0xFF5D2596), fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Inter'),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _stampCompanyController.text,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Color(0xFF5D2596), fontWeight: FontWeight.bold, fontSize: 8, height: 1.2, fontFamily: 'Inter'),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Endereço: ${_stampAddressController.text}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Color(0xFF5D2596), fontSize: 7, height: 1.2, fontFamily: 'Inter'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 48),

                                      // Signature line
                                      Center(
                                        child: Column(
                                          children: [
                                            // Simulated Signature
                                            SizedBox(
                                              width: 150,
                                              height: 40,
                                              child: CustomPaint(
                                                painter: SignaturePainter(),
                                              ),
                                            ),
                                            Container(
                                              width: 320,
                                              height: 1,
                                              color: Colors.black87,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _signatureTitleController.text,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFieldInput(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primaryBlue : AppColors.cardBorder),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A48AD)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.1, size.width * 0.35, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.8, size.width * 0.55, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.1, size.width * 0.75, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.9, size.width * 0.9, size.height * 0.4)
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.85, size.height * 0.8);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
