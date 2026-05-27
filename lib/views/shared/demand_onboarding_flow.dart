import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../models/app_models.dart';

class DemandOnboardingFlow {
  static Future<bool?> show(BuildContext context, {required AppDemand demand, required String userCpf}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OnboardingDialog(demand: demand, userCpf: userCpf),
    );
  }
}

class _OnboardingDialog extends StatefulWidget {
  final AppDemand demand;
  final String userCpf;
  const _OnboardingDialog({required this.demand, required this.userCpf});

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  String _promoterName = 'Promotor';
  Map<String, dynamic> _curriculumData = {};
  bool _loadingCurriculum = true;
  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final projectId = widget.demand.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        final projectSnap = await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .get();
        if (projectSnap.exists) {
          final qId = projectSnap.data()?['questionnaireId'] as String?;
          if (qId != null && qId.isNotEmpty) {
            final qSnap = await FirebaseFirestore.instance
                .collection('questionnaires')
                .doc(qId)
                .get();
            if (qSnap.exists) {
              _questions = qSnap.data()?['questions'] as List? ?? [];
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar questionario do projeto: $e');
    }
    if (_questions.isEmpty) {
      _questions = widget.demand.questionnaire.isNotEmpty
          ? widget.demand.questionnaire
          : AppDemand.defaultQuestionnaire;
    }
    await _fetchCurriculum();
  }

  Future<void> _fetchCurriculum() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userCpf).get();
      if (doc.exists) {
        final docData = doc.data() as Map<String, dynamic>;
        if (docData['name'] != null) {
          _promoterName = docData['name']?.toString() ?? 'Promotor';
        }
        if (docData['curriculum_completo_dados'] != null) {
          final String cvJson = docData['curriculum_completo_dados']?.toString() ?? '{}';
          setState(() {
            _curriculumData = jsonDecode(cvJson);
            _loadingCurriculum = false;
          });
          _prefillFromCurriculum();
          return;
        }
      }
    } catch (e) {
      print('Erro ao carregar currículo no onboarding: $e');
    }
    setState(() {
      _loadingCurriculum = false;
    });
  }

  void _prefillFromCurriculum() {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final mapping = q['curriculumMapping']?.toString() ?? 'Nenhum';
      if (mapping != 'Nenhum' && mapping.contains('/')) {
        final parts = mapping.split('/');
        final section = parts[0];
        final key = parts[1];
        
        dynamic rawVal;
        if (section == 'trade_flags') {
          final tradeFlags = _curriculumData['trade_flags'] ?? {};
          rawVal = tradeFlags[key];
        } else {
          final secData = _curriculumData[section] ?? {};
          rawVal = secData[key];
        }

        if (rawVal != null) {
          String mappedString = '';
          if (rawVal is bool) {
            mappedString = rawVal ? 'Sim' : 'Não';
          } else {
            mappedString = rawVal.toString();
          }
          
          final qType = q['questionType']?.toString() ?? 'Opções';
          if (qType == 'Texto' || qType == 'Pergunta e resposta') {
            setState(() {
              _answers[i] = mappedString;
              if (!_textControllers.containsKey(i)) {
                _textControllers[i] = TextEditingController(text: mappedString);
              } else {
                _textControllers[i]!.text = mappedString;
              }
            });
          } else if (qType == 'Sim/Não') {
            setState(() {
              _answers[i] = mappedString;
            });
          } else {
            final optionsList = q['options'] as List? ?? [];
            for (var opt in optionsList) {
              final optText = opt['text']?.toString() ?? '';
              if (optText.toLowerCase() == mappedString.toLowerCase()) {
                setState(() {
                  _answers[i] = optText;
                });
                break;
              }
            }
          }
        }
      }
    }
  }

  void _updateCurriculumData(int questionIndex, String selectedValue) {
    final q = _questions[questionIndex];
    final mapping = q['curriculumMapping']?.toString() ?? 'Nenhum';
    if (mapping != 'Nenhum' && mapping.contains('/')) {
      final parts = mapping.split('/');
      final section = parts[0];
      final key = parts[1];
      
      dynamic finalVal;
      if (selectedValue.toLowerCase() == 'sim') {
        finalVal = true;
      } else if (selectedValue.toLowerCase() == 'não') {
        finalVal = false;
      } else {
        finalVal = selectedValue;
      }

      if (section == 'trade_flags') {
        if (_curriculumData['trade_flags'] == null) {
          _curriculumData['trade_flags'] = <String, dynamic>{};
        }
        _curriculumData['trade_flags'][key] = finalVal;
      } else {
        if (_curriculumData[section] == null) {
          _curriculumData[section] = <String, dynamic>{};
        }
        _curriculumData[section][key] = finalVal;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 60, offset: const Offset(0, 24)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Flexible(
              child: _loadingCurriculum 
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildQuestionnaire(),
                    ),
            ),
            
            // Footer (Botões)
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.demand.storeName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Questionário de Habilitação para a Vaga', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionnaire() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text('Nenhuma pergunta cadastrada para esta vaga.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Questionário de Perfil', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Por favor, responda às perguntas abaixo exigidas pelo contratante para esta vaga específica.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        ...List.generate(_questions.length, (index) {
          final q = _questions[index];
          final qText = q['questionText']?.toString() ?? '';
          final section = q['sectionTitle']?.toString() ?? '';
          final mapping = q['curriculumMapping']?.toString() ?? 'Nenhum';
          
          final questionType = q['questionType']?.toString() ?? 'Opções';
          final responseType = q['responseType']?.toString() ?? 'Texto';
          final options = (q['options'] as List? ?? []).map((o) => o['text']?.toString() ?? '').toList();

          final hasPrefill = mapping != 'Nenhum';
          final currentVal = _answers[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.isNotEmpty) ...[
                  Text(section.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(qText, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    if (hasPrefill && currentVal != null && currentVal.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 12),
                            SizedBox(width: 4),
                            Text('Currículo', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuestionInputWidget(index, questionType, responseType, options, currentVal),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionInputWidget(int index, String questionType, String responseType, List<String> options, String? currentValue) {
    if (questionType == 'Opções') {
      return _buildQuestionDropdown(index, options, currentValue);
    } else if (questionType == 'Sim/Não') {
      return _buildQuestionDropdown(index, const ['Sim', 'Não'], currentValue);
    } else if (questionType == 'Múltiplas opções escolha') {
      return _buildMultipleChoiceCheckboxes(index, options, currentValue);
    } else if (questionType == 'Texto') {
      return _buildQuestionTextField(index);
    } else if (questionType == 'Pergunta e resposta') {
      if (responseType == 'Inteiro') {
        return _buildQuestionTextField(index, keyboardType: TextInputType.number);
      } else if (responseType == 'Decimal') {
        return _buildQuestionTextField(index, keyboardType: const TextInputType.numberWithOptions(decimal: true));
      } else if (responseType == 'Moeda') {
        return _buildQuestionTextField(index, keyboardType: TextInputType.number, prefixText: 'R\$ ');
      } else if (responseType == 'Data') {
        return _buildDatePicker(index, currentValue);
      } else if (responseType == 'Hora') {
        return _buildTimePicker(index, currentValue);
      } else {
        return _buildQuestionTextField(index);
      }
    }
    return _buildQuestionDropdown(index, options, currentValue);
  }

  Widget _buildQuestionDropdown(int questionIndex, List<String> options, String? currentValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentValue != null && options.contains(currentValue)) ? currentValue : null,
          hint: const Text('Selecione uma resposta...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _answers[questionIndex] = val;
              });
              _updateCurriculumData(questionIndex, val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceCheckboxes(int questionIndex, List<String> options, String? currentValue) {
    final selectedList = (currentValue != null && currentValue.isNotEmpty)
        ? currentValue.split(', ').toList()
        : <String>[];
    return Column(
      children: options.map((opt) {
        final isSelected = selectedList.contains(opt);
        return CheckboxListTile(
          title: Text(opt, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          value: isSelected,
          activeColor: AppColors.primaryBlue,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                if (!selectedList.contains(opt)) selectedList.add(opt);
              } else {
                selectedList.remove(opt);
              }
              final joined = selectedList.join(', ');
              _answers[questionIndex] = joined;
              _updateCurriculumData(questionIndex, joined);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuestionTextField(int questionIndex, {TextInputType? keyboardType, String? prefixText}) {
    if (!_textControllers.containsKey(questionIndex)) {
      _textControllers[questionIndex] = TextEditingController(text: _answers[questionIndex] ?? '');
    }
    final controller = _textControllers[questionIndex]!;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixText: prefixText,
        hintText: 'Digite sua resposta aqui...',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
      ),
      onChanged: (val) {
        _answers[questionIndex] = val;
        _updateCurriculumData(questionIndex, val);
      },
    );
  }

  Widget _buildDatePicker(int questionIndex, String? currentValue) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          setState(() {
            _answers[questionIndex] = formatted;
          });
          _updateCurriculumData(questionIndex, formatted);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(currentValue ?? 'Selecione uma data...', style: TextStyle(color: currentValue != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
            const Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(int questionIndex, String? currentValue) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
          setState(() {
            _answers[questionIndex] = formatted;
          });
          _updateCurriculumData(questionIndex, formatted);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(currentValue ?? 'Selecione um horário...', style: TextStyle(color: currentValue != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
            const Icon(Icons.access_time_filled, color: AppColors.primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final allAnswered = _answers.length == _questions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Desistir', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: allAnswered ? _submitAndSaveCurriculum : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: AppColors.cardBorder,
            ),
            child: const Text('ENVIAR FORMULÁRIO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAndSaveCurriculum() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      // 1. Salvar currículo atualizado via SDK
      await FirebaseFirestore.instance.collection('users').doc(widget.userCpf).update({
        'curriculum_completo_dados': jsonEncode(_curriculumData),
      });

      // 2. Salvar inscrição na coleção 'applications' com status tarefa_aprovada via SDK
      final answersMap = <String, dynamic>{};
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        answersMap['q$i'] = {
          'question': q['questionText']?.toString() ?? '',
          'answer': _answers[i] ?? '',
        };
      }

      final now = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance.collection('applications').add({
        'promoterCpf': widget.userCpf,
        'demandId': widget.demand.id,
        'storeName': widget.demand.storeName,
        'network': widget.demand.network,
        'address': widget.demand.address,
        'role': widget.demand.role,
        'date': widget.demand.date,
        'timeRange': widget.demand.timeRange,
        'value': widget.demand.value,
        'status': 'tarefa_aprovada',
        'submittedAt': now,
        'updatedAt': now,
        'latitude': widget.demand.latitude ?? -23.5275,
        'longitude': widget.demand.longitude ?? -46.6853,
        'questionnaireAnswers': jsonEncode(answersMap),
      });

      // 3. Atualizar a demanda no Firestore (incrementando filledVagas e definindo assignedPromoter) via SDK
      final newFilled = widget.demand.filledVagas + 1;
      final newStatus = newFilled >= widget.demand.totalVagas ? 'PREENCHIDAS' : widget.demand.status;

      await FirebaseFirestore.instance.collection('demands').doc(widget.demand.id).update({
        'filledVagas': newFilled,
        'assignedPromoter': _promoterName,
        'status': newStatus,
      });

    } catch (e) {
      print('Erro ao salvar inscrição e atualizar demanda: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir inscrição: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }

    if (mounted) {
      Navigator.pop(context); // fecha loading
      Navigator.pop(context, true); // fecha onboarding modal com valor true
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sua inscrição para esta demanda foi confirmada e vinculada com sucesso! Você já pode realizar o check-in na aba "Tarefas" quando estiver no local.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
