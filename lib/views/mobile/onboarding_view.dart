import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import 'promoter_home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 0;
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const PremiumHeader(title: 'CheckFast', subtitle: 'CADASTRO DE PROMOTOR'),
              const SizedBox(height: 30),
              
              // Indicador de Progresso (5 Etapas)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Container(
                  width: 35, 
                  height: 4, 
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? AppColors.neonCyan : Colors.white10, 
                    borderRadius: BorderRadius.circular(2)
                  ),
                )),
              ),
              const SizedBox(height: 30),

              // Conteúdo Dinâmico
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),

              const SizedBox(height: 20),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep(
          Icons.person_pin_outlined, 
          'Identificação & Pagamento', 
          'Dados essenciais para sua contratação e recebimento de diárias.',
          Column(
            children: [
              _buildField('Nome Completo'),
              _buildField('CPF'),
              _buildField('Chave PIX (Deve ser seu CPF)'),
            ],
          ),
        );
      case 1:
        return _buildStep(
          Icons.home_outlined, 
          'Residência', 
          'Seu endereço define as vagas mais próximas de você.',
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildField('CEP')),
                  const SizedBox(width: 15),
                  Expanded(child: _buildField('Número')),
                ],
              ),
              _buildField('Rua / Avenida'),
              _buildField('Bairro'),
              _buildField('Cidade - UF'),
            ],
          ),
        );
      case 2:
        return _buildStep(
          Icons.lock_outline, 
          'Segurança da Conta', 
          'Crie suas credenciais de acesso ao app e painel web.',
          Column(
            children: [
              _buildField('E-mail (Seu Login)'),
              _buildField('Senha de Acesso', obscure: true),
              _buildField('Confirmar Senha', obscure: true),
            ],
          ),
        );
      case 3:
        return _buildStep(
          Icons.badge_outlined, 
          'Documentação & Selfie', 
          'Envie as fotos do seu documento para validação da conta.',
          Column(
            children: [
              _buildDocSlot('RG OU CNH (FRENTE)', true),
              const SizedBox(height: 15),
              _buildDocSlot('RG OU CNH (VERSO)', false),
              const SizedBox(height: 30),
              const Icon(Icons.face_unlock_outlined, color: AppColors.neonCyan, size: 50),
              const SizedBox(height: 10),
              const Text('Prepare-se para a Biometria Facial', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        );
      case 4:
        return _buildStep(
          Icons.gavel_outlined, 
          'Compliance e LGPD', 
          'Leia e aceite as regras de operação e proteção de dados.',
          _buildTermsStep(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTermsStep() {
    return Column(
      children: [
        Container(
          height: 200, 
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: const SingleChildScrollView(
            child: Text(
              'CONTRATO DE ADMISSÃO DIGITAL E POLÍTICA LGPD\n\n1. O colaborador declara que todas as informações prestadas são verdadeiras.\n2. Autorizo o CheckFast a coletar minha geolocalização durante a jornada para fins de auditoria.\n3. O pagamento da diária está condicionado ao mínimo de 4h de permanência em loja.\n4. Comprometo-me a não divulgar dados sensíveis dos clientes atendidos.\n5. Aceito os termos de compliance e conduta ética do CheckFast.',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.6)
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms, 
              activeColor: AppColors.neonCyan, 
              side: const BorderSide(color: Colors.white38),
              onChanged: (v) => setState(() => _acceptedTerms = v!)
            ),
            const Expanded(child: Text('Li e concordo com todos os termos e regras citados acima.', style: TextStyle(color: Colors.white, fontSize: 11))),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => setState(() => _currentStep--), 
            child: const Text('ANTERIOR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))
          )
        else
          const SizedBox(),
        
        ElevatedButton(
          onPressed: () => setState(() => _currentStep < 4 ? _currentStep++ : _finishRegistration()), 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: Text(_currentStep == 4 ? 'ENTRAR NO APP' : 'PRÓXIMO', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }

  void _finishRegistration() {
    if (_acceptedTerms) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const PromoterHomeView())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa aceitar os termos para prosseguir.'))
      );
    }
  }

  Widget _buildStep(IconData i, String t, String s, Widget c) => Column(
    children: [
      Icon(i, color: AppColors.neonCyan, size: 35),
      const SizedBox(height: 15),
      Text(t, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text(s, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 35),
      c,
    ],
  );

  Widget _buildField(String l, {bool obscure = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12), 
    child: TextField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: l, 
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12), 
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)), 
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan))
      )
    )
  );

  Widget _buildDocSlot(String l, bool d) => Container(
    padding: const EdgeInsets.all(20), 
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
    child: Row(
      children: [
        Icon(d ? Icons.check_circle : Icons.camera_alt, color: d ? AppColors.success : AppColors.neonCyan, size: 20),
        const SizedBox(width: 15),
        Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const Spacer(),
        if (d) const Icon(Icons.verified, color: AppColors.success, size: 16),
      ],
    ),
  );
}
