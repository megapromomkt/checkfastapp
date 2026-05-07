import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/constants/premium_theme.dart';

class RegistersListDetailLayout<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemTitle;
  final String Function(T)? itemSubtitle;
  final Function(T) onSelect;
  final VoidCallback onAdd;
  final Function(T) onDelete;
  final Widget Function(T) detailsBuilder;
  final String searchHint;

  const RegistersListDetailLayout({
    super.key,
    required this.items,
    this.selectedItem,
    required this.itemTitle,
    this.itemSubtitle,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.detailsBuilder,
    this.searchHint = 'Buscar...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LADO ESQUERDO: LISTA
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.glassBorderDark),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(IconsaxPlusLinear.search_normal, size: 18, color: AppColors.textSecondary),
                          fillColor: Colors.white.withOpacity(0.05),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(IconsaxPlusLinear.add_square, color: AppColors.neonCyan),
                      style: IconButton.styleFrom(backgroundColor: AppColors.neonCyan.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedItem == item;
                    return ListTile(
                      onTap: () => onSelect(item),
                      selected: isSelected,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(itemTitle(item), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: itemSubtitle != null ? Text(itemSubtitle!(item), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => onDelete(item),
                            icon: const Icon(IconsaxPlusLinear.trash, size: 16, color: Colors.redAccent),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),
        // LADO DIREITO: DETALHE
        Expanded(
          child: selectedItem == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.document_text, size: 64, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 20),
                      const Text('Selecione ou crie um item para ver os detalhes.', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : detailsBuilder(selectedItem!),
        ),
      ],
    );
  }
}
