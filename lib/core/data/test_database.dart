import '../../models/app_models.dart';
import '../../models/register_models.dart';

class TestDatabase {
  static final TestDatabase instance = TestDatabase._init();
  TestDatabase._init();

  // Tabelas de Banco de Dados Mockadas
  List<AppDemand> demands = [];
  List<AppPresence> presenceRecords = [];
  List<AppPayment> payments = [];
  List<AdminFinancialBatch> financialBatches = [];

  // Novos dados para o fluxo de demandas
  List<AppClient> clients = [];
  List<AppProject> projects = [];
  List<AppStore> stores = [];
  List<AppRole> roles = [];
  List<AppPaymentRule> paymentRules = [];
  List<AppDemandModel> demandModels = [];

  // Variáveis globais do painel
  double currentLiquidity = 0.0;

  void clearAllData() {
    demands.clear();
    presenceRecords.clear();
    payments.clear();
    financialBatches.clear();
    currentLiquidity = 0.0;
  }

  void seedTestData() {
    clearAllData();
    currentLiquidity = 12450.0;

    // Demandas de Teste
    demands = [
      AppDemand(
        id: '1', clientId: 'c1', projectId: 'p1', storeId: 's1', roleId: 'r1',
        storeName: 'Atacadão Lapa', network: 'REDE ATACADÃO', address: 'Lapa, SP', 
        role: 'Promotor de Vendas', distance: '1.2 KM', timeRange: '08:00 - 14:00', 
        value: 150.0, date: '27/04', urgency: 'HOJE', status: 'ABERTAS',
        clientName: 'Unilever', projectName: 'Reposição Verão', totalVagas: 2, filledVagas: 0,
        priority: 'Alta'
      ),
      AppDemand(
        id: '2', clientId: 'c3', projectId: 'p3', storeId: 's2', roleId: 'r1',
        storeName: 'Carrefour Osasco', network: 'CARREFOUR BR', address: 'Osasco, SP', 
        role: 'Repositor', distance: '4.5 KM', timeRange: '09:00 - 18:00', 
        value: 180.0, date: '28/04', urgency: 'AMANHÃ', status: 'PREENCHIDAS', 
        assignedPromoter: 'Carlos Silva',
        clientName: 'Ambev', projectName: 'Exibição Brahma', totalVagas: 1, filledVagas: 1
      ),
      AppDemand(
        id: '3', clientId: 'c2', projectId: 'p3', storeId: 's1', roleId: 'r2',
        storeName: 'Pão de Açúcar', network: 'GPA S/A', address: 'Pinheiros, SP', 
        role: 'Promotor Especialista', distance: '0.8 KM', timeRange: '08:00 - 12:00', 
        value: 160.0, date: '27/04', urgency: 'URGENTE', status: 'EM ANDAMENTO', 
        assignedPromoter: 'Ana Paula',
        clientName: 'Nestlé', projectName: 'Nespresso Experience', totalVagas: 1, filledVagas: 1
      ),
    ];

    // Presenças de Teste
    presenceRecords = [
      AppPresence(id: '1', demandId: '3', promoterName: 'Ana Paula', storeName: 'Pão de Açúcar', checkInTime: '08:05', checkOutTime: '--:--', gpsValid: true, photoValid: true, status: 'EM LOJA'),
      AppPresence(id: '2', demandId: '4', promoterName: 'Ricardo Souza', storeName: 'Big Bompreço', checkInTime: '10:02', checkOutTime: '16:15', gpsValid: true, photoValid: true, status: 'FINALIZADA'),
      AppPresence(id: '3', demandId: '5', promoterName: 'Ricardo Souza', storeName: 'Lojas Americanas', checkInTime: '12:30', checkOutTime: '15:00', gpsValid: false, photoValid: true, status: 'IRREGULAR'),
    ];

    // Pagamentos de Teste
    payments = [
      AppPayment(id: '1', storeName: 'Big Bompreço', date: '26/04', value: 145.0, status: 'Aprovado'),
      AppPayment(id: '2', storeName: 'Lojas Americanas', date: '26/04', value: 0.0, status: 'Não apto'),
    ];

    // Lotes Financeiros
    financialBatches = [
      AdminFinancialBatch(id: '1', batchName: 'LOTE_PAGTO_2026_04_26', totalValue: 10200.0, isPaid: true),
      AdminFinancialBatch(id: '2', batchName: 'LOTE_PAGTO_2026_04_25', totalValue: 8500.0, isPaid: true),
      AdminFinancialBatch(id: '3', batchName: 'LOTE_PAGTO_2026_04_27', totalValue: 12450.0, isPaid: false),
    ];

    // Seed Registers
    clients = [
      AppClient(id: 'c1', name: 'Unilever', cnpj: '01.234.567/0001-89', type: 'Indústria', responsible: 'João Silva', contact: '(11) 99999-9999'),
      AppClient(id: 'c2', name: 'Nestlé', cnpj: '98.765.432/0001-10', type: 'Indústria', responsible: 'Maria Souza', contact: '(11) 88888-8888'),
      AppClient(id: 'c3', name: 'Ambev', cnpj: '11.222.333/0001-44', type: 'Bebidas', responsible: 'Carlos Lima', contact: '(11) 77777-7777'),
    ];

    projects = [
      AppProject(id: 'p1', name: 'Reposição Verão', clientId: 'c1', type: 'Exclusivo', paymentModel: 'Diária', defaultValue: 150.0),
      AppProject(id: 'p2', name: 'Lançamento Dove', clientId: 'c1', type: 'Compartilhado', paymentModel: 'Hora', defaultValue: 25.0, minHours: 4),
      AppProject(id: 'p3', name: 'Degustação KitKat', clientId: 'c2', type: 'Exclusivo', paymentModel: 'Diária', defaultValue: 180.0),
    ];

    stores = [
      AppStore(id: 's1', name: 'Atacadão Lapa', clientId: 'c1', address: 'Av. das Nações Unidas, 123', city: 'São Paulo', state: 'SP', responsible: 'Gerente Marcos'),
      AppStore(id: 's2', name: 'Carrefour Osasco', clientId: 'c3', address: 'Av. dos Autonomistas, 456', city: 'Osasco', state: 'SP', responsible: 'Gerente Ana'),
    ];

    roles = [
      AppRole(id: 'r1', name: 'Promotor', type: 'Operacional em Loja', description: 'Reposição e precificação de produtos.'),
      AppRole(id: 'r2', name: 'Degustador', type: 'Ação de Vendas', description: 'Abordagem de clientes para degustação.'),
    ];

    paymentRules = [
      AppPaymentRule(id: 'pr1', name: 'Diária Padrão', type: 'Diária', baseValue: 120.0, minHours: 8, allowException: false),
      AppPaymentRule(id: 'pr2', name: 'Hora Extra FDS', type: 'Hora', baseValue: 25.0, minHours: 4, allowException: true),
    ];

    demandModels = [
      AppDemandModel(id: 'dm1', name: 'Reposição Final de Semana', clientId: 'c1', roleId: 'r1', defaultTime: '08:00 - 17:00', defaultVacancies: 1, defaultInstructions: 'Levar EPI e crachá.'),
    ];
  }

  // --- MÉTODOS AUXILIARES DE BUSCA (REPOSITÓRIO) ---

  // Clientes
  AppClient? getClientById(String id) => clients.firstWhere((c) => c.id == id);
  
  // Projetos
  List<AppProject> getProjectsByClient(String clientId) => projects.where((p) => p.clientId == clientId).toList();
  AppProject? getProjectById(String id) => projects.firstWhere((p) => p.id == id);

  // Lojas
  List<AppStore> getStoresByClient(String clientId) => stores.where((s) => s.clientId == clientId).toList();
  AppStore? getStoreById(String id) => stores.firstWhere((s) => s.id == id);

  // Funções
  AppRole? getRoleById(String id) => roles.firstWhere((r) => r.id == id);

  // Demandas
  List<AppDemand> getDemandsByProject(String projectId) => demands.where((d) => d.projectId == projectId).toList();
  
  void addDemand(AppDemand demand) {
    demands.add(demand);
  }

  void updateDemandStatus(String id, String newStatus) {
    final index = demands.indexWhere((d) => d.id == id);
    if (index != -1) {
      demands[index].status = newStatus;
    }
  }
}
