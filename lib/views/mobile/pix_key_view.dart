import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PixKeyView extends StatefulWidget {
  const PixKeyView({super.key});

  @override
  State<PixKeyView> createState() => _PixKeyViewState();
}

class _PixKeyViewState extends State<PixKeyView> {
  String _selectedType = 'CPF';
  final _keyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _userCpf = '';
  Map<String, dynamic> _cvDados = {};

  @override
  void initState() {
    super.initState();
    _loadPixKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadPixKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userCpf = prefs.getString('user_cpf') ?? '';
      final cleanCPF = _userCpf.replaceAll(RegExp(r'\D'), '');

      if (cleanCPF.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanCPF).get();

      if (doc.exists) {
        final docData = doc.data() as Map<String, dynamic>;
        String pixKey = docData['pixKey']?.toString() ?? '';
        
        if (docData['curriculum_completo_dados'] != null) {
          try {
            _cvDados = jsonDecode(docData['curriculum_completo_dados'].toString());
            final docs = _cvDados['documentacao'] ?? {};
            if (pixKey.isEmpty) {
              pixKey = docs['chave_pix'] ?? '';
            }
          } catch (e) {
            print('Erro ao parsear dados do currículo: $e');
          }
        }

        _keyController.text = pixKey;
        
        // Detectar o tipo de chave pix baseando-se no formato
        if (pixKey.isNotEmpty) {
          if (pixKey.contains('@')) {
            _selectedType = 'E-mail';
          } else if (RegExp(r'^[a-zA-Z0-9-]{32,36}$').hasMatch(pixKey.trim())) {
            _selectedType = 'Chave Aleatória';
          } else {
            final digits = pixKey.replaceAll(RegExp(r'\D'), '');
            if (digits.length == 11) {
              if (pixKey.contains('.') || pixKey.contains('-')) {
                _selectedType = 'CPF';
              } else {
                _selectedType = 'CPF';
              }
            } else if (digits.length == 10 || digits.length == 11) {
              _selectedType = 'Celular';
            } else {
              _selectedType = 'CPF';
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar chave pix: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePixKey() async {
    final cleanCPF = _userCpf.replaceAll(RegExp(r'\D'), '');
    if (cleanCPF.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: CPF não identificado.'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    final newPixKey = _keyController.text.trim();
    if (newPixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a chave PIX.'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Sincronizar no JSON de dados completos do currículo
      final documentacao = Map<String, dynamic>.from(_cvDados['documentacao'] ?? {});
      documentacao['chave_pix'] = newPixKey;
      _cvDados['documentacao'] = documentacao;

      final cvDadosString = jsonEncode(_cvDados);

      // Envia via SDK do Firestore (evita quota REST e problemas de permissão/token)
      await FirebaseFirestore.instance.collection('users').doc(cleanCPF).update({
        'pixKey': newPixKey,
        'curriculum_completo_dados': cvDadosString,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chave PIX atualizada com sucesso!'), backgroundColor: AppColors.success)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erro ao salvar chave pix: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar chave PIX: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configurar Chave PIX', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seus pagamentos serão enviados para esta chave com segurança.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),
                  
                  const Text('TIPO DE CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        icon: const Icon(IconsaxPlusLinear.arrow_down_1, color: AppColors.primaryBlue),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        onChanged: _isSaving ? null : (val) => setState(() => _selectedType = val!),
                        items: ['CPF', 'E-mail', 'Celular', 'Chave Aleatória'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('VALOR DA CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TextField(
                      controller: _keyController,
                      enabled: !_isSaving,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(IconsaxPlusLinear.card_receive, color: AppColors.primaryBlue, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(18),
                        hintText: 'Digite sua chave pix...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePixKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.all(22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
