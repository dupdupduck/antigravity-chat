/// ANSI color codes and styles for rich terminal presentation.
class TerminalStyle {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  // Colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Bright colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  // Background colors
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';

  static String colorize(String text, String color) => '$color$text$reset';

  static String primary(String text) => '$brightCyan$bold$text$reset';
  static String secondary(String text) => '$brightMagenta$text$reset';
  static String success(String text) => '$brightGreen$text$reset';
  static String warning(String text) => '$brightYellow$text$reset';
  static String error(String text) => '$brightRed$bold$text$reset';
  static String mute(String text) => '$brightBlack$text$reset';
  static String highlight(String text) => '$bold$brightWhite$text$reset';
  static String bot(String text) => '$brightMagenta$bold$text$reset';

  static String userColor(String username) {
    final colors = [
      brightCyan,
      brightGreen,
      brightYellow,
      brightMagenta,
      brightBlue,
      cyan,
      green,
      yellow,
    ];
    final hash = username.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    final color = colors[hash % colors.length];
    return '$color$bold$username$reset';
  }

  static String banner() {
    return '''
$brightCyan$bold   ___          __   _                         _  __           
  / _ | ___  __/ /_ (_)__  ________ __  _____   / |/ /__ ___ __  
 / __ |/ _ \\/ _  // // _ \\/ __/ _ `/| |/ / -_) /    / -_) _ `/  
/_/ |_/_//_/\\_,_//_/ \\_, /_/  \\_,_/ |___/\\__/ /_/|_/\\__/\\_,_/   
                    /___/                                        $reset
$brightMagenta    ⚡ Terminal Messaging Network & AI Agent ⚡$reset
$brightBlack    ------------------------------------------------------$reset
''';
  }
}
