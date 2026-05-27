import 'package:flutter/material.dart';

/// Breakpoints padrão do CheckFast
/// Mobile  : largura < 600
/// Tablet  : 600 ≤ largura < 1024
/// Desktop : largura ≥ 1024
class Responsive {
  static const double _mobileBreak = 600;
  static const double _tabletBreak = 1024;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) => width(context) < _mobileBreak;
  static bool isTablet(BuildContext context) =>
      width(context) >= _mobileBreak && width(context) < _tabletBreak;
  static bool isDesktop(BuildContext context) => width(context) >= _tabletBreak;

  /// Retorna o valor correto de acordo com o breakpoint atual.
  /// [mobile] é obrigatório. [tablet] e [desktop] têm fallback para o anterior.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Padding horizontal adaptativo (lateral das telas)
  static double hPad(BuildContext context) =>
      value(context, mobile: 20.0, tablet: 36.0, desktop: 48.0);

  /// Padding vertical adaptativo para seções
  static double vPad(BuildContext context) =>
      value(context, mobile: 24.0, tablet: 36.0, desktop: 48.0);

  /// Espaçamento entre seções
  static double sectionGap(BuildContext context) =>
      value(context, mobile: 24.0, tablet: 32.0, desktop: 40.0);

  /// Tamanho de título principal (h1)
  static double titleSize(BuildContext context) =>
      value(context, mobile: 22.0, tablet: 28.0, desktop: 32.0);

  /// Tamanho de subtítulo
  static double subtitleSize(BuildContext context) =>
      value(context, mobile: 13.0, tablet: 14.0, desktop: 16.0);

  /// Largura máxima dos modais/dialogs (ocupa tela inteira em mobile)
  static double dialogWidth(BuildContext context, {double maxWidth = 480}) {
    final w = width(context);
    return w < maxWidth + 48 ? double.infinity : maxWidth;
  }

  /// Padding interno dos dialogs
  static EdgeInsets dialogPadding(BuildContext context) => EdgeInsets.all(
        value(context, mobile: 24.0, tablet: 36.0, desktop: 48.0),
      );

  /// Grid cross-axis count adaptativo
  static int gridCount(BuildContext context,
          {int mobile = 2, int tablet = 3, int desktop = 4}) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Empilha [children] horizontalmente no tablet/desktop e verticalmente no
  /// mobile, com espaçamento [gap].
  static Widget row({
    required BuildContext context,
    required List<Widget> children,
    double gap = 16,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    if (isMobile(context)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: _interleave(
          children,
          SizedBox(height: gap),
        ),
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: _interleave(
        children.map((c) => Expanded(child: c)).toList(),
        SizedBox(width: gap),
      ),
    );
  }

  static List<Widget> _interleave(List<Widget> items, Widget separator) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(separator);
    }
    return result;
  }
}
