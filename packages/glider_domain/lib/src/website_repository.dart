import 'package:glider_data/glider_data.dart';

class const WebsiteRepository(
  final GenericWebsiteService _genericWebsiteService,
) {
  Future<String?> getWebsiteTitle(Uri url) =>
      _genericWebsiteService.getTitle(url);
}
