import 'package:glider_data/glider_data.dart';

class const WebsiteRepository(this._genericWebsiteService) {
  final GenericWebsiteService _genericWebsiteService;

  Future<String?> getWebsiteTitle(Uri url) async =>
      _genericWebsiteService.getTitle(url);
}
