enum UserStyle({this.showPrimary = false, this.showSecondary = false}) {
  full(showPrimary: true, showSecondary: true),
  primary(showPrimary: true),
  secondary(showSecondary: true);

  final bool showPrimary;
  final bool showSecondary;
}
