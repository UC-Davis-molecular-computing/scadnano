import 'package:w_flux/w_flux.dart';
import '../rate_limit.dart';

class ThrottledStore extends Store {

  ThrottledStore() : super.withTransformer(new Throttler<Store>(const Duration(milliseconds: 30)));
}