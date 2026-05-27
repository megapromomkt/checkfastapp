import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../shared/auth_modals.dart';

class LandingPageView extends StatelessWidget {
  const LandingPageView({super.key});

  // Breakpoints
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width < 1024 && MediaQuery.of(context).size.width >= 600;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildHero(context),
            _buildMetrics(context),
            _buildHowItWorks(context),
            _buildCTA(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  double _hPad(BuildContext context) {
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 40;
    return MediaQuery.of(context).size.width * 0.1;
  }

  Widget _buildHeader(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _hPad(context), vertical: mobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onDoubleTap: () {
                  Navigator.pushNamed(context, '/megapromo');
                },
                child: const Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(width: 10),
              Text('CheckFast', style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: mobile ? 20 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              )),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => AuthModals.showPromoterLogin(context),
                child: Text('Entrar', style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: mobile ? 14 : 15,
                ))
              ),
              SizedBox(width: mobile ? 8 : 16),
              ElevatedButton(
                onPressed: () => AuthModals.showPromoterRegister(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 16 : 24,
                    vertical: mobile ? 14 : 20,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: Text(
                  mobile ? 'Cadastrar' : 'Começar agora',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                )
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final mobile = isMobile(context);
    final tablet = isTablet(context);
    final titleSize = mobile ? 36.0 : (tablet ? 48.0 : 64.0);
    final subtitleSize = mobile ? 16.0 : (tablet ? 18.0 : 20.0);
    final vPad = mobile ? 60.0 : (tablet ? 80.0 : 120.0);

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text('✨ Gestão de Trabalho por Diária 4.0', style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5
          )),
        ),
        const SizedBox(height: 28),
        Text('Trabalhe por diárias.\nDinheiro rápido e\npagamento seguro.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -2,
          )
        ),
        const SizedBox(height: 24),
        Text(
          'O CheckFast conecta você a oportunidades próximas. Aceite tarefas, comprove sua presença e receba dinheiro rápido direto na sua conta.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: subtitleSize, height: 1.6, fontWeight: FontWeight.w500)
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => AuthModals.showPromoterRegister(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text('QUERO ME CADASTRAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5))
            ),
            OutlinedButton(
              onPressed: () => AuthModals.showPromoterLogin(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cardBorder, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: AppColors.textPrimary
              ),
              child: const Text('JÁ TENHO CADASTRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))
            ),
          ],
        )
      ],
    );

    final phonePreview = Container(
      height: mobile ? 320 : 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20))
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryBlue,
              child: const Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white24, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 18)),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, Marcos Silva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Profissional Verificado', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMockItem('Atacadão Lapa', 'Check-in: 08:02', 'VÁLIDO', AppColors.success),
                    const SizedBox(height: 12),
                    _buildMockItem('Carrefour Osasco', 'Pendente', 'AGUARDANDO', Colors.orange),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Saldo à Receber', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('R\$ 1.450,00', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 18)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: _hPad(context), vertical: vPad),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textContent,
                const SizedBox(height: 48),
                phonePreview,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: textContent),
                const SizedBox(width: 60),
                Expanded(flex: 4, child: phonePreview),
              ],
            ),
    );
  }

  Widget _buildMockItem(String title, String sub, String badge, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder)
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13)),
                Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: mobile ? 48 : 80, horizontal: _hPad(context)),
      color: Colors.white,
      child: mobile
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.8,
              children: [
                _buildMetricItem('15k+', 'Diárias Validadas'),
                _buildMetricItem('500+', 'Locais Atendidos'),
                _buildMetricItem('98%', 'SLA de Presença'),
                _buildMetricItem('R\$ 2M+', 'Pagos em Diárias'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('15k+', 'Diárias Validadas'),
                _buildMetricItem('500+', 'Locais Atendidos'),
                _buildMetricItem('98%', 'SLA de Presença'),
                _buildMetricItem('R\$ 2M+', 'Pagos em Diárias'),
              ],
            ),
    );
  }

  Widget _buildMetricItem(String val, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(val, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    final mobile = isMobile(context);
    final tablet = isTablet(context);
    final titleSize = mobile ? 28.0 : (tablet ? 36.0 : 48.0);
    final vPad = mobile ? 60.0 : 120.0;

    final steps = [
      ['01', 'Cadastro Rápido', 'Crie seu perfil profissional e valide seus documentos em minutos.'],
      ['02', 'Seleção de Vagas', 'Encontre oportunidades por geolocalização próximas a você.'],
      ['03', 'Check-in Seguro', 'Registre sua presença com travas de GPS e foto em tempo real.'],
      ['04', 'Pagamento Garantido', 'Acompanhe seu extrato e receba suas diárias com segurança.'],
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _hPad(context), vertical: vPad),
      child: Column(
        children: [
          const Text('FLUXO INTELIGENTE', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
          const SizedBox(height: 14),
          Text('Sua jornada em 4 passos simples', style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 56),
          if (mobile)
            Column(
              children: steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStepCard(s[0], s[1], s[2]),
              )).toList(),
            )
          else if (tablet)
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: steps.map((s) => SizedBox(
                width: (MediaQuery.of(context).size.width - _hPad(context) * 2 - 24) / 2,
                child: _buildStepCard(s[0], s[1], s[2]),
              )).toList(),
            )
          else
            Row(
              children: steps.asMap().entries.map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < steps.length - 1 ? 24 : 0),
                  child: _buildStepCard(e.value[0], e.value[1], e.value[2]),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String num, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: TextStyle(color: AppColors.primaryBlue.withOpacity(0.2), fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _hPad(context), vertical: mobile ? 48 : 80),
      padding: EdgeInsets.all(mobile ? 40 : 80),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Pronto para otimizar sua operação?',
            style: TextStyle(color: Colors.white, fontSize: mobile ? 24 : 40, fontWeight: FontWeight.w900, letterSpacing: -1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Junte-se a milhares de profissionais que já utilizam o CheckFast.',
            style: TextStyle(color: Colors.white70, fontSize: mobile ? 15 : 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => AuthModals.showPromoterRegister(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: mobile ? 32 : 48, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0
            ),
            child: const Text('CRIAR MINHA CONTA AGORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          )
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: _hPad(context)),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text('CheckFast', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('© 2024 CheckFast Tecnologia Ltda.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  children: [
                    _buildFooterLink('Privacidade'),
                    _buildFooterLink('Termos'),
                    _buildFooterLink('Suporte'),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 22),
                        SizedBox(width: 8),
                        Text('CheckFast', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('© 2024 CheckFast Tecnologia Ltda.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    _buildFooterLink('Privacidade'),
                    const SizedBox(width: 28),
                    _buildFooterLink('Termos'),
                    const SizedBox(width: 28),
                    _buildFooterLink('Suporte'),
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildNavLink(String label) {
    return Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15));
  }

  Widget _buildFooterLink(String label) {
    return Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13));
  }
}
