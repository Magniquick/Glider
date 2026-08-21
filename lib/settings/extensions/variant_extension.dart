import 'package:intl/intl.dart' as intl;
import 'package:material_color_utilities/dynamiccolor/variant.dart';

extension VariantExtension on Variant {
  String get capitalizedLabel => intl.toBeginningOfSentenceCase(label)!;
}
