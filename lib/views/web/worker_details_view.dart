import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class WorkerDetailsView extends StatefulWidget {
  const WorkerDetailsView({super.key});

  @override
  State<WorkerDetailsView> createState() => _WorkerDetailsViewState();
}

class _WorkerDetailsViewState extends State<WorkerDetailsView> {
  bool _showProfile = false;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: 'Gestão de Colaboradores', subtitle: 'Busque promotores, valide documentos e audite presenças.'),
          const SizedBox(height: 30),
          Expanded(
            child: _showProfile ? _buildProfileView() : _buildSearchView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de Busca com Botão de Filtros Avançados
        PremiumCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por Nome ou CPF...', 
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 14), 
                        prefixIcon: Icon(Icons.search, color: AppColors.neonCyan), 
                        border: InputBorder.none
                      )
                    )
                  ),
                  // Botão de expandir filtros
                  IconButton(
                    onPressed: () => setState(() => _showFilters = !_showFilters), 
                    icon: Icon(Icons.tune, color: _showFilters ? AppColors.neonCyan : Colors.white38)
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {}, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan, 
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ), 
                    child: const Text('BUSCAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
              
              // Painel de Filtros Avançados (Expandível)
              if (_showFilters) ...[
                const Divider(color: Colors.white10, height: 40),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('Status Operacional', ['Todos', 'Ativo', 'Em Análise', 'Reprovado', 'Bloqueado'])),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFilterDropdown('Cidade / Região', ['Todas', 'São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Curitiba'])),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFilterDropdown('Cargo / Função', ['Todos', 'Promotor', 'Supervisor', 'Repositor', 'Degustador'])),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFilterDropdown('Treinamento', ['Todos', 'Concluído', 'Pendente', 'Expirado'])),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        // Relatório de Resultados
        const Text('Todos os Colaboradores (Relatório)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: PremiumCard(
            child: ListView.separated(
              itemCount: 15,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white10, 
                  child: Icon(Icons.person_outline, color: AppColors.neonCyan)
                ),
                title: Text(index == 0 ? 'Ricardo Lira' : 'Colaborador #$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('CPF: 123.456.789-0$index | Status: ATIVO | SP - Capital', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: ElevatedButton(
                  onPressed: () => setState(() => _showProfile = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('VER DETALHES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, 
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)), 
      DropdownButtonFormField<String>(
        value: options[0], 
        dropdownColor: AppColors.cardDark, 
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neonCyan, size: 16),
        decoration: const InputDecoration(border: InputBorder.none), 
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(), 
        onChanged: (v) {}
      )
    ]
  );

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _showProfile = false),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan, size: 16),
          label: const Text('VOLTAR PARA LISTA GERAL', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.neonCyan,
                  labelColor: AppColors.neonCyan,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'DADOS BÁSICOS'),
                    Tab(text: 'DOCUMENTAÇÃO'),
                    Tab(text: 'HISTÓRICO'),
                    Tab(text: 'FINANCEIRO'),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: TabBarView(
                    children: [
                      _GeneralInfoTab(),
                      _DocsTab(),
                      _HistoryTab(),
                      _FinancialTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneralInfoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: ListView(
      children: [
        _buildInfo('NOME COMPLETO', 'Ricardo Lira'),
        _buildInfo('CPF', '123.456.789-00'),
        _buildInfo('CARGO', 'Promotor de Vendas'),
        _buildInfo('CIDADE', 'São Paulo - SP'),
        _buildInfo('STATUS', 'ATIVO', isSuccess: true),
      ],
    ),
  );

  Widget _buildInfo(String l, String v, {bool isSuccess = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)), 
      Text(v, style: TextStyle(color: isSuccess ? AppColors.success : Colors.white, fontWeight: FontWeight.bold))
    ])
  );
}

class _DocsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Column(
      children: [
        _buildDocRow('RG (Frente)', true),
        _buildDocRow('RG (Verso)', true),
        _buildDocRow('Certificado de Treinamento', true),
      ],
    ),
  );

  Widget _buildDocRow(String l, bool v) => ListTile(
    leading: const Icon(Icons.file_present_outlined, color: AppColors.electricBlue), 
    title: Text(l, style: const TextStyle(color: Colors.white, fontSize: 14)), 
    trailing: v ? const Icon(Icons.verified, color: AppColors.neonCyan) : const Icon(Icons.pending, color: Colors.white24)
  );
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: ListView.separated(
      itemCount: 5, 
      separatorBuilder: (_, __) => const Divider(color: Colors.white10), 
      itemBuilder: (c, i) => ListTile(
        leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
        title: Text('Check-in Loja Atacadão #$i', style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: const Text('Localização validada e foto auditada.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      )
    ),
  );
}

class _FinancialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Column(
      children: [
        const ListTile(
          title: Text('TOTAL ACUMULADO', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)), 
          trailing: Text('R\$ 1.250,00', style: TextStyle(color: AppColors.neonCyan, fontSize: 24, fontWeight: FontWeight.bold))
        ),
        const Divider(color: Colors.white10),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {}, 
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
          child: const Text('LIBERAR PAGAMENTO PIX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
