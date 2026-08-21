enum ItemStyle({
  this.showPrimary = false,
  this.showSecondary = false,
  this.showUrlHost = false,
}) {
  full(showPrimary: true, showSecondary: true),
  overview(showPrimary: true, showUrlHost: true),
  primary(showPrimary: true),
  secondary(showSecondary: true);

  final bool showPrimary;
  final bool showSecondary;
  final bool showUrlHost;
}
