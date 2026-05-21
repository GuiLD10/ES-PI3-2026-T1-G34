// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Gerenciador de sessão do usuário autenticado

/// Armazena os dados da sessão do usuário logado (uid e token)
/// retornados pela Firebase Function de login.
class SessionManager {
  SessionManager._();

  static String? _uid;
  static String? _token;

  /// Salva os dados da sessão após login bem-sucedido.
  static void salvarSessao({required String uid, required String token}) {
    _uid = uid;
    _token = token;
  }

  /// Retorna o UID do usuário logado, ou null se não estiver autenticado.
  static String? get uid => _uid;

  /// Retorna o token do usuário logado, ou null se não estiver autenticado.
  static String? get token => _token;

  /// Verifica se o usuário está autenticado.
  static bool get estaAutenticado => _uid != null && _uid!.isNotEmpty;

  /// Limpa os dados da sessão (logout).
  static void limparSessao() {
    _uid = null;
    _token = null;
  }
}
