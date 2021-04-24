import 'dart:html';

abstract class Clipboard {
  write(String input);

  Future<String> read();
}

class BrowserClipboard implements Clipboard {
  write(String input) {
    window.navigator.clipboard.writeText(input);
  }

  Future<String> read() async {
    String content = await window.navigator.clipboard.readText();
    return content;
  }
}


class CLIClipboard implements Clipboard {
  String content = '';

  @override
  write(String input) {
    content = input;
  }

  @override
  Future<String> read() async {
    return content;
  }
}
