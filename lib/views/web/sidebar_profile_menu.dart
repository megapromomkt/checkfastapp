import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class SidebarProfileMenu extends StatefulWidget {
  final String userName;
  final String userRole;

  const SidebarProfileMenu({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<SidebarProfileMenu> createState() => _SidebarProfileMenuState();
}

class _SidebarProfileMenuState extends State<SidebarProfileMenu> {
  void _showProfileSubmenu(BuildContext context) {
    // Usamos o showPositioned ou um PopupMenuButton para simular o submenu no canto inferior
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
      items: [
        const PopupMenuItem(
          value: 'password',
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18),
              SizedBox(width: 10),
              Text('Trocar Senha'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(Icons.palette_outlined, size: 18),
              SizedBox(width: 10),
              Text('Alterar Cor do Sistema'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Sair', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'logout') {
        // Lógica de logout
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.userName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return InkWell(
      onTap: () => _showProfileSubmenu(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            // Círculo com Iniciais
            CircleAvatar(
              backgroundColor: AppColors.electricBlue,
              radius: 20,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            // Nome e Perfil de Acesso
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.userRole,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
