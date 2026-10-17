import 'package:flutter_web_plugins/url_strategy.dart';

/// Implementação web: remove o `#` das URLs.
void configureUrlStrategy() => usePathUrlStrategy();
