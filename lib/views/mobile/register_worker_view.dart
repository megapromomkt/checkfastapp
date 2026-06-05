import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class RegisterWorkerView extends StatefulWidget {
  const RegisterWorkerView({super.key});

  @override
  State<RegisterWorkerView> createState() => _RegisterWorkerViewState();
}

class _RegisterWorkerViewState extends State<RegisterWorkerView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Colaborador', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto do Perfil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.neutralGray.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 50, color: AppColors.neutralGray),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: AppColors.white, size: 20),
                          onPressed: () {
                            // Lógica para capturar foto
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Campos Pessoais
              Text('Dados Pessoais', style: AppTextStyles.subtitle),
              const SizedBox(height: 10),
              _buildTextField('Nome Completo', Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField('CPF', Icons.badge_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField('Telefone (WhatsApp) *', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              _buildTextField('E-mail', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField('Endereço Completo', Icons.location_on_outlined),
              
              const SizedBox(height: 30),

              // Experiência e Disponibilidade
              Text('Perfil Profissional', style: AppTextStyles.subtitle),
              const SizedBox(height: 10),
              _buildTextField('Função / Experiência (Ex: Promotor)', Icons.work_outline),
              const SizedBox(height: 15),
              _buildTextField('Disponibilidade (Ex: Seg a Sex, Finais de Semana)', Icons.calendar_today_outlined),

              const SizedBox(height: 30),

              // Financeiro
              Text('Dados para Pagamento', style: AppTextStyles.subtitle),
              const SizedBox(height: 10),
              _buildTextField('Chave PIX', Icons.pix, color: AppColors.successGreen),

              const SizedBox(height: 40),

              // Botão Enviar
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Salvar no Firestore e alterar status para 'Em análise'
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('ENVIAR PARA ANÁLISE', style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {TextInputType? keyboardType, Color? color}) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color ?? AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.neutralGray.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }
}
