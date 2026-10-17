/// Seleciona a estratégia de URL conforme a plataforma de compilação.
///
/// A skill oficial do Flutter recomenda `usePathUrlStrategy()` para tirar o
/// `#` das URLs — necessário para deep link limpo. Mas
/// `package:flutter_web_plugins` só existe na web, e este projeto também
/// compila para macOS. O export condicional resolve: na web carrega a
/// implementação real, fora dela um no-op.
///
/// Atenção no deploy: com path strategy o servidor precisa reescrever
/// qualquer caminho desconhecido para `index.html`, senão um F5 em
/// `/governadores` devolve 404. `flutter run -d chrome` já faz isso sozinho.
library;

export 'url_strategy_noop.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
