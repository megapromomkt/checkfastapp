import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
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

  final _api = RegisterService();
  bool _loading = true;
  List<AppUser> _users = [];
  List<AppStore> _stores = [];
  AppUser? _editingUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

    final filteredUsers = _users.where((user) {
      final isWorker = user.type == 'prestador' || user.role.toLowerCase() == 'worker';
      if (_currentListTab == 0) {
        return isWorker;
      } else {
        return !isWorker;
      }
    }).toList();


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
                  subtitle: Text('${user.email} | ${user.role}'),
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
                _buildFormTab(3, 'Documentos'),
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
                if (_nomeCtrl.text.isNotEmpty) {
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
                    } else {
                      userToSave = AppUser(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nomeCtrl.text,
                        email: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Sem e-mail',
                        role: _cargoCtrl.text.isNotEmpty ? _cargoCtrl.text : 'Não definido',
                        password: pass,
                        status: 'Ativo',
                        type: userType,
                        storeId: _cargoCtrl.text == 'Líder de Frente de Caixa' ? _selectedStoreId : '',
                        regional: _cargoCtrl.text == 'Regional' ? _regionalCtrl2.text : '',
                      );
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
                    });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha o nome do usuário')));
                }
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
      case 3: return _buildDocumentsTab();
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
          Expanded(child: _buildTextField('Telefone')),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField('Login')),
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
            Expanded(child: _buildTextField('CPF')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('RG')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Data de Nascimento')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Sexo')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Banco')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Agência')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Nº da Conta')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Chave Pix')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Tipo de Conta')),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Contato de Emergência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField('Nome do Contato')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Telefone de Emergência')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Grau de Parentesco')),
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
            Expanded(child: _buildTextField('CEP')),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildTextField('Logradouro')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Número')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Bairro')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Cidade')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Estado')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Latitude')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Longitude')),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Mapa será exibido aqui para confirmar a localização.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
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

}
