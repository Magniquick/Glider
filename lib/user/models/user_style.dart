enum UserStyle({
  final bool showPrimary = false,
  final bool showSecondary = false,
}) {
  full(showPrimary: true, showSecondary: true),
  primary(showPrimary: true),
  secondary(showSecondary: true);
}
