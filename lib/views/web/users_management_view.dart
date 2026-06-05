import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/security_service.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  bool _showingForm = false;
  int _currentFormTab = 0;
  int _currentListTab = 0; // 0 = Prestadores, 1 = Ambiente Rede

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '123456');
  String _selectedStoreId = '';
  final _regionalCtrl2 = TextEditingController();
  final _searchCtrl = TextEditingController();

  // Novos controllers - dados do perfil, pessoais, endereço, profissionais e veículo
  final _telefoneCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();
  final _nascimentoCtrl = TextEditingController();
  final _sexoCtrl = TextEditingController();
  final _bancoCtrl = TextEditingController();
  final _agenciaCtrl = TextEditingController();
  final _contaCtrl = TextEditingController();
  final _pixCtrl = TextEditingController();
  final _tipoContaCtrl = TextEditingController();
  final _contatoEmergenciaNomeCtrl = TextEditingController();
  final _contatoEmergenciaFoneCtrl = TextEditingController();
  final _contatoEmergenciaParentescoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _cargoAtualCtrl = TextEditingController();
  final _ultimoCargoCtrl = TextEditingController();
  final _tempoExperienciaCtrl = TextEditingController();
  final _pretensaoSalarialCtrl = TextEditingController();
  final _cnhCategoriaCtrl = TextEditingController();
  final _cnhValidadeCtrl = TextEditingController();
  final _veiculoProprioCtrl = TextEditingController();
  final _carroCtrl = TextEditingController();
  final _motoCtrl = TextEditingController();
  final _horariosCtrl = TextEditingController();
  final _raioDeslocamentoCtrl = TextEditingController();

  final _api = RegisterService();
  bool _loading = true;
  List<AppUser> _users = [];
  List<AppStore> _stores = [];
  AppUser? _editingUser;
  bool _trainingCompleted = false;
  bool _atacadaoExperience = false;
  bool _isBlocked = false;
  final _blockJustificationCtrl = TextEditingController();
  final _occurrenceDescCtrl = TextEditingController();
  final _occurrenceStoreCtrl = TextEditingController();
  String _occurrenceSeverity = 'Leve';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _cargoCtrl.dispose();
    _passwordCtrl.dispose();
    _regionalCtrl2.dispose();
    _searchCtrl.dispose();
    _telefoneCtrl.dispose();
    _loginCtrl.dispose();
    _cpfCtrl.dispose();
    _rgCtrl.dispose();
    _nascimentoCtrl.dispose();
    _sexoCtrl.dispose();
    _bancoCtrl.dispose();
    _agenciaCtrl.dispose();
    _contaCtrl.dispose();
    _pixCtrl.dispose();
    _tipoContaCtrl.dispose();
    _contatoEmergenciaNomeCtrl.dispose();
    _contatoEmergenciaFoneCtrl.dispose();
    _contatoEmergenciaParentescoCtrl.dispose();
    _cepCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _cargoAtualCtrl.dispose();
    _ultimoCargoCtrl.dispose();
    _tempoExperienciaCtrl.dispose();
    _pretensaoSalarialCtrl.dispose();
    _cnhCategoriaCtrl.dispose();
    _cnhValidadeCtrl.dispose();
    _veiculoProprioCtrl.dispose();
    _carroCtrl.dispose();
    _motoCtrl.dispose();
    _horariosCtrl.dispose();
    _raioDeslocamentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _api.getUsers();
      final stores = await _api.getStores();
      setState(() {
        _users = users;
        _stores = stores;
        _loading = false;
      });
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showingForm ? _buildForm() : _buildList();
  }

  // --- TELA DE LISTA (Imagem 1) ---
  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final query = _searchCtrl.text.toLowerCase().trim();
    final filteredUsers = _users.where((user) {
      final isWorker = user.type == 'prestador' || user.role.toLowerCase() == 'worker';
      final matchesTab = _currentListTab == 0 ? isWorker : !isWorker;
      if (!matchesTab) return false;
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query) ||
             user.role.toLowerCase().contains(query) ||
             user.phone.toLowerCase().contains(query);
    }).toList();

    filteredUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('USUÁRIOS DO SISTEMA', style: TextStyle(color: AppColors.primaryBlue, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Gerencie os usuários do PDV e seus atributos', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        
        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              _buildListTab(0, 'PRESTADORES'),
              _buildListTab(1, 'AMBIENTE REDE'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Barra de Ações
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _editingUser = null;
                _nomeCtrl.clear();
                _emailCtrl.clear();
                _cargoCtrl.clear();
                _passwordCtrl.text = '123456';
                _trainingCompleted = false;
                _atacadaoExperience = false;
                _isBlocked = false;
                _blockJustificationCtrl.clear();
                _telefoneCtrl.clear();
                _loginCtrl.clear();
                _cpfCtrl.clear();
                _rgCtrl.clear();
                _nascimentoCtrl.clear();
                _sexoCtrl.clear();
                _bancoCtrl.clear();
                _agenciaCtrl.clear();
                _contaCtrl.clear();
                _pixCtrl.clear();
                _tipoContaCtrl.clear();
                _contatoEmergenciaNomeCtrl.clear();
                _contatoEmergenciaFoneCtrl.clear();
                _contatoEmergenciaParentescoCtrl.clear();
                _cepCtrl.clear();
                _ruaCtrl.clear();
                _numeroCtrl.clear();
                _bairroCtrl.clear();
                _cidadeCtrl.clear();
                _estadoCtrl.clear();
                _latitudeCtrl.clear();
                _longitudeCtrl.clear();
                _cargoAtualCtrl.clear();
                _ultimoCargoCtrl.clear();
                _tempoExperienciaCtrl.clear();
                _pretensaoSalarialCtrl.clear();
                _cnhCategoriaCtrl.clear();
                _cnhValidadeCtrl.clear();
                _veiculoProprioCtrl.clear();
                _carroCtrl.clear();
                _motoCtrl.clear();
                _horariosCtrl.clear();
                _raioDeslocamentoCtrl.clear();
                _currentFormTab = 0;
                _showingForm = true;
              }),
              icon: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 18),
              label: const Text('Adicionar usuário', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Habilitar dispositivos'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(IconsaxPlusLinear.document_download, size: 18, color: AppColors.primaryBlue),
              label: const Text('Exportar', style: TextStyle(color: AppColors.primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(IconsaxPlusLinear.document_upload, size: 18, color: AppColors.primaryBlue),
              label: const Text('Importar', style: TextStyle(color: AppColors.primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filtros
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  prefixIcon: const Icon(IconsaxPlusLinear.search_normal, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButton<String>(
                value: 'Status',
                underline: const SizedBox(),
                onChanged: (val) {},
                items: const [
                  DropdownMenuItem(value: 'Status', child: Text('Status')),
                  DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                  DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tabela
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user.email} | ${user.role}${user.phone.isNotEmpty ? ' | 📱 ${user.phone}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: user.status == 'Ativo',
                        activeColor: AppColors.success,
                        onChanged: (val) async {
                          setState(() {
                            user.status = val ? 'Ativo' : 'Inativo';
                          });
                          await _api.saveUser(user);
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.status == 'Ativo' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(user.status, style: TextStyle(color: user.status == 'Ativo' ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      if (user.type == 'prestador') ...[
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.document_text_1, color: Colors.purple, size: 20),
                          tooltip: 'Histórico do Promotor',
                          onPressed: () {
                            _showPromoterHistoryDialog(user);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: const Icon(IconsaxPlusLinear.edit_2, color: AppColors.primaryBlue, size: 20),
                        tooltip: 'Editar',
                        onPressed: () {
                          setState(() {
                            _editingUser = user;
                            _nomeCtrl.text = user.name;
                            _emailCtrl.text = user.email;
                            _cargoCtrl.text = user.role;
                            _passwordCtrl.text = user.password;
                            _trainingCompleted = user.trainingCompleted;
                            _atacadaoExperience = user.atacadaoExperience;
                            _isBlocked = user.isBlocked;
                            _blockJustificationCtrl.clear();
                            
                            // Carregar campos root adicionais
                            _telefoneCtrl.text = user.phone;
                            _cepCtrl.text = user.addressCep ?? '';
                            _ruaCtrl.text = user.addressRua ?? '';
                            _bairroCtrl.text = user.addressBairro ?? '';
                            _cidadeCtrl.text = user.addressCity ?? '';
                            _estadoCtrl.text = user.addressUf ?? '';
                            _pixCtrl.text = user.pixKey;

                            // Decodificar curriculumCompletoDados se houver
                            final Map<String, dynamic> cv = user.curriculumCompletoDados != null && user.curriculumCompletoDados!.isNotEmpty
                                ? jsonDecode(user.curriculumCompletoDados!)
                                : {};
                            
                            final personal = cv['dados_pessoais'] ?? {};
                            final docs = cv['documentacao'] ?? {};
                            final prof = cv['dados_profissionais'] ?? {};
                            final disp = cv['disponibilidade'] ?? {};
                            
                            _loginCtrl.text = personal['login'] ?? '';
                            _cpfCtrl.text = user.id; // CPF é o ID do prestador
                            if (_cpfCtrl.text.isEmpty || _cpfCtrl.text.length < 11) {
                              _cpfCtrl.text = personal['cpf'] ?? '';
                            }
                            _rgCtrl.text = personal['rg'] ?? '';
                            _nascimentoCtrl.text = personal['nascimento'] ?? personal['data_nascimento'] ?? '';
                            _sexoCtrl.text = personal['sexo'] ?? '';
                            
                            _bancoCtrl.text = personal['banco'] ?? '';
                            _agenciaCtrl.text = personal['agencia'] ?? '';
                            _contaCtrl.text = personal['conta'] ?? '';
                            if (_pixCtrl.text.isEmpty) {
                              _pixCtrl.text = docs['chave_pix'] ?? '';
                            }
                            _tipoContaCtrl.text = personal['tipo_conta'] ?? '';
                            
                            _contatoEmergenciaNomeCtrl.text = personal['contato_emergencia_nome'] ?? '';
                            _contatoEmergenciaFoneCtrl.text = personal['contato_emergencia_fone'] ?? '';
                            _contatoEmergenciaParentescoCtrl.text = personal['contato_emergencia_parentesco'] ?? '';
                            
                            _numeroCtrl.text = personal['numero'] ?? '';
                            _latitudeCtrl.text = personal['latitude']?.toString() ?? '';
                            _longitudeCtrl.text = personal['longitude']?.toString() ?? '';
                            
                            _cargoAtualCtrl.text = prof['cargo_atual'] ?? '';
                            _ultimoCargoCtrl.text = prof['ultimo_cargo'] ?? '';
                            _tempoExperienciaCtrl.text = prof['tempo_experiencia'] ?? '';
                            _pretensaoSalarialCtrl.text = prof['pretensao_salarial'] ?? '';
                            
                            _cnhCategoriaCtrl.text = docs['cnh_categoria'] ?? '';
                            _cnhValidadeCtrl.text = docs['cnh_validade'] ?? '';
                            _veiculoProprioCtrl.text = docs['veiculo_proprio'] == true ? 'Sim' : (docs['veiculo_proprio'] == false ? 'Não' : '');
                            _carroCtrl.text = docs['carro'] == true ? 'Sim' : (docs['carro'] == false ? 'Não' : '');
                            _motoCtrl.text = docs['moto'] == true ? 'Sim' : (docs['moto'] == false ? 'Não' : '');
                            
                            _horariosCtrl.text = disp['horarios'] ?? '';
                            _raioDeslocamentoCtrl.text = disp['raio']?.toString() ?? '';
                            
                            _currentFormTab = 0;
                            _showingForm = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 20),
                        tooltip: 'Excluir',
                        onPressed: () async {
                          await _api.deleteUser(user.id);
                          setState(() {
                            _users.remove(user);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTab(int index, String label) {
    final isSelected = _currentListTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentListTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // --- TELA DE FORMULÁRIO (Imagem 2, 3, 4, 5) ---
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CADASTRAR USUÁRIO', style: TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Tabs do Formulário
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFormTab(0, 'Dados do Perfil'),
                _buildFormTab(1, 'Dados pessoais'),
                _buildFormTab(2, 'Endereço'),
                _buildFormTab(3, 'Profissional & Veículo'),
                _buildFormTab(4, 'Documentos'),
                if (_editingUser != null && _currentListTab == 0)
                  _buildFormTab(5, 'Ocorrências'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Conteúdo da Aba
        Expanded(
          child: SingleChildScrollView(
            child: _buildTabContent(),
          ),
        ),

        const SizedBox(height: 24),
        // Botões de Ação
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _showingForm = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Voltar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nomeCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha o nome do usuário')));
                  return;
                }
                
                if (_telefoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ O campo Celular / WhatsApp é obrigatório!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final internalRoles = ['Admin', 'Suporte', 'Financeiro', 'RH', 'Trade'];
                final isRede = _cargoCtrl.text == 'Líder de Frente de Caixa' || _cargoCtrl.text == 'Regional';
                final userType = isRede ? 'rede' : (internalRoles.contains(_cargoCtrl.text) ? 'interno' : 'prestador');
                AppUser userToSave;

                final String pass = (_editingUser == null || _passwordCtrl.text != _editingUser!.password)
                    ? SecurityService.hashPassword(_passwordCtrl.text)
                    : _passwordCtrl.text;

                if (_editingUser != null) {
                  userToSave = _editingUser!;
                  userToSave.name = _nomeCtrl.text;
                  userToSave.email = _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Sem e-mail';
                  userToSave.role = _cargoCtrl.text.isNotEmpty ? _cargoCtrl.text : 'Não definido';
                  userToSave.password = pass;
                  userToSave.type = userType;
                  userToSave.storeId = _cargoCtrl.text == 'Líder de Frente de Caixa' ? _selectedStoreId : '';
                  userToSave.regional = _cargoCtrl.text == 'Regional' ? _regionalCtrl2.text : '';
                  userToSave.trainingCompleted = _trainingCompleted;
                  userToSave.atacadaoExperience = _atacadaoExperience;
                  userToSave.isBlocked = _isBlocked;
                } else {
                  final String cleanCpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
                  final String generatedId = (userType == 'prestador' && cleanCpf.isNotEmpty)
                      ? cleanCpf
                      : DateTime.now().millisecondsSinceEpoch.toString();

                  userToSave = AppUser(
                    id: generatedId,
                    name: _nomeCtrl.text,
                    email: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Sem e-mail',
                    role: _cargoCtrl.text.isNotEmpty ? _cargoCtrl.text : 'Não definido',
                    password: pass,
                    status: 'Ativo',
                    type: userType,
                    storeId: _cargoCtrl.text == 'Líder de Frente de Caixa' ? _selectedStoreId : '',
                    regional: _cargoCtrl.text == 'Regional' ? _regionalCtrl2.text : '',
                    trainingCompleted: _trainingCompleted,
                    atacadaoExperience: _atacadaoExperience,
                    isBlocked: _isBlocked,
                  );
                }

                // 1. Atualizar campos root do user
                userToSave.phone = _telefoneCtrl.text.trim();
                userToSave.addressCep = _cepCtrl.text.trim();
                userToSave.addressRua = _ruaCtrl.text.trim();
                userToSave.addressBairro = _bairroCtrl.text.trim();
                userToSave.addressCity = _cidadeCtrl.text.trim();
                userToSave.addressUf = _estadoCtrl.text.trim();
                userToSave.pixKey = _pixCtrl.text.trim();

                // 2. Atualizar curriculumCompletoDados
                final Map<String, dynamic> cv = userToSave.curriculumCompletoDados != null && userToSave.curriculumCompletoDados!.isNotEmpty
                    ? jsonDecode(userToSave.curriculumCompletoDados!)
                    : {};

                final dadosPessoais = Map<String, dynamic>.from(cv['dados_pessoais'] ?? {});
                dadosPessoais['rg'] = _rgCtrl.text.trim();
                dadosPessoais['nascimento'] = _nascimentoCtrl.text.trim();
                dadosPessoais['sexo'] = _sexoCtrl.text.trim();
                dadosPessoais['login'] = _loginCtrl.text.trim();
                dadosPessoais['whatsapp'] = _telefoneCtrl.text.trim();
                dadosPessoais['banco'] = _bancoCtrl.text.trim();
                dadosPessoais['agencia'] = _agenciaCtrl.text.trim();
                dadosPessoais['conta'] = _contaCtrl.text.trim();
                dadosPessoais['tipo_conta'] = _tipoContaCtrl.text.trim();
                dadosPessoais['contato_emergencia_nome'] = _contatoEmergenciaNomeCtrl.text.trim();
                dadosPessoais['contato_emergencia_fone'] = _contatoEmergenciaFoneCtrl.text.trim();
                dadosPessoais['contato_emergencia_parentesco'] = _contatoEmergenciaParentescoCtrl.text.trim();
                
                dadosPessoais['rua'] = _ruaCtrl.text.trim();
                dadosPessoais['bairro'] = _bairroCtrl.text.trim();
                dadosPessoais['cep'] = _cepCtrl.text.trim();
                dadosPessoais['numero'] = _numeroCtrl.text.trim();
                dadosPessoais['cidade'] = _cidadeCtrl.text.trim();
                dadosPessoais['estado'] = _estadoCtrl.text.trim();
                if (_latitudeCtrl.text.isNotEmpty) {
                  dadosPessoais['latitude'] = double.tryParse(_latitudeCtrl.text) ?? 0.0;
                }
                if (_longitudeCtrl.text.isNotEmpty) {
                  dadosPessoais['longitude'] = double.tryParse(_longitudeCtrl.text) ?? 0.0;
                }

                final docsMap = Map<String, dynamic>.from(cv['documentacao'] ?? {});
                docsMap['chave_pix'] = _pixCtrl.text.trim();
                docsMap['cnh_categoria'] = _cnhCategoriaCtrl.text.trim();
                docsMap['cnh_validade'] = _cnhValidadeCtrl.text.trim();
                docsMap['veiculo_proprio'] = _veiculoProprioCtrl.text == 'Sim';
                docsMap['carro'] = _carroCtrl.text == 'Sim';
                docsMap['moto'] = _motoCtrl.text == 'Sim';

                final profMap = Map<String, dynamic>.from(cv['dados_profissionais'] ?? {});
                profMap['cargo_atual'] = _cargoAtualCtrl.text.trim();
                profMap['ultimo_cargo'] = _ultimoCargoCtrl.text.trim();
                profMap['tempo_experiencia'] = _tempoExperienciaCtrl.text.trim();
                profMap['pretensao_salarial'] = _pretensaoSalarialCtrl.text.trim();

                final dispMap = Map<String, dynamic>.from(cv['disponibilidade'] ?? {});
                dispMap['horarios'] = _horariosCtrl.text.trim();
                if (_raioDeslocamentoCtrl.text.isNotEmpty) {
                  dispMap['raio'] = int.tryParse(_raioDeslocamentoCtrl.text) ?? 20;
                }

                cv['dados_pessoais'] = dadosPessoais;
                cv['documentacao'] = docsMap;
                cv['dados_profissionais'] = profMap;
                cv['disponibilidade'] = dispMap;

                userToSave.curriculumCompletoDados = jsonEncode(cv);

                if (_isBlocked && _blockJustificationCtrl.text.isNotEmpty) {
                  final nowFormatted = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
                  await FirebaseFirestore.instance.collection('occurrences').add({
                    'promoterCpf': userToSave.id,
                    'description': 'Bloqueio: ${_blockJustificationCtrl.text}',
                    'storeName': 'Geral',
                    'severity': 'Grave',
                    'date': nowFormatted,
                  });
                }
                
                await _api.saveUser(userToSave);
                
                setState(() {
                  if (_editingUser == null) {
                    _users.add(userToSave);
                  }
                  _showingForm = false;
                  _nomeCtrl.clear();
                  _emailCtrl.clear();
                  _cargoCtrl.clear();
                  _telefoneCtrl.clear();
                  _loginCtrl.clear();
                  _cpfCtrl.clear();
                  _rgCtrl.clear();
                  _nascimentoCtrl.clear();
                  _sexoCtrl.clear();
                  _bancoCtrl.clear();
                  _agenciaCtrl.clear();
                  _contaCtrl.clear();
                  _pixCtrl.clear();
                  _tipoContaCtrl.clear();
                  _contatoEmergenciaNomeCtrl.clear();
                  _contatoEmergenciaFoneCtrl.clear();
                  _contatoEmergenciaParentescoCtrl.clear();
                  _cepCtrl.clear();
                  _ruaCtrl.clear();
                  _numeroCtrl.clear();
                  _bairroCtrl.clear();
                  _cidadeCtrl.clear();
                  _estadoCtrl.clear();
                  _latitudeCtrl.clear();
                  _longitudeCtrl.clear();
                  _cargoAtualCtrl.clear();
                  _ultimoCargoCtrl.clear();
                  _tempoExperienciaCtrl.clear();
                  _pretensaoSalarialCtrl.clear();
                  _cnhCategoriaCtrl.clear();
                  _cnhValidadeCtrl.clear();
                  _veiculoProprioCtrl.clear();
                  _carroCtrl.clear();
                  _motoCtrl.clear();
                  _horariosCtrl.clear();
                  _raioDeslocamentoCtrl.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_editingUser != null ? 'Salvar' : 'Incluir', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormTab(int index, String label) {
    final isSelected = _currentFormTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentFormTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentFormTab) {
      case 0: return _buildProfileTab();
      case 1: return _buildPersonalDataTab();
      case 2: return _buildAddressTab();
      case 3: return _buildProfissionalVeiculoTab();
      case 4: return _buildDocumentsTab();
      case 5: 
        if (_editingUser != null) {
          final tempFeedbackCtrl = TextEditingController();
          final Map<String, dynamic> cv = _editingUser!.curriculumCompletoDados != null && _editingUser!.curriculumCompletoDados!.isNotEmpty
              ? jsonDecode(_editingUser!.curriculumCompletoDados!)
              : {};
          tempFeedbackCtrl.text = cv['rh_feedback'] ?? '';
          return SizedBox(
            height: 450,
            child: _buildHistoryOcorrenciasTab(
              _editingUser!,
              tempFeedbackCtrl,
              _occurrenceDescCtrl,
              _occurrenceStoreCtrl,
              _occurrenceSeverity,
              (val) => setState(() => _occurrenceSeverity = val),
              () => setState(() {}),
            ),
          );
        }
        return const SizedBox();
      default: return const SizedBox();
    }
  }

  // Aba 1: Dados do Perfil
  Widget _buildProfileTab() {
    final isLider = _cargoCtrl.text == 'Líder de Frente de Caixa';
    final isRegional = _cargoCtrl.text == 'Regional';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dados do perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildTextField('NOME DO USUÁRIO', controller: _nomeCtrl)),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField('E-MAIL DE ACESSO', controller: _emailCtrl)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildTextField('Telefone (Celular) *', controller: _telefoneCtrl)),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField('Login', controller: _loginCtrl)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildTextField('SENHA DE ACESSO', controller: _passwordCtrl)),
          const SizedBox(width: 16),
          Expanded(
            child: _currentListTab == 1
                ? _buildDropdownField(
                    'Perfil de acesso',
                    ['Admin', 'Suporte', 'Financeiro', 'RH', 'Trade', 'Líder de Frente de Caixa', 'Regional'],
                    value: _cargoCtrl.text.isEmpty ? null : _cargoCtrl.text,
                    onChanged: (val) => setState(() => _cargoCtrl.text = val ?? ''),
                  )
                : _buildTextField('Cargo de campo', controller: _cargoCtrl),
          ),
        ]),
        // Loja vinculada — apenas para Líder de Frente de Caixa
        if (isLider && _currentListTab == 1) ...[  
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(IconsaxPlusLinear.buildings_2, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text('Loja Vinculada', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              const Text('O Líder terá acesso apenas às informações desta loja.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              _buildDropdownField(
                'SELECIONE A LOJA',
                _stores.map((s) => s.id).toList(),
                value: _selectedStoreId.isNotEmpty ? _selectedStoreId : null,
                labelMapper: (id) => _stores.any((s) => s.id == id) ? _stores.firstWhere((s) => s.id == id).name : id,
                onChanged: (val) => setState(() => _selectedStoreId = val ?? ''),
              ),
            ]),
          ),
        ],
        // Regional — apenas para perfil Regional
        if (isRegional && _currentListTab == 1) ...[  
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(IconsaxPlusLinear.map, color: Color(0xFF7C3AED), size: 18),
                SizedBox(width: 8),
                Text('Regional de Atuação', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              const Text('O Regional verá todas as lojas desta regional.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              _buildTextField('NOME DA REGIONAL (ex: Sul, Grande SP)', controller: _regionalCtrl2),
            ]),
          ),
        ],
        if (_currentListTab == 0) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  'Realizou o treinamento?',
                  ['Sim', 'Não'],
                  value: _trainingCompleted ? 'Sim' : 'Não',
                  onChanged: (val) {
                    setState(() {
                      _trainingCompleted = val == 'Sim';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  'Já teve vivência com o sistema do Atacadão?',
                  ['Sim', 'Não'],
                  value: _atacadaoExperience ? 'Sim' : 'Não',
                  onChanged: (val) {
                    setState(() {
                      _atacadaoExperience = val == 'Sim';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  'Bloqueado?',
                  ['Sim', 'Não'],
                  value: _isBlocked ? 'Sim' : 'Não',
                  onChanged: (val) {
                    setState(() {
                      _isBlocked = val == 'Sim';
                    });
                  },
                ),
              ),
            ],
          ),
          if (_isBlocked) ...[
            const SizedBox(height: 16),
            _buildTextField(
              'Justificativa do Bloqueio',
              controller: _blockJustificationCtrl,
            ),
          ],
        ],
      ],
    );
  }

  // Aba 2: Dados Pessoais (Imagem 3 Simplificada)
  Widget _buildPersonalDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dados pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('CPF', controller: _cpfCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('RG', controller: _rgCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Data de Nascimento', controller: _nascimentoCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Sexo', controller: _sexoCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Banco', controller: _bancoCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Agência', controller: _agenciaCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Nº da Conta', controller: _contaCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Chave Pix', controller: _pixCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Tipo de Conta', controller: _tipoContaCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Contato de Emergência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField('Nome do Contato', controller: _contatoEmergenciaNomeCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Telefone de Emergência', controller: _contatoEmergenciaFoneCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Grau de Parentesco', controller: _contatoEmergenciaParentescoCtrl)),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  // Aba 3: Endereço (Imagem 4)
  Widget _buildAddressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Endereço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('CEP', controller: _cepCtrl)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildTextField('Logradouro', controller: _ruaCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Número', controller: _numeroCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Bairro', controller: _bairroCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Cidade', controller: _cidadeCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Estado', controller: _estadoCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Latitude', controller: _latitudeCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Longitude', controller: _longitudeCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Mapa será exibido aqui para confirmar a localização.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildProfissionalVeiculoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dados Profissionais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Cargo Atual', controller: _cargoAtualCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Último Cargo', controller: _ultimoCargoCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Tempo de Experiência', controller: _tempoExperienciaCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Pretensão Salarial', controller: _pretensaoSalarialCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Documentação & Veículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('CNH Categoria', controller: _cnhCategoriaCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Validade CNH', controller: _cnhValidadeCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                'Veículo Próprio?',
                ['Sim', 'Não'],
                value: _veiculoProprioCtrl.text.isEmpty ? null : _veiculoProprioCtrl.text,
                onChanged: (val) => setState(() => _veiculoProprioCtrl.text = val ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                'Possui Carro?',
                ['Sim', 'Não'],
                value: _carroCtrl.text.isEmpty ? null : _carroCtrl.text,
                onChanged: (val) => setState(() => _carroCtrl.text = val ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                'Possui Moto?',
                ['Sim', 'Não'],
                value: _motoCtrl.text.isEmpty ? null : _motoCtrl.text,
                onChanged: (val) => setState(() => _motoCtrl.text = val ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Disponibilidade de Trabalho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Horário Disponível', controller: _horariosCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Raio Deslocamento (KM)', controller: _raioDeslocamentoCtrl)),
          ],
        ),
      ],
    );
  }

  // Aba 4: Documentos (Imagem 5 Simplificada)
  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 20),
        _buildDocumentRow('RG'),
        const SizedBox(height: 16),
        _buildDocumentRow('CPF'),
        const SizedBox(height: 16),
        _buildDocumentRow('Comprovante de Conta Bancária'),
        const SizedBox(height: 16),
        _buildDocumentRow('Selfie / Foto do Rosto'),
      ],
    );
  }

  Widget _buildDocumentRow(String label) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                  hintText: 'Nenhum arquivo selecionado',
                ),
                readOnly: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text('Carregar', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: () {}, icon: const Icon(IconsaxPlusLinear.eye, color: AppColors.textSecondary)),
        IconButton(onPressed: () {}, icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error)),
      ],
    );
  }

  Widget _buildTextField(String label, {bool obscureText = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, {String? value, void Function(String?)? onChanged, String Function(String)? labelMapper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value != null && options.contains(value)) ? value : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
          items: options.map((String optValue) {
            return DropdownMenuItem<String>(
              value: optValue,
              child: Text(labelMapper != null ? labelMapper(optValue) : optValue),
            );
          }).toList(),
          onChanged: onChanged,
          hint: const Text('Selecione'),
        ),
      ],
    );
  }

  Future<void> _printLetterFromData(Map<String, dynamic> letter) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'DATA DE EMISSÃO DA CARTA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final String formattedDate = DateFormat("dd/MM/yyyy").format(pickedDate);
    final String title = letter['title'] ?? 'CARTA DE APRESENTAÇÃO';
    final String type = letter['type'] ?? 'diarias';
    final String promoterName = letter['promoterName'] ?? '';
    final String promoterCpfFormatted = letter['promoterCpfFormatted'] ?? letter['promoterCpf'] ?? '';
    final String storeName = letter['storeName'] ?? '';
    final int validityDays = type == 'treinamento' ? 1 : 3;
    final DateTime expirationDateTime = pickedDate.add(Duration(days: validityDays));
    final String expiresAt = DateFormat("dd/MM/yyyy").format(expirationDateTime);

    final String printHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title — $promoterName</title>
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
    .letter-title {
      text-align: center;
      font-weight: bold;
      font-size: 16px;
      margin-top: 1cm;
      margin-bottom: 1cm;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #1A3C70;
      border-bottom: 2px solid #E37A24;
      padding-bottom: 8px;
    }
    .recipient {
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
  
  <div class="letter-title">
    $title
  </div>

  <div class="recipient">
    <p>Ao</p>
    <p><strong>$storeName</strong></p>
    <p class="salutation">Prezados Senhores,</p>
  </div>
  <div class="body-content">
    <p class="indent">A empresa <strong>MEGA WORLD SERVICOS DE TERCEIRIZACAO E MARKETING LTDA</strong>, vem por meio desta, comunicar que o(a) nosso(a) prestador(a) de serviço autônomo(a) Sr.(a) <strong>$promoterName</strong>, portador(a) do CPF <strong>$promoterCpfFormatted</strong>, está devidamente autorizado(a) e alocado(a) nesta unidade para realizar as atividades de ${type == 'treinamento' ? 'Treinamento Obrigatório Frente de Caixa' : 'Operações de Frente de Caixa / Diárias de Atendimento'}.</p>
    
    <p class="indent"><strong>Informações de Segurança e Treinamento:</strong> Declaramos que o referido prestador participou do treinamento referente ao uso do(s) EPI(s) e às Normas de Segurança do Trabalho, estando ciente do uso obrigatório dos Equipamentos de Proteção Individual, conforme Lei n.º 514, de 22/12/77, artigo 157.</p>
    
    <p class="indent"><strong>Validade do Documento:</strong> Esta carta possui finalidade exclusiva de credenciamento operacional e tem validade improrrogável de <strong>$validityDays dia(s)</strong> a partir da data de emissão, vencendo impreterivelmente em <strong>$expiresAt</strong>.</p>
    
    <p class="indent">Declaramos que o referido autônomo exercerá exclusivamente suas atividades comerciais de forma independente, não possuindo qualquer vínculo empregatício com a empresa de V.S.a., sendo de inteira responsabilidade da MEGA WORLD todos os encargos trabalhistas, previdenciários ou securitários que venham a incidir.</p>
    
    <p>Sendo o que nos apresenta, subscrevemo-nos</p>
    <p>Atenciosamente,</p>
  </div>
  
  <div class="bottom-section">
    <div class="date-location">
      São Paulo, $formattedDate
    </div>
    <div class="stamp-box">
      <strong>60.970.093/0001-09</strong>
      MEGA WORLD SERVIÇOS DE TERCEIRIZAÇÃO E MARKETING LTDA<br><br>
      Endereço: AV MARCOS PENTEADO DE ULHOA RODRIGUES, 939 - TAMBORÉ, BARUERI / SP
    </div>
  </div>
  
  <div class="signature-area">
    <div class="signature-line"></div>
    <div class="signature-title">MEGA WORLD SERVIÇOS DE TERCEIRIZAÇÃO E MARKETING LTDA</div>
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

  void _showPromoterHistoryDialog(AppUser user) {
    int activeTab = 0;
    final feedbackCtrl = TextEditingController();
    final occurrenceDescCtrl = TextEditingController();
    final occurrenceStoreCtrl = TextEditingController();
    String occurrenceSeverity = 'Leve';

    final Map<String, dynamic> cv = user.curriculumCompletoDados != null && user.curriculumCompletoDados!.isNotEmpty
        ? jsonDecode(user.curriculumCompletoDados!)
        : {};
    feedbackCtrl.text = cv['rh_feedback'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
              child: Container(
                width: 900,
                height: 650,
                padding: const EdgeInsets.all(24),
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
                            const Text('HISTÓRICO DO PRESTADOR', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(user.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tabs
                    Container(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
                      child: Row(
                        children: [
                          _buildDialogTab(activeTab, 0, 'Jornadas & Vínculos', (index) => setDialogState(() => activeTab = index)),
                          _buildDialogTab(activeTab, 1, 'Treinamento & Cartas', (index) => setDialogState(() => activeTab = index)),
                          _buildDialogTab(activeTab, 2, 'Feedbacks & Ocorrências', (index) => setDialogState(() => activeTab = index)),
                          _buildDialogTab(activeTab, 3, 'Extrato Financeiro', (index) => setDialogState(() => activeTab = index)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Content
                    Expanded(
                      child: IndexedStack(
                        index: activeTab,
                        children: [
                          _buildHistoryJornadasTab(user),
                          _buildHistoryTreinamentoTab(user),
                          _buildHistoryOcorrenciasTab(user, feedbackCtrl, occurrenceDescCtrl, occurrenceStoreCtrl, occurrenceSeverity, (val) {
                            setDialogState(() => occurrenceSeverity = val);
                          }, () {
                            setDialogState(() {});
                          }),
                          _buildHistoryFinanceiroTab(user),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTab(int activeTab, int index, String label, Function(int) onTap) {
    final isSelected = activeTab == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryJornadasTab(AppUser user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('promoterCpf', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Nenhum vínculo ou diária aceita por este prestador ainda.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final storeName = data['storeName'] ?? 'Loja Desconhecida';
            final role = data['role'] ?? 'Operador';
            final date = data['date'] ?? '';
            final val = data['value'] ?? 0.0;
            final status = data['status'] ?? 'Pendente';
            
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.background, child: Icon(IconsaxPlusLinear.shop, color: AppColors.primaryBlue, size: 18)),
                title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('$role • $date', style: const TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ ${val.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status.toString().toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTreinamentoTab(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.teacher, color: AppColors.primaryBlue, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATUS DE TREINAMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        user.trainingCompleted
                            ? 'Treinamento Atacadão Homologado (Selo Dourado Ativo)'
                            : 'Treinamento Pendente / Não Realizado',
                        style: TextStyle(
                          color: user.trainingCompleted ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.trainingCompleted || user.atacadaoExperience)
                  const Icon(Icons.stars, color: Colors.amber, size: 28),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('CARTAS DE APRESENTAÇÃO EMITIDAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('letters')
                .where('promoterCpf', isEqualTo: user.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Nenhuma carta emitida para este prestador ainda.', style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final storeName = data['storeName'] ?? '';
                  final type = data['type'] ?? 'diarias';
                  final createdAt = data['createdAt'] ?? '';
                  final expiresAt = data['expiresAt'] ?? '';
                  
                  final dateFormatted = createdAt.isNotEmpty ? DateFormat("dd/MM/yyyy").format(DateTime.parse(createdAt)) : '';
                  final expFormatted = expiresAt.isNotEmpty ? DateFormat("dd/MM/yyyy").format(DateTime.parse(expiresAt)) : '';

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
                    child: ListTile(
                      leading: const Icon(IconsaxPlusLinear.document_text, color: AppColors.primaryBlue),
                      title: Text(type == 'treinamento' ? 'Carta de Treinamento - $storeName' : 'Carta de Diárias - $storeName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Emitida em: $dateFormatted • Validade até: $expFormatted', style: const TextStyle(fontSize: 11)),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _printLetterFromData(data),
                        icon: const Icon(Icons.print, size: 14, color: Colors.white),
                        label: const Text('IMPRIMIR', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, elevation: 0),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryOcorrenciasTab(
      AppUser user,
      TextEditingController feedbackCtrl,
      TextEditingController descCtrl,
      TextEditingController storeCtrl,
      String severity,
      Function(String) onSeverityChanged,
      VoidCallback refreshState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side: RH Feedback & Occurrences List
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OBSERVAÇÕES E FEEDBACK DO RH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feedbackCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: 'Digite o feedback profissional do promotor...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final Map<String, dynamic> cv = user.curriculumCompletoDados != null && user.curriculumCompletoDados!.isNotEmpty
                          ? jsonDecode(user.curriculumCompletoDados!)
                          : {};
                      cv['rh_feedback'] = feedbackCtrl.text;
                      user.curriculumCompletoDados = jsonEncode(cv);
                      await _api.saveUser(user);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback atualizado!'), backgroundColor: AppColors.success));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    child: const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('OCORRÊNCIAS REGISTRADAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('occurrences')
                      .where('promoterCpf', isEqualTo: user.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Nenhuma ocorrência registrada para este prestador.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final desc = data['description'] ?? '';
                        final store = data['storeName'] ?? '';
                        final sev = data['severity'] ?? 'Leve';
                        final dt = data['date'] ?? '';

                        Color sevColor = Colors.green;
                        if (sev == 'Média') sevColor = Colors.orange;
                        if (sev == 'Grave') sevColor = Colors.red;

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.warning_amber_rounded, color: sevColor),
                            title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text('Loja: $store • Data: $dt', style: const TextStyle(fontSize: 11)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(sev.toUpperCase(), style: TextStyle(color: sevColor, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(width: 1, color: AppColors.cardBorder),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REGISTRAR NOVA OCORRÊNCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
              const SizedBox(height: 16),
              _buildDialogLabel('Descrição do Ocorrido'),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  hintText: 'Descreva os detalhes da ocorrência...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
              const SizedBox(height: 12),
              _buildDialogLabel('Estabelecimento / Loja'),
              const SizedBox(height: 6),
              TextField(
                controller: storeCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  hintText: 'Ex: Atacadão Santo André',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
              const SizedBox(height: 12),
              _buildDialogLabel('Gravidade'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                dropdownColor: Colors.white,
                items: ['Leve', 'Média', 'Grave'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (v) {
                  if (v != null) onSeverityChanged(v);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A descrição é obrigatória.'), backgroundColor: Colors.redAccent));
                      return;
                    }
                    final nowFormatted = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
                    await FirebaseFirestore.instance.collection('occurrences').add({
                      'promoterCpf': user.id,
                      'description': descCtrl.text,
                      'storeName': storeCtrl.text.isEmpty ? 'Geral' : storeCtrl.text,
                      'severity': severity,
                      'date': nowFormatted,
                    });
                    descCtrl.clear();
                    storeCtrl.clear();
                    refreshState();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorrência registrada!'), backgroundColor: AppColors.success));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('REGISTRAR OCORRÊNCIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialogLabel(String text) {
    return Text(text.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold));
  }

  Widget _buildHistoryFinanceiroTab(AppUser user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('promoterCpf', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        
        double totalPaid = 0.0;
        double totalPending = 0.0;
        final List<Map<String, dynamic>> paidApps = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final val = (data['value'] ?? 0.0).toDouble();
          final status = data['status']?.toString() ?? '';

          if (status == 'pago') {
            totalPaid += val;
            paidApps.add(data);
          } else if (status == 'liberado_pagamento' || status == 'em_analise') {
            totalPending += val;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatHistoryCard('Total Recebido (Pago)', 'R\$ ${totalPaid.toStringAsFixed(2)}', AppColors.success),
                const SizedBox(width: 16),
                _buildStatHistoryCard('Aguardando Liberação / Pago Pendente', 'R\$ ${totalPending.toStringAsFixed(2)}', AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            const Text('DETALHES DE DIÁRIAS PAGAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Expanded(
              child: paidApps.isEmpty
                  ? const Center(child: Text('Nenhuma diária paga registrada ainda.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))
                  : ListView.builder(
                      itemCount: paidApps.length,
                      itemBuilder: (context, index) {
                        final data = paidApps[index];
                        final storeName = data['storeName'] ?? '';
                        final date = data['date'] ?? '';
                        final val = (data['value'] ?? 0.0).toDouble();

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                            title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('Jornada em $date', style: const TextStyle(fontSize: 11)),
                            trailing: Text('R\$ ${val.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatHistoryCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}
