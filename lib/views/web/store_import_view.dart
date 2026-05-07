import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class StoreImportView extends StatefulWidget {
  const StoreImportView({super.key});

  @override
  State<StoreImportView> createState() => _StoreImportViewState();
}

class _StoreImportViewState extends State<StoreImportView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeader(title: 'Gestão de Lojas', subtitle: 'Gerencie pontos de venda, cadastre novas unidades ou importe listas massivas.'),
            const SizedBox(height: 30),
            const TabBar(
              isScrollable: true,
              indicatorColor: AppColors.neonCyan,
              labelColor: AppColors.neonCyan,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'PESQUISAR LOJAS'),
                Tab(text: 'CADASTRO MANUAL'),
                Tab(text: 'IMPORTAÇÃO EM MASSA'),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSearchTab(),
                  _buildManualEntryTab(),
                  _buildBulkImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        PremiumCard(
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filtrar por Nome, Cidade ou CNPJ...', 
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14), 
                    prefixIcon: Icon(Icons.search, color: AppColors.neonCyan), 
                    border: InputBorder.none
                  )
                )
              ),
              ElevatedButton(
                onPressed: () {}, 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan), 
                child: const Text('FILTRAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: PremiumCard(
            child: ListView.separated(
              itemCount: 10,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.store, color: AppColors.neonCyan),
                title: Text('Atacadão - Unidade #$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('CNPJ: 00.000.000/0001-0$index | São Paulo - SP', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryTab() {
    return PremiumCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados da Unidade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildField('Nome da Loja'),
            _buildField('CNPJ'),
            _buildField('Endereço Completo'),
            _buildField('Responsável na Loja'),
            _buildField('Telefone / WhatsApp'),
            _buildField('Latitude'),
            _buildField('Longitude'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.save, color: Colors.black), 
                label: const Text('CADASTRAR UNIDADE AGORA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan, 
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkImportTab() {
    return PremiumCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppColors.neonCyan, size: 60),
          const SizedBox(height: 20),
          const Text('Arraste sua planilha .xlsx aqui', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              OutlinedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.download, color: AppColors.neonCyan), 
                label: const Text('MODELO XLS', style: TextStyle(color: AppColors.neonCyan)), 
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.neonCyan), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.upload, color: Colors.black), 
                label: const Text('SELECIONAR ARQUIVO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10), 
    child: TextField(
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12), 
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)), 
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan))
      )
    )
  );
}
