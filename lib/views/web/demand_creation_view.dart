import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class DemandCreationView extends StatefulWidget {
  const DemandCreationView({super.key});

  @override
  State<DemandCreationView> createState() => _DemandCreationViewState();
}

class _DemandCreationViewState extends State<DemandCreationView> {
  final _formKey = GlobalKey<FormState>();
  
  // Variáveis do formulário
  String? _selectedStore;
  String? _selectedRole;
  int _slotsCount = 1; // Quantidade de pessoas para a loja
  double _dailyValue = 100.0;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Espaço reservado para o Sidebar do Dashboard
          Container(
            width: 80,
            color: AppColors.darkBlue,
            child: const Column(
              children: [
                SizedBox(height: 30),
                Icon(Icons.check_circle_outline, color: AppColors.cyan, size: 32),
                SizedBox(height: 40),
                Icon(Icons.assignment_add, color: AppColors.white, size: 28), // Menu Ativo
              ],
            ),
          ),

          // Conteúdo de Criação da Demanda
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gerar Novas Demandas (Vagas)', style: AppTextStyles.title),
                  const SizedBox(height: 10),
                  Text('Crie vagas e defina a quantidade de colaboradores (slots) necessários para cada loja.', style: AppTextStyles.subtitle),
                  const SizedBox(height: 40),

                  Container(
                    width: 600, // Tamanho fixo para o formulário no Web
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seleção da Loja
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Selecione a Loja',
                              prefixIcon: const Icon(Icons.store, color: AppColors.primaryBlue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['Supermercado Central', 'Atacadão Premium', 'Farmácia Vida']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedStore = value),
                          ),
                          const SizedBox(height: 25),

                          // Função e Valor
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Função do Colaborador',
                                    prefixIcon: const Icon(Icons.work, color: AppColors.primaryBlue),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: ['Promotor de Vendas', 'Repositor', 'Sampling', 'Degustador']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedRole = value),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: '150.00',
                                  decoration: InputDecoration(
                                    labelText: 'Valor da Diária (R\$)',
                                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.successGreen),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => _dailyValue = double.tryParse(value) ?? 100.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // O DETALHE IMPORTANTE: Quantidade de Pessoas (Slots)
                          Text('Quantidade de Pessoas para essa Loja:', style: AppTextStyles.subtitle.copyWith(color: AppColors.darkBlue)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_slotsCount > 1) setState(() => _slotsCount--);
                                },
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Text('$_slotsCount vagas', style: AppTextStyles.title.copyWith(fontSize: 24)),
                              const SizedBox(width: 15),
                              IconButton(
                                onPressed: () {
                                  setState(() => _slotsCount++);
                                },
                                icon: const Icon(Icons.add_circle, color: AppColors.successGreen, size: 30),
                              ),
                              const Spacer(),
                              
                              // Seleção de Data (Apenas ilustrativo no Web)
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.calendar_month, color: AppColors.primaryBlue),
                                label: Text(
                                  'Data: ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}', 
                                  style: const TextStyle(color: AppColors.primaryBlue),
                                ),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                              )
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Botão de Publicar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_selectedStore != null && _selectedRole != null) {
                                  // Aqui a gente aciona o FirebaseService e cria a demanda
                                  // Passando exatamente a quantidade de slots escolhida!
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sucesso! Criadas $_slotsCount vagas de $_selectedRole para $_selectedStore!'),
                                      backgroundColor: AppColors.successGreen,
                                    )
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('PUBLICAR DEMANDAS', style: AppTextStyles.button),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
