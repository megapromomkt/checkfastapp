import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class ClientsManagementView extends StatefulWidget {
  const ClientsManagementView({super.key});

  @override
  State<ClientsManagementView> createState() => _ClientsManagementViewState();
}

class _ClientsManagementViewState extends State<ClientsManagementView> {
  bool _isRegistering = false;
  bool _viewingClient = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: 'Gestão de Clientes', subtitle: 'Base de governança, regras de operação e análise estratégica ISO-ready.'),
          const SizedBox(height: 30),
          Expanded(
            child: _viewingClient 
              ? _buildClientDossier() 
              : (_isRegistering ? _buildRegisterForm() : _buildClientsList()),
          ),
        ],
      ),
    );
  }

  // --- TELA 1: LISTA DE CLIENTES (GOVERNANÇA) ---
  Widget _buildClientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumCard(
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por Nome ou CNPJ...', 
                    prefixIcon: Icon(Icons.search, color: AppColors.neonCyan), 
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14)
                  )
                )
              ),
              _buildSmallFilter('Status'),
              _buildSmallFilter('Segmento'),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isRegistering = true), 
                icon: const Icon(Icons.add, color: Colors.black, size: 18), 
                label: const Text('NOVO CLIENTE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: PremiumCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowHeight: 60,
                  columns: const [
                    DataColumn(label: Text('NOME', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('CNPJ', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SEGMENTO', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('TIPO', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('STATUS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('AÇÕES', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(5, (index) => DataRow(cells: [
                    DataCell(Text(index == 0 ? 'Nestlé Brasil' : 'Cliente Exemplo #$index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    const DataCell(Text('00.000.000/0001-91', style: TextStyle(fontSize: 12))),
                    const DataCell(Text('Alimentício', style: TextStyle(fontSize: 12))),
                    const DataCell(Text('Exclusivo', style: TextStyle(fontSize: 12))),
                    DataCell(_buildStatusBadge(index == 1 ? 'EM IMPLANTAÇÃO' : 'ATIVO')),
                    DataCell(Row(
                      children: [
                        IconButton(onPressed: () => setState(() => _viewingClient = true), icon: const Icon(Icons.analytics_outlined, color: AppColors.neonCyan, size: 20)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note, color: Colors.white24, size: 20)),
                      ],
                    )),
                  ])),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- TELA 2: CADASTRO ESTRATÉGICO (6 BLOCOS) ---
  Widget _buildRegisterForm() {
    return ListView(
      children: [
        Row(
          children: [
            IconButton(onPressed: () => setState(() => _isRegistering = false), icon: const Icon(Icons.arrow_back, color: AppColors.neonCyan)),
            const Text('Cadastro de Governança do Cliente', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 30),
        _buildFormBlock('🔹 BLOCO 1 — IDENTIFICAÇÃO EMPRESARIAL', [
          Row(children: [Expanded(child: _buildField('Nome Fantasia')), const SizedBox(width: 20), Expanded(child: _buildField('Razão Social'))]),
          const SizedBox(height: 15),
          Row(children: [Expanded(child: _buildField('CNPJ')), const SizedBox(width: 20), Expanded(child: _buildField('Segmento de Atuação'))]),
        ]),
        _buildFormBlock('🔹 BLOCO 2 — MATRIZ DE CONTATOS', [
          Row(children: [Expanded(child: _buildField('Responsável Principal')), const SizedBox(width: 20), Expanded(child: _buildField('E-mail Corporativo'))]),
          const SizedBox(height: 15),
          Row(children: [Expanded(child: _buildField('Contato Operacional')), const SizedBox(width: 20), Expanded(child: _buildField('Contato Financeiro'))]),
        ]),
        _buildFormBlock('🔥 🔹 BLOCO 3 — MODELO DE PROJETO (REGRAS DE HERANÇA)', [
           _buildDropdown('Tipo de Projeto Padrão', ['Exclusivo', 'Compartilhado', 'Misto']),
           const SizedBox(height: 15),
           Row(children: [
             Expanded(child: _buildField('Mínimo de Horas para Pagamento (ex: 4h)')),
             const SizedBox(width: 20),
             Expanded(child: _buildDropdown('Modelo de Remuneração', ['Por Diária', 'Por Hora', 'Misto'])),
           ]),
           const SizedBox(height: 15),
           _buildToggleRow('Exigir Biometria Facial no Check-in/Checkout'),
           _buildToggleRow('Validar Geolocalização (Raio de 200m)'),
           _buildToggleRow('Bloquear Pagamento sem Comprovação de Horas'),
        ]),
        _buildFormBlock('🔗 BLOCO 4 — GESTÃO DE SLA & COMPLIANCE', [
           Row(children: [
             Expanded(child: _buildField('Tempo de Resposta (SLA)')),
             const SizedBox(width: 20),
             Expanded(child: _buildDropdown('Prioridade Operacional', ['Alta (Crítica)', 'Média', 'Baixa'])),
           ]),
        ]),
        _buildFormBlock('📁 BLOCO 5 — REPOSITÓRIO DE DOCUMENTOS ISO', [
           Container(
             padding: const EdgeInsets.all(30),
             decoration: BoxDecoration(border: Border.all(color: Colors.white10, style: BorderStyle.none), borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(0.02)),
             child: const Column(children: [Icon(Icons.upload_file, color: AppColors.neonCyan, size: 40), SizedBox(height: 15), Text('Arraste Contratos, Aditivos e Briefings (PDF)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))]),
           ),
        ]),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: () => setState(() => _isRegistering = false), 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan, 
              padding: const EdgeInsets.all(22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 20,
              shadowColor: AppColors.neonCyan.withOpacity(0.3)
            ), 
            child: const Text('SALVAR CLIENTE ESTRATÉGICO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 3))
          )
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- TELA 3: DOSSIÊ ANALÍTICO DO CLIENTE (ABAS) ---
  Widget _buildClientDossier() {
    return DefaultTabController(
      length: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _viewingClient = false), icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan, size: 18)),
              const Text('Nestlé Brasil Ltda', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildStatusBadge('ATIVO'),
            ],
          ),
          const SizedBox(height: 20),
          const TabBar(
            isScrollable: true, 
            indicatorColor: AppColors.neonCyan, 
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'RESUMO'), Tab(text: 'PROJETOS'), Tab(text: 'LOJAS'), 
              Tab(text: 'EQUIPE'), Tab(text: 'FINANCEIRO'), Tab(text: 'OCORRÊNCIAS'), Tab(text: 'RELATÓRIOS')
            ]
          ),
          const SizedBox(height: 30),
          Expanded(
            child: TabBarView(
              children: [
                _buildResumoTab(),
                _buildPlaceholder('Aba Projetos (Somente Leitura)'),
                _buildPlaceholder('Aba Lojas Vinculadas'),
                _buildPlaceholder('Aba Equipe Histórica'),
                _buildFinanceiroTab(),
                _buildPlaceholder('Aba Gestão de Ocorrências'),
                _buildRelatoriosTab(),
              ]
            )
          )
        ],
      ),
    );
  }

  Widget _buildResumoTab() {
    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard('PROJETOS ATIVOS', '12', Icons.assignment_outlined),
            const SizedBox(width: 20),
            _buildSummaryCard('LOJAS ATIVAS', '450', Icons.storefront),
            const SizedBox(width: 20),
            _buildSummaryCard('PESSOAS EM LOJA', '84', Icons.person_pin_circle_outlined),
            const SizedBox(width: 20),
            _buildSummaryCard('FATURAMENTO MÊS', 'R\$ 125.4k', Icons.account_balance_wallet_outlined),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(child: PremiumCard(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bar_chart, color: Colors.white10, size: 80), const SizedBox(height: 20), Text('Gráficos de Performance e Execução (%)', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)))])))),
      ],
    );
  }

  Widget _buildFinanceiroTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Histórico de Faturamento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('EXPORTAR FINANCEIRO (XLS)')),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(child: PremiumCard(child: const Center(child: Text('Tabela de Diárias, Projetos e Pagamentos Pendentes', style: TextStyle(color: AppColors.textSecondary))))),
      ],
    );
  }

  Widget _buildRelatoriosTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, color: AppColors.neonCyan, size: 60),
          const SizedBox(height: 20),
          const Text('Exportação Estratégica Massiva', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildExportBtn('PRESENÇA (XLS)'),
              const SizedBox(width: 20),
              _buildExportBtn('FINANCEIRO (XLS)'),
              const SizedBox(width: 20),
              _buildExportBtn('EXECUÇÃO (XLS)'),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPERS DE INTERFACE ---
  Widget _buildFormBlock(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 25), 
    padding: const EdgeInsets.all(30), 
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorderDark)), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)), 
      const SizedBox(height: 25), 
      ...children
    ])
  );

  Widget _buildField(String l) => TextField(
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: l, 
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
    )
  );

  Widget _buildDropdown(String l, List<String> o) => DropdownButtonFormField<String>(
    decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11)), 
    value: o[0], 
    dropdownColor: AppColors.cardDark,
    items: o.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14, color: Colors.white)))).toList(), 
    onChanged: (v) {}
  );

  Widget _buildToggleRow(String l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.white, fontSize: 13)), 
      Switch(value: true, onChanged: (v) {}, activeColor: AppColors.neonCyan)
    ])
  );

  Widget _buildSummaryCard(String l, String v, IconData i) => Expanded(
    child: PremiumCard(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(i, color: AppColors.neonCyan, size: 28), 
        const SizedBox(height: 15), 
        Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)), 
        const SizedBox(height: 5),
        Text(v, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))
      ])
    )
  );

  Widget _buildExportBtn(String t) => ElevatedButton.icon(
    onPressed: () {}, 
    icon: const Icon(Icons.file_download_outlined, size: 16), 
    label: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
  );

  Widget _buildPlaceholder(String t) => Center(child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 2)));

  Widget _buildStatusBadge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
    decoration: BoxDecoration(
      color: s == 'ATIVO' ? AppColors.successEmerald.withOpacity(0.1) : Colors.orange.withOpacity(0.1), 
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: s == 'ATIVO' ? AppColors.successEmerald.withOpacity(0.3) : Colors.orange.withOpacity(0.3))
    ), 
    child: Text(s, style: TextStyle(color: s == 'ATIVO' ? AppColors.successEmerald : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold))
  );

  Widget _buildSmallFilter(String l) => Padding(
    padding: const EdgeInsets.only(left: 20), 
    child: Row(children: [
      Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
    ])
  );
}
