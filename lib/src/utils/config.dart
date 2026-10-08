import 'dart:io';

/// Application configuration and paths.
class AppConfig {
  static const int defaultPort = 4040;
  static const String defaultHost = '127.0.0.1';
  static const String defaultRoom = '#general';
  static const String appName = 'antigravity-chat';
  static const String appVersion = '1.0.0';

  static Directory get appDataDir {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dir = Directory('$home/.antigravity_chat');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  static File get pidFile => File('${appDataDir.path}/server.pid');
  static File get historyFile => File('${appDataDir.path}/history.jsonl');
  static File get serverLogFile => File('${appDataDir.path}/server.log');

  static String getDefaultUsername() {
    final envUser =
        Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        'User_${DateTime.now().millisecondsSinceEpoch % 1000}';
    return envUser;
  }
}
