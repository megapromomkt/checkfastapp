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
          width: 380,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(IconsaxPlusLinear.search_normal, size: 20, color: AppColors.textSecondary),
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(IconsaxPlusLinear.add, color: AppColors.primaryBlue, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (context, index) => const Divider(color: AppColors.cardBorder, height: 1, indent: 24, endIndent: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedItem == item;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListTile(
                        onTap: () => onSelect(item),
                        selected: isSelected,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        selectedTileColor: AppColors.primaryBlue.withOpacity(0.06),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(itemTitle(item), style: TextStyle(
                          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary, 
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                          fontSize: 14
                        )),
                        subtitle: itemSubtitle != null ? Text(itemSubtitle!(item), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onDelete(item),
                              icon: const Icon(IconsaxPlusLinear.trash, size: 18, color: AppColors.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // LADO DIREITO: DETALHE
        Expanded(
          child: selectedItem == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.document_text, size: 80, color: AppColors.textSecondary.withOpacity(0.1)),
                      const SizedBox(height: 24),
                      const Text('Selecione um item da lista para visualizar os detalhes', 
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : detailsBuilder(selectedItem!),
        ),
      ],
    );
  }
}
