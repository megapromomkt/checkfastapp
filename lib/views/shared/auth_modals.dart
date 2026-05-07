import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class AuthModals {
  static void showPromoterLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(40),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Acesso do Promotor', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Bem-vindo de volta! Faça login para ver oportunidades.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 30),
              
              const Text('E-mail ou CPF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.spaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('Senha', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.spaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/promoter');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('ENTRAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showPromoterRegister(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.neonCyan.withOpacity(0.5)),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('CRIAR CADASTRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showForgotPassword(context);
                  }, 
                  child: const Text('Esqueci minha senha', style: TextStyle(color: AppColors.textSecondary))
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  static void showPromoterRegister(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(40),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cadastro de Promotor', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Preencha as 4 etapas para liberar seu acesso às diárias.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 30),
                
                // Etapa 1 Simulada
                const Text('1. Dados Pessoais', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildInputField('Nome Completo'),
                _buildInputField('CPF'),
                _buildInputField('E-mail'),
                _buildInputField('Celular (WhatsApp)'),
                _buildInputField('Senha', obscureText: true),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cadastro enviado com sucesso! Agora você pode acessar sua conta.'), backgroundColor: AppColors.successEmerald)
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text('FINALIZAR CADASTRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  static void showForgotPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(40),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Redefinir Senha', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Informe seu e-mail cadastrado para receber o link de redefinição.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 30),
              
              _buildInputField('E-mail'),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enviamos um link para seu e-mail. Verifique sua caixa de entrada.'), backgroundColor: AppColors.neonCyan)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('ENVIAR LINK DE REDEFINIÇÃO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  static Widget _buildInputField(String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.spaceBlack,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
