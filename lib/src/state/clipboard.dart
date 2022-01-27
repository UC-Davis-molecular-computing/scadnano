import 'dart:html';

import 'package:platform_detect/platform_detect.dart';

abstract class Clipboard {
  write(String input);

  Future<String> read();
}

class BrowserClipboard implements Clipboard {
  write(String input) {
    window.navigator.clipboard.writeText(input);
  }

  Future<String> read() async {
    try {
      String text = await window.navigator.clipboard.readText();
      return text;
    } on NoSuchMethodError {
      if (browser.isFirefox) {
        var msg = """\
It looks like you are using Firefox and want to paste from the clipboard.
Unfortunately you need to make a change to permissions before that will be possible.
  1. Open a new tab and enter about:config in the address bar.
  2. Click "Accept the Risk and Continue".
  3. Search dom.events.testing.asyncClipboard and set it to true.
  4. Refresh the scadnano tab. 
Then you will be able to paste from the clipboard.
""";
        window.alert(msg);
      } else {
        var msg = "Unable to paste; unknown reason.";
        window.alert(msg);
      }
      return '';
    } catch (e) {
      var msg = 'error: ${e}';
      window.alert('Unable to paste. Reason:\n${msg}');
      return '';
    }
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
