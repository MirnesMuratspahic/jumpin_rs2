import 'package:jumpin_admin/models/ad.dart';
import 'package:jumpin_admin/providers/base_provider.dart';

class AdProvider extends BaseProvider<Ad> {
  AdProvider() : super("Ad");

  @override
  Ad fromJson(data) {
    return Ad.fromJson(data);
  }
}
