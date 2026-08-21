enum ItemStyle({
  final bool showPrimary = false,
  final bool showSecondary = false,
  final bool showUrlHost = false,
}) {
  full(showPrimary: true, showSecondary: true),
  overview(showPrimary: true, showUrlHost: true),
  primary(showPrimary: true),
  secondary(showSecondary: true);
}
