import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/constants/premium_theme.dart';
import '../../../core/data/test_database.dart';
import '../../../models/app_models.dart';

class CreateDemandModal extends StatefulWidget {
  const CreateDemandModal({super.key});

  @override
  State<CreateDemandModal> createState() => _CreateDemandModalState();
}

class _CreateDemandModalState extends State<CreateDemandModal> {
  final db = TestDatabase.instance;

  // Form State
  String? _selectedClient;
  String? _selectedProject;
  String? _selectedStore = 'Atacadão Jandira';
  String _selectedRole = 'Promotor';
  final _nameController = TextEditingController();
  final _vagasController = TextEditingController(text: '1');
  final _instructionsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _entryTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _exitTime = const TimeOfDay(hour: 14, minute: 0);

  bool _requiresCheckIn = true;
  bool _requiresCheckOut = true;
  bool _requiresPhoto = true;
  bool _requiresLocation = true;
  int _allowedRadius = 100;
  String _priority = 'Média';

  @override
  void initState() {
    super.initState();
    _updateAutoName();
  }

  void _updateAutoName() {
    setState(() {
      _nameController.text = "${_selectedStore ?? 'Loja'} — ${_selectedRole} — ${_selectedDate.day}/${_selectedDate.month}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.spaceBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorderDark),
        ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('🔹 BLOCO 1 — ESTRUTURA'),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Cliente *', db.clients.map((e) => e.name).toList(), _selectedClient, (val) {
                        setState(() {
                          _selectedClient = val;
                          _selectedProject = null;
                        });
                      })),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDropdown('Projeto *', _selectedClient == null ? [] : db.projects.where((p) => p.clientId == db.clients.firstWhere((c) => c.name == _selectedClient).id).map((p) => p.name).toList(), _selectedProject, (val) {
                        setState(() {
                          _selectedProject = val;
                          // Aqui carregaríamos as regras automáticas do projeto
                        });
                      })),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDropdown('Loja *', db.stores.map((e) => e.name).toList(), _selectedStore, (val) {
                        setState(() {
                          _selectedStore = val;
                          _updateAutoName();
                        });
                      })),
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('🔹 BLOCO 2 — IDENTIFICAÇÃO DA DEMANDA'),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildTextField('Nome da demanda (Auto)', _nameController)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDropdown('Função', db.roles.map((e) => e.name).toList(), _selectedRole, (val) {
                        setState(() {
                          _selectedRole = val!;
                          _updateAutoName();
                        });
                      })),
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('🔹 BLOCO 3 — EXECUÇÃO'),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTimePicker('Entrada', _entryTime, (t) => setState(() => _entryTime = t))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTimePicker('Saída', _exitTime, (t) => setState(() => _exitTime = t))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField('Vagas', _vagasController)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('🔹 BLOCO 4 & 5 — REGRAS E VALIDAÇÃO'),
                  Wrap(
                    spacing: 30,
                    runSpacing: 20,
                    children: [
                      _buildSwitch('Exigir Check-in', _requiresCheckIn, (v) => setState(() => _requiresCheckIn = v)),
                      _buildSwitch('Exigir Check-out', _requiresCheckOut, (v) => setState(() => _requiresCheckOut = v)),
                      _buildSwitch('Exigir Foto', _requiresPhoto, (v) => setState(() => _requiresPhoto = v)),
                      _buildSwitch('Exigir Localização', _requiresLocation, (v) => setState(() => _requiresLocation = v)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Raio permitido (metros): ', style: TextStyle(color: AppColors.textSecondary)),
                      Slider(
                        value: _allowedRadius.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 9,
                        label: '${_allowedRadius}m',
                        activeColor: AppColors.neonCyan,
                        onChanged: (v) => setState(() => _allowedRadius = v.toInt()),
                      ),
                      Text('${_allowedRadius}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('🔹 BLOCO 7 — INSTRUÇÕES DA LOJA'),
                  _buildTextField('Instruções detalhadas (o que deve ser feito, vestimenta, regras...)', _instructionsController, maxLines: 5),
                  const SizedBox(height: 40),

                  _buildSectionTitle('🔹 BLOCO 8 — CONTROLE OPERACIONAL'),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Prioridade', ['Alta', 'Média', 'Baixa'], _priority, (val) => setState(() => _priority = val!))),
                      const SizedBox(width: 20),
                      const Expanded(child: SizedBox()), // Placeholder
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CRIAR NOVA DEMANDA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('Vincule projetos e defina regras de execução.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(IconsaxPlusLinear.close_circle, color: AppColors.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _saveDemand('RASCUNHO'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            ),
            child: const Text('SALVAR RASCUNHO', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => _saveDemand('ABERTAS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: const Text('PUBLICAR DEMANDA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveDemand(String status) {
    if (_selectedClient == null || _selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione Cliente e Projeto obrigatórios.')));
      return;
    }

    final newDemand = AppDemand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      storeName: _selectedStore!,
      network: 'REDE TESTE',
      address: 'Endereço Automático, 123',
      role: _selectedRole,
      distance: '0.0 KM',
      timeRange: '${_entryTime.format(context)} - ${_exitTime.format(context)}',
      value: 150.0,
      date: '${_selectedDate.day}/${_selectedDate.month}',
      urgency: 'HOJE',
      status: status,
      clientName: _selectedClient,
      projectName: _selectedProject,
      totalVagas: int.tryParse(_vagasController.text) ?? 1,
      instructions: _instructionsController.text,
      priority: _priority,
      requiresCheckIn: _requiresCheckIn,
      requiresCheckOut: _requiresCheckOut,
      requiresPhoto: _requiresPhoto,
      requiresLocation: _requiresLocation,
      allowedRadius: _allowedRadius,
    );

    db.demands.add(newDemand);
    Navigator.pop(context, true);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(title, style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              hint: const Text('Selecione...', style: TextStyle(color: Colors.white24, fontSize: 13)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardDark,
            contentPadding: const EdgeInsets.all(15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.neonCyan),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DATA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date != null) {
              setState(() => _selectedDate = date);
              _updateAutoName();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.calendar, color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 15),
                Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) onSelected(t);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.timer, color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 15),
                Text(time.format(context), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
