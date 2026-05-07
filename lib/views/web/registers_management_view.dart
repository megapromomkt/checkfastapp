import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import 'widgets/registers_list_detail_layout.dart';

class RegistersManagementView extends StatefulWidget {
  const RegistersManagementView({super.key});

  @override
  State<RegistersManagementView> createState() => _RegistersManagementViewState();
}

class _RegistersManagementViewState extends State<RegistersManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final db = TestDatabase.instance;
  final _api = RegisterService();

  AppClient? _selectedClient;
  AppProject? _selectedProject;
  AppStore? _selectedStore;
  AppRole? _selectedRole;
  AppPaymentRule? _selectedRule;
  AppDemandModel? _selectedModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _initializeSelections();
  }

  void _initializeSelections() {
    if (db.clients.isNotEmpty) _selectedClient = db.clients.first;
    if (db.projects.isNotEmpty) _selectedProject = db.projects.first;
    if (db.stores.isNotEmpty) _selectedStore = db.stores.first;
    if (db.roles.isNotEmpty) _selectedRole = db.roles.first;
    if (db.paymentRules.isNotEmpty) _selectedRule = db.paymentRules.first;
    if (db.demandModels.isNotEmpty) _selectedModel = db.demandModels.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumHeader(
          title: 'Cadastros',
          subtitle: 'Gerencie clientes, projetos, lojas e regras para criação de demandas',
        ),
        const SizedBox(height: 30),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: Colors.white10,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Projetos'),
            Tab(text: 'Lojas'),
            Tab(text: 'Funções'),
            Tab(text: 'Regras de Pagamento'),
            Tab(text: 'Modelos de Demanda'),
            Tab(text: 'Configurações Gerais'),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClientsTab(),
              _buildProjectsTab(),
              _buildStoresTab(),
              _buildRolesTab(),
              _buildPaymentRulesTab(),
              _buildDemandModelsTab(),
              _buildGeneralSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // --- DIALOGS ---
  void _showDeleteDialog(String itemName, Function() onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir "$itemName"?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              onDelete();
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({required String title, required List<Widget> fields, required Function() onSave}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ...fields,
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      onSave();
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
                    child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          )
        ],
      ),
    );
  }

  // --- ABA 1: CLIENTES ---
  Widget _buildClientsTab() {
    return _buildStandardListWithDetails<AppClient>(
      buttonLabel: 'Novo cliente',
      items: db.clients,
      selectedItem: _selectedClient,
      titleBuilder: (c) => c.name,
      subtitleBuilder: (c) => 'CNPJ: ${c.cnpj}',
      onSelect: (val) => setState(() => _selectedClient = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        _showFormDialog(
          title: 'Novo Cliente', 
          fields: [_buildTextField('Nome', nameCtrl)], 
          onSave: () async {
            final newClient = AppClient(id: DateTime.now().toString(), name: nameCtrl.text, cnpj: '00.000.000/0001-00');
            await _api.saveClient(newClient);
            setState(() => _selectedClient = newClient);
          }
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteClient(item.id);
          setState(() {
            _selectedClient = null;
          });
        });
      },
      detailsBuilder: (item) {
        final clientProjects = db.projects.where((p) => p.clientId == item.id).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                    child: const Center(child: Icon(IconsaxPlusLinear.building, color: AppColors.neonCyan, size: 40)),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            OutlinedButton.icon(
                              onPressed: () {
                                final nameCtrl = TextEditingController(text: item.name);
                                final cnpjCtrl = TextEditingController(text: item.cnpj);
                                _showFormDialog(
                                  title: 'Editar Cliente',
                                  fields: [_buildTextField('Nome Fantasia', nameCtrl), _buildTextField('CNPJ', cnpjCtrl)],
                                  onSave: () {
                                    item.name = nameCtrl.text;
                                    item.cnpj = cnpjCtrl.text;
                                  }
                                );
                              },
                              icon: const Icon(IconsaxPlusLinear.edit, size: 16),
                              label: const Text('Editar'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildInfoItem('CNPJ', item.cnpj), const SizedBox(width: 40),
                            _buildInfoItem('Tipo', item.type), const SizedBox(width: 40),
                            _buildInfoItem('Prazo Pagamento', item.paymentTerm),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Projetos Vinculados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController();
                    _showFormDialog(
                      title: 'Novo Projeto para ${item.name}',
                      fields: [_buildTextField('Nome do Projeto', nameCtrl)],
                      onSave: () => db.projects.add(AppProject(id: DateTime.now().toString(), name: nameCtrl.text, clientId: item.id))
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.add, color: Colors.black, size: 16),
                  label: const Text('Novo projeto', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                )
              ],
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
              child: clientProjects.isEmpty 
                ? const Padding(padding: EdgeInsets.all(20), child: Text('Nenhum projeto vinculado.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clientProjects.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final proj = clientProjects[index];
                  return ListTile(
                    title: Text(proj.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Tipo: ${proj.type} | Pagamento: ${proj.paymentModel}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.trash, color: Colors.redAccent, size: 18), 
                          onPressed: () => _showDeleteDialog(proj.name, () => db.projects.remove(proj))
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  // --- ABA 2: PROJETOS ---
  Widget _buildProjectsTab() {
    return _buildStandardListWithDetails<AppProject>(
      buttonLabel: 'Novo projeto (Via Cliente)',
      items: db.projects,
      selectedItem: _selectedProject,
      titleBuilder: (p) => p.name,
      subtitleBuilder: (p) => db.clients.firstWhere((c) => c.id == p.clientId, orElse: () => AppClient(id: '', name: 'Desconhecido')).name,
      onSelect: (val) => setState(() => _selectedProject = val),
      onAdd: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Projetos devem ser criados dentro da aba Clientes.')));
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () {
          db.projects.remove(item);
          _selectedProject = db.projects.isNotEmpty ? db.projects.first : null;
        });
      },
      detailsBuilder: (item) {
        final clientName = db.clients.firstWhere((c) => c.id == item.clientId, orElse: () => AppClient(id: '', name: 'Desconhecido')).name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE PROJETO', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final typeCtrl = TextEditingController(text: item.type);
                    final payCtrl = TextEditingController(text: item.paymentModel);
                    _showFormDialog(
                      title: 'Editar Projeto', 
                      fields: [
                        _buildTextField('Nome', nameCtrl),
                        _buildTextField('Tipo (Exclusivo/Compartilhado)', typeCtrl),
                        _buildTextField('Modelo Pagamento (Diária/Hora)', payCtrl),
                      ], 
                      onSave: () {
                        item.name = nameCtrl.text;
                        item.type = typeCtrl.text;
                        item.paymentModel = payCtrl.text;
                      }
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                )
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionBlock('BLOCO 1 — IDENTIFICAÇÃO', [
              _buildFakeField('Nome do projeto', item.name),
              _buildFakeField('Cliente vinculado', clientName),
            ]),
            _buildSectionBlock('BLOCO 2 E 3 — TIPO E PAGAMENTO', [
              _buildFakeField('Tipo', item.type, icon: IconsaxPlusLinear.star),
              _buildFakeField('Modelo', item.paymentModel),
            ]),
          ],
        );
      }
    );
  }

  // --- ABA 3: LOJAS ---
  Widget _buildStoresTab() {
    return _buildStandardListWithDetails<AppStore>(
      buttonLabel: 'Nova loja',
      items: db.stores,
      selectedItem: _selectedStore,
      titleBuilder: (s) => s.name,
      subtitleBuilder: (s) => s.address,
      onSelect: (val) => setState(() => _selectedStore = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        final addrCtrl = TextEditingController();
        final latCtrl = TextEditingController();
        final lngCtrl = TextEditingController();
        final radiusCtrl = TextEditingController(text: '200');
        _showFormDialog(
          title: 'Nova Loja', 
          fields: [
            _buildTextField('Nome da Loja', nameCtrl),
            _buildTextField('Endereço Completo (Google Maps)', addrCtrl),
            Row(
              children: [
                Expanded(child: _buildTextField('Latitude', latCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField('Longitude', lngCtrl)),
              ],
            ),
            _buildTextField('Raio de Check-in Permitido (metros)', radiusCtrl),
          ], 
          onSave: () {
            final newStore = AppStore(
              id: DateTime.now().toString(), 
              name: nameCtrl.text, 
              clientId: '', 
              address: addrCtrl.text,
              latitude: double.tryParse(latCtrl.text) ?? 0.0,
              longitude: double.tryParse(lngCtrl.text) ?? 0.0,
              locationRadius: int.tryParse(radiusCtrl.text) ?? 200,
            );
            db.stores.add(newStore);
            _selectedStore = newStore;
          }
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () {
          db.stores.remove(item);
          _selectedStore = db.stores.isNotEmpty ? db.stores.first : null;
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE LOJA', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final addrCtrl = TextEditingController(text: item.address);
                    final latCtrl = TextEditingController(text: item.latitude.toString());
                    final lngCtrl = TextEditingController(text: item.longitude.toString());
                    final radiusCtrl = TextEditingController(text: item.locationRadius.toString());
                    _showFormDialog(
                      title: 'Editar Loja', 
                      fields: [
                        _buildTextField('Nome da Loja', nameCtrl),
                        _buildTextField('Endereço Completo (Google Maps)', addrCtrl),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Latitude', latCtrl)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTextField('Longitude', lngCtrl)),
                          ],
                        ),
                        _buildTextField('Raio de Check-in Permitido (metros)', radiusCtrl),
                      ], 
                      onSave: () {
                        item.name = nameCtrl.text;
                        item.address = addrCtrl.text;
                        item.latitude = double.tryParse(latCtrl.text) ?? 0.0;
                        item.longitude = double.tryParse(lngCtrl.text) ?? 0.0;
                        item.locationRadius = int.tryParse(radiusCtrl.text) ?? 200;
                      }
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                )
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionBlock('INFORMAÇÕES GERAIS', [
              _buildFakeField('Nome', item.name),
            ]),
            _buildSectionBlock('LOCALIZAÇÃO', [
              _buildFakeField('Endereço', item.address),
            ]),
          ],
        );
      }
    );
  }

  // --- ABA 4: FUNÇÕES ---
  Widget _buildRolesTab() {
    return _buildStandardListWithDetails<AppRole>(
      buttonLabel: 'Nova função',
      items: db.roles,
      selectedItem: _selectedRole,
      titleBuilder: (r) => r.name,
      subtitleBuilder: (r) => r.type,
      onSelect: (val) => setState(() => _selectedRole = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        final typeCtrl = TextEditingController(text: 'Operacional em Loja');
        final descCtrl = TextEditingController();
        _showFormDialog(
          title: 'Nova Função', 
          fields: [
            _buildTextField('Nome da Função', nameCtrl),
            _buildTextField('Tipo de Atividade', typeCtrl),
            _buildTextField('Descrição', descCtrl),
          ], 
          onSave: () {
            final newRole = AppRole(id: DateTime.now().toString(), name: nameCtrl.text, type: typeCtrl.text, description: descCtrl.text);
            db.roles.add(newRole);
            _selectedRole = newRole;
          }
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () {
          db.roles.remove(item);
          _selectedRole = db.roles.isNotEmpty ? db.roles.first : null;
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE FUNÇÃO', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final typeCtrl = TextEditingController(text: item.type);
                    final descCtrl = TextEditingController(text: item.description);
                    _showFormDialog(
                      title: 'Editar Função', 
                      fields: [
                        _buildTextField('Nome da Função', nameCtrl),
                        _buildTextField('Tipo de Atividade', typeCtrl),
                        _buildTextField('Descrição', descCtrl),
                      ], 
                      onSave: () {
                        item.name = nameCtrl.text;
                        item.type = typeCtrl.text;
                        item.description = descCtrl.text;
                      }
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                )
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionBlock('INFORMAÇÕES', [
              _buildFakeField('Nome da função', item.name),
              _buildFakeField('Tipo de atividade', item.type),
            ]),
            _buildFakeField('Descrição', item.description, isLong: true),
          ],
        );
      }
    );
  }

  // --- ABA 5: REGRAS DE PAGAMENTO ---
  Widget _buildPaymentRulesTab() {
    return _buildStandardListWithDetails<AppPaymentRule>(
      buttonLabel: 'Nova regra',
      items: db.paymentRules,
      selectedItem: _selectedRule,
      titleBuilder: (pr) => pr.name,
      subtitleBuilder: (pr) => pr.type,
      onSelect: (val) => setState(() => _selectedRule = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        final typeCtrl = TextEditingController(text: 'Diária');
        _showFormDialog(
          title: 'Nova Regra', 
          fields: [
            _buildTextField('Nome da Regra', nameCtrl),
            _buildTextField('Tipo (Ex: Diária, Hora)', typeCtrl),
          ], 
          onSave: () {
            final newRule = AppPaymentRule(id: DateTime.now().toString(), name: nameCtrl.text, type: typeCtrl.text);
            db.paymentRules.add(newRule);
            _selectedRule = newRule;
          }
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () {
          db.paymentRules.remove(item);
          _selectedRule = db.paymentRules.isNotEmpty ? db.paymentRules.first : null;
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE REGRA', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final typeCtrl = TextEditingController(text: item.type);
                    _showFormDialog(
                      title: 'Editar Regra', 
                      fields: [
                        _buildTextField('Nome da Regra', nameCtrl),
                        _buildTextField('Tipo (Ex: Diária, Hora)', typeCtrl),
                      ], 
                      onSave: () {
                        item.name = nameCtrl.text;
                        item.type = typeCtrl.text;
                      }
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                )
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionBlock('DADOS DA REGRA', [
              _buildFakeField('Nome da regra', item.name),
              _buildFakeField('Tipo', item.type),
            ]),
          ],
        );
      }
    );
  }

  // --- ABA 6: MODELOS DE DEMANDA ---
  Widget _buildDemandModelsTab() {
    return _buildStandardListWithDetails<AppDemandModel>(
      buttonLabel: 'Novo modelo',
      items: db.demandModels,
      selectedItem: _selectedModel,
      titleBuilder: (m) => m.name,
      subtitleBuilder: (m) => 'Configuração Padrão',
      onSelect: (val) => setState(() => _selectedModel = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        final timeCtrl = TextEditingController(text: '08:00 - 17:00');
        final vacCtrl = TextEditingController(text: '1');
        _showFormDialog(
          title: 'Novo Modelo', 
          fields: [
            _buildTextField('Nome do Modelo', nameCtrl),
            _buildTextField('Horário Padrão', timeCtrl),
            _buildTextField('Vagas Padrão', vacCtrl),
          ], 
          onSave: () {
            final newModel = AppDemandModel(id: DateTime.now().toString(), name: nameCtrl.text, clientId: '', roleId: '', defaultTime: timeCtrl.text, defaultVacancies: int.tryParse(vacCtrl.text) ?? 1);
            db.demandModels.add(newModel);
            _selectedModel = newModel;
          }
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () {
          db.demandModels.remove(item);
          _selectedModel = db.demandModels.isNotEmpty ? db.demandModels.first : null;
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE MODELO', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final timeCtrl = TextEditingController(text: item.defaultTime);
                    final vacCtrl = TextEditingController(text: item.defaultVacancies.toString());
                    _showFormDialog(
                      title: 'Editar Modelo', 
                      fields: [
                        _buildTextField('Nome do Modelo', nameCtrl),
                        _buildTextField('Horário Padrão', timeCtrl),
                        _buildTextField('Vagas Padrão', vacCtrl),
                      ], 
                      onSave: () {
                        item.name = nameCtrl.text;
                        item.defaultTime = timeCtrl.text;
                        item.defaultVacancies = int.tryParse(vacCtrl.text) ?? 1;
                      }
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan, side: const BorderSide(color: AppColors.neonCyan)),
                )
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionBlock('ESTRUTURA', [
              _buildFakeField('Nome do modelo', item.name),
            ]),
            _buildSectionBlock('EXECUÇÃO', [
              _buildFakeField('Horário padrão', item.defaultTime),
              _buildFakeField('Vagas', item.defaultVacancies.toString()),
            ]),
          ],
        );
      }
    );
  }

  // --- ABA 7: CONFIGURAÇÕES GERAIS ---
  Widget _buildGeneralSettingsTab() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONFIGURAÇÕES GERAIS', style: TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  const Text('Controlar o comportamento base do sistema em todas as operações.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSectionBlock('PADRÕES DE EXECUÇÃO', [
                          _buildEditableField('Tempo mínimo padrão (SLA)', '4 horas'),
                          _buildEditableField('Exigir foto padrão', 'Sim'),
                          _buildEditableField('Exigir localização padrão', 'Sim'),
                        ], isColumn: true),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _buildSectionBlock('SEGURANÇA E FINANCEIRO', [
                          _buildEditableField('Prazo padrão de pagamento', '30 dias úteis'),
                          _buildEditableField('Bloquear pagamento sem checkout', 'Sim (Trava ISO)'),
                          _buildEditableField('Bloquear pagamento fora da localização', 'Sim (Raio de segurança)'),
                        ], isColumn: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas com sucesso!')));
                      },
                      icon: const Icon(IconsaxPlusLinear.save_2, color: Colors.black, size: 18),
                      label: const Text('SALVAR CONFIGURAÇÕES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // --- GENERIC LIST VIEW BUILDER ---
  Widget _buildStandardListWithDetails<T>({
    required String buttonLabel,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) titleBuilder,
    required String Function(T) subtitleBuilder,
    required Function(T) onSelect,
    required Function() onAdd,
    required Function(T) onDelete,
    required Widget Function(T) detailsBuilder,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(IconsaxPlusLinear.search_normal, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(onPressed: onAdd, icon: const Icon(IconsaxPlusLinear.add_square, color: AppColors.neonCyan), tooltip: buttonLabel)
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: items.isEmpty ? const Center(child: Text('Nenhum item.', style: TextStyle(color: AppColors.textSecondary))) : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedItem;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.neonCyan.withOpacity(0.1),
                        title: Text(titleBuilder(item), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitleBuilder(item), style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(IconsaxPlusLinear.trash, color: Colors.redAccent, size: 16), onPressed: () => onDelete(item)),
                            const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.textSecondary, size: 16),
                          ],
                        ),
                        onTap: () => onSelect(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
            child: selectedItem == null || !items.contains(selectedItem) 
              ? const Center(child: Text('Selecione ou crie um item', style: TextStyle(color: AppColors.textSecondary))) 
              : detailsBuilder(selectedItem),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionBlock(String title, List<Widget> children, {bool isColumn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          isColumn 
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: c)).toList())
            : Row(children: children.map((c) => Expanded(child: c)).toList()),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFakeField(String label, String value, {IconData? icon, bool isLong = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.neonCyan, size: 14), const SizedBox(width: 8)],
              Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, String initialValue) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
