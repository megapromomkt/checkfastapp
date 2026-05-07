import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'daily_execution_view.dart';
import 'check_in_tab_view.dart';
import 'store_detail_view.dart';
import 'task_timeline_view.dart';
import 'payment_details_view.dart';
import 'edit_profile_view.dart';
import 'pix_key_view.dart';
import 'package:url_launcher/url_launcher.dart';

class PromoterHomeView extends StatefulWidget {
  const PromoterHomeView({super.key});

  @override
  State<PromoterHomeView> createState() => _PromoterHomeViewState();
}

class _PromoterHomeViewState extends State<PromoterHomeView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget body = IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeTab(isDesktop),
        _buildLojasTab(isDesktop),
        _buildTarefasTab(isDesktop),
        _buildCheckInTab(isDesktop),
        _buildFinanceiroTab(isDesktop),
        _buildPerfilTab(isDesktop),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      extendBody: !isDesktop, // Para o Glassmorphism no mobile
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
      body: isDesktop 
        ? Row(
            children: [
              _buildDesktopSidebar(),
              Expanded(child: body),
            ],
          )
        : body,
    );
  }

  Widget _buildMobileBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() => _selectedIndex = index);
          },
          backgroundColor: AppColors.cardDark.withOpacity(0.6),
          selectedItemColor: AppColors.neonCyan,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.home_2), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.shop), label: 'Lojas'),
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.task_square), label: 'Tarefas'),
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.location), label: 'Check-in'),
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.wallet_2), label: 'Ganhos'),
            BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.profile_circle), label: 'Perfil'),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 250,
      color: AppColors.cardDark,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(30.0),
            child: Row(
              children: [
                Icon(IconsaxPlusBold.verify, color: AppColors.neonCyan, size: 28),
                SizedBox(width: 10),
                Text('CheckFast', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(0, IconsaxPlusLinear.home_2, 'Home'),
          _buildSidebarItem(1, IconsaxPlusLinear.shop, 'Lojas disponíveis'),
          _buildSidebarItem(2, IconsaxPlusLinear.task_square, 'Minhas tarefas'),
          _buildSidebarItem(3, IconsaxPlusLinear.location, 'Check-in'),
          _buildSidebarItem(4, IconsaxPlusLinear.wallet_2, 'Ganhos'),
          _buildSidebarItem(5, IconsaxPlusLinear.profile_circle, 'Perfil'),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.neonCyan.withOpacity(0.2), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.3))
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconsaxPlusLinear.cup, color: AppColors.successEmerald, size: 24),
                SizedBox(height: 10),
                Text('Mais tarefas\nmais ganhos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 5),
                Text('Complete tarefas e ganhe mais!', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue : Colors.transparent,
          border: Border(left: BorderSide(color: isSelected ? AppColors.neonCyan : Colors.transparent, width: 4))
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
            const SizedBox(width: 15),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // 1. TELA HOME
  Widget _buildHomeTab(bool isDesktop) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá, Ricardo!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    Text('Segunda-feira, 27 de Abril', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(IconsaxPlusLinear.notification, color: Colors.white, size: 28),
                    const SizedBox(width: 20),
                    const CircleAvatar(radius: 20, backgroundColor: AppColors.electricBlue, child: Text('RS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                    if (isDesktop) const Icon(IconsaxPlusLinear.arrow_down_1, color: AppColors.textSecondary, size: 16)
                  ],
                )
              ],
            ),
            const SizedBox(height: 30),
            
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [AppColors.cardDark, Color(0xFF0F3A20)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(text: const TextSpan(children: [
                          TextSpan(text: 'Você tem ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          TextSpan(text: '12', style: TextStyle(color: AppColors.neonCyan, fontSize: 24, fontWeight: FontWeight.w900)),
                          TextSpan(text: ' oportunidades próximas', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ])),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          icon: const Text('VER LOJAS DISPONÍVEIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          label: const Icon(IconsaxPlusLinear.arrow_right_1, color: Colors.white, size: 18)
                        )
                      ],
                    ),
                  ),
                  if (isDesktop) const Icon(IconsaxPlusLinear.map, color: AppColors.successEmerald, size: 100)
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('Resumo rápido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 2.2,
              children: [
                _buildNewStatCard(IconsaxPlusLinear.task_square, 'Tarefas hoje', '02', 'Em andamento', AppColors.electricBlue),
                _buildNewStatCard(IconsaxPlusLinear.timer_1, 'Horas totais', '42h', 'Registradas', AppColors.successEmerald),
                _buildNewStatCard(IconsaxPlusLinear.wallet_2, 'Ganhos do mês', 'R\$ 1.280,00', 'Total acumulado', Colors.purpleAccent),
                _buildNewStatCard(IconsaxPlusLinear.calendar_1, 'Próximo pagamento', '30/04', 'Quarta-feira', AppColors.alertOrange),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text('Avisos importantes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _buildNewAlertCard('Check-out pendente: Atacadão Lapa', 'Você possui um check-out pendente em 1 tarefa.', AppColors.alertOrange, 'Finalizar check-out', () => setState(() => _selectedIndex = 3)),
            const SizedBox(height: 10),
            _buildNewAlertCard('Pagamento disponível para saque PIX', 'Você tem um valor disponível para saque.', AppColors.successEmerald, 'Ver meus ganhos', () => setState(() => _selectedIndex = 4)),

            const SizedBox(height: 40),
            const Text('Ações rápidas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionCard(IconsaxPlusLinear.shop, 'Lojas disponíveis', 'Ver oportunidades', AppColors.electricBlue, 1),
                _buildQuickActionCard(IconsaxPlusLinear.task_square, 'Minhas tarefas', 'Ver tarefas aceitas', AppColors.electricBlue, 2),
                _buildQuickActionCard(IconsaxPlusLinear.location, 'Check-in', 'Registrar presença', AppColors.successEmerald, 3),
                _buildQuickActionCard(IconsaxPlusLinear.wallet_2, 'Meus ganhos', 'Ver pagamentos', Colors.purpleAccent, 4),
              ],
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildNewStatCard(IconData icon, String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNewAlertCard(String title, String subtitle, Color color, String btnText, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(IconsaxPlusBold.info_circle, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Row(
              children: [
                Text(btnText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Icon(IconsaxPlusLinear.arrow_right_3, color: color, size: 18)
              ],
            )
          )
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String subtitle, Color color, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.textSecondary, size: 18)
          ],
        ),
      ),
    );
  }

  // 2. TELA LOJAS
  Widget _buildLojasTab(bool isDesktop) {
    return _buildListTab(
      isDesktop,
      'LOJAS DISPONÍVEIS', 
      'Encontre e aceite tarefas próximas a você.', 
      [
        _buildStoreCard('ATACADÃO LAPA', 'REDE ATACADÃO', '1.2 KM', 'R\$ 150,00', 'HOJE', AppColors.successEmerald),
        _buildStoreCard('CARREFOUR OSASCO', 'CARREFOUR BR', '4.5 KM', 'R\$ 180,00', 'AMANHÃ', AppColors.alertOrange),
        _buildStoreCard('PÃO DE AÇÚCAR', 'GPA S/A', '0.8 KM', 'R\$ 160,00', 'URGENTE', Colors.redAccent),
        _buildStoreCard('BIG BOMPREÇO', 'WALMART BR', '2.1 KM', 'R\$ 145,00', 'HOJE', AppColors.successEmerald),
      ]
    );
  }

  // 3. TELA TAREFAS
  Widget _buildTarefasTab(bool isDesktop) {
    return _buildListTab(
      isDesktop,
      'MINHAS TAREFAS', 
      'Acompanhe suas tarefas e status de execução.', 
      [
        _buildTaskCard('ATACADÃO LAPA', 'REDE ATACADÃO', '27/04', 'CONCLUÍDA', AppColors.successEmerald),
        _buildTaskCard('CARREFOUR OSASCO', 'CARREFOUR BR', '28/04', 'EM ANDAMENTO', AppColors.neonCyan),
        _buildTaskCard('BIG BOMPREÇO', 'WALMART BR', '29/04', 'AGENDADA', AppColors.textSecondary),
        _buildTaskCard('PÃO DE AÇÚCAR', 'GPA S/A', '24/04', 'CANCELADA', Colors.redAccent),
      ]
    );
  }

  // 4. TELA CHECK-IN (CRÍTICA)
  Widget _buildCheckInTab(bool isDesktop) {
    return CheckInTabView(isDesktop: isDesktop);
  }

  // 5. RECEBIMENTOS (FINANCEIRO)
  Widget _buildFinanceiroTab(bool isDesktop) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const PremiumHeader(title: 'Recebimentos', subtitle: 'Acompanhe seus valores e previsões.'),
            const SizedBox(height: 30),
            
            // BI DASHBOARD (GRID)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _buildBICard('R\$ 390,00', 'A receber', AppColors.neonCyan),
                _buildBICard('R\$ 780,00', 'Pago no mês', AppColors.successEmerald),
                _buildBICard('R\$ 130,00', 'Em análise', AppColors.alertOrange),
                _buildBICard('R\$ 0,00', 'Não apto', Colors.redAccent),
              ],
            ),
            
            const SizedBox(height: 30),
            _buildSectionHeader('FILTRAR POR'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              child: Row(
                children: ['Todos', 'A receber', 'Pagos', 'Em análise'].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 10), 
                  child: ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 11)), 
                    selected: f == 'Todos', 
                    onSelected: (_) {}, 
                    backgroundColor: AppColors.cardDark, 
                    selectedColor: AppColors.neonCyan.withOpacity(0.1),
                    labelStyle: TextStyle(color: f == 'Todos' ? AppColors.neonCyan : AppColors.textSecondary),
                  )
                )).toList()
              )
            ),
            
            const SizedBox(height: 25),
            _buildSectionHeader('LISTA DE RECEBIMENTOS'),
            Expanded(
              child: ListView(
                children: [
                  _buildFinanceCard('ATACADÃO LAPA', '25/04', 'R\$ 150,00', 'Pago', AppColors.successEmerald),
                  _buildFinanceCard('PÃO DE AÇÚCAR', '26/04', 'R\$ 160,00', 'Em análise', AppColors.alertOrange),
                  _buildFinanceCard('CARREFOUR CENTRO', '27/04', 'R\$ 180,00', 'Aprovado', AppColors.electricBlue),
                  _buildFinanceCard('LOJAS AMERICANAS', '20/04', 'R\$ 0,00', 'Não apto', Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildBICard(String value, String label, Color color) => PremiumCard(
    padding: const EdgeInsets.all(15), 
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)), 
        const SizedBox(height: 5), 
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))
      ]
    )
  );
  
  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12), 
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))
  );

  // 6. PERFIL
  Widget _buildPerfilTab(bool isDesktop) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
          children: [
            const CircleAvatar(radius: 45, backgroundColor: AppColors.cardDark, child: Text('RS', style: TextStyle(color: AppColors.neonCyan, fontSize: 32, fontWeight: FontWeight.w900))),
            const SizedBox(height: 15),
            const Text('Ricardo Souza', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('CPF: 123.456.789-00', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 40),
            _buildProfileItem(IconsaxPlusLinear.edit, 'Editar Meus Dados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView()))),
            _buildProfileItem(IconsaxPlusLinear.card_receive, 'Minha Chave PIX', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PixKeyView()))),
            _buildProfileItem(IconsaxPlusLinear.support, 'Suporte CheckFast', onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'suporte@checkfast.com',
                queryParameters: {'subject': 'Suporte CheckFast - Ricardo Souza'}
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }
            }),
            const Spacer(),
            _buildProfileItem(IconsaxPlusLinear.logout, 'Sair do Aplicativo', color: Colors.redAccent, onTap: () => Navigator.pushReplacementNamed(context, '/')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    )));
  }

  // AUXILIARES DE UI
  Widget _buildListTab(bool isDesktop, String title, String subtitle, List<Widget> children) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 25),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.neonCyan,
                backgroundColor: AppColors.cardDark,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: children
                ),
              ),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 15),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStoreCard(String name, String network, String dist, String val, String tag, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(network, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ]
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text('Rua Gago Coutinho, 350 - Lapa, SP', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSimpleInfo(IconsaxPlusLinear.location, dist),
                _buildSimpleInfo(IconsaxPlusLinear.briefcase, 'Promotor'),
                _buildSimpleInfo(IconsaxPlusLinear.timer_1, '08h-14h'),
              ],
            ),
            const Divider(color: Colors.white10, height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(val, style: const TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.w900, fontSize: 20)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreDetailView(storeName: name, network: network))), 
                      child: const Text('DETALHES', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () {}, 
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                      child: const Text('ACEITAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11))
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: AppColors.neonCyan, size: 12), 
      const SizedBox(width: 5), 
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11))
    ]
  );

  Widget _buildTaskCard(String loc, String network, String date, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          if (status == 'AGENDADA') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => StoreDetailView(storeName: loc, network: network)));
          } else if (status != 'CANCELADA') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TaskTimelineView(storeName: loc, status: status)));
          }
        },
        child: PremiumCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('$network • $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String loc, String date, String val, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentDetailsView(storeName: loc, status: status, value: val, date: date))),
        child: PremiumCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Text('Projeto: Reposição Verão', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('Executado em: $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 5),
                  const Text('Prev: 05/05', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, {Color color = Colors.white, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color == Colors.white ? AppColors.neonCyan : color, size: 22),
              const SizedBox(width: 20),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Icon(IconsaxPlusLinear.arrow_right_3, color: color.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
