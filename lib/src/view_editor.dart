import 'dart:async';
import 'dart:html';

import 'package:codemirror/codemirror.dart';
import 'package:codemirror/hints.dart';
import 'package:scadnano/src/actions.dart';

import 'app.dart';

class EditorViewComponent {

  CodeMirror editor;

  EditorViewComponent() {
    var editor_div_element = querySelector('#editor');

    Map options = {
      'theme': 'mbo',
      'continueComments': {'continueLineComment': false},
      'autoCloseTags': true,
      'mode': 'python',
      'lineNumbers': true,
      'extraKeys': {'Ctrl-Space': 'autocomplete', 'Cmd-/': 'toggleComment', 'Ctrl-/': 'toggleComment'}
    };


    this.editor = CodeMirror.fromElement(editor_div_element, options: options);

    Hints.registerHintsHelper('dart', _dartCompleter);
    Hints.registerHintsHelperAsync('dart', _dartCompleterAsync);

    // Theme control.
    SelectElement themeSelect = querySelector('#theme');
    for (String theme in CodeMirror.THEMES) {
      themeSelect.children.add(OptionElement(value: theme)..text = theme);
      if (theme == editor.getTheme()) {
        themeSelect.selectedIndex = themeSelect.length - 1;
      }
    }
    themeSelect.onChange.listen((e) {
      String themeName = themeSelect.options[themeSelect.selectedIndex].value;
      editor.setTheme(themeName);
    });

    // Status line.
    _updateFooter(editor);
    editor.onCursorActivity.listen((_) => _updateFooter(editor));

    editor.refresh();
    editor.focus();

    CodeMirror.addCommand('find', (foo) {
      /*LineHandle handle =*/ editor.getDoc().getLineHandle(editor.getCursor().line);

      print('todo: handle find');
    });

    editor.onDoubleClick.listen((MouseEvent evt) {
      Doc doc = editor.getDoc();
      print('[${doc.getLine(doc.getCursor().line).trim()}]');
    });

    editor.getDoc().setValue(app.model.editor_content);
  }

  render() {

  }

  void _updateFooter(CodeMirror editor) {
    Position pos = editor.getCursor();
    int off = editor.getDoc().indexFromPos(pos);
    String str = 'line ${pos.line} • column ${pos.ch} • offset ${off}' +
        (editor.getDoc().isClean() ? '' : ' • (modified)');
    querySelector('#footer').text = str;
  }

  HintResults _dartCompleter(CodeMirror editor, [HintsOptions options]) {
    Position cur = editor.getCursor();
    String word = _getCurrentWord(editor).toLowerCase();
    List<HintResult> list = _numbers.where((s) => s.startsWith(word)).map((s) => HintResult(s)).toList();

    HintResults results =
        HintResults.fromHints(list, Position(cur.line, cur.ch - word.length), Position(cur.line, cur.ch));
    results.registerOnShown(() => print('hints shown'));
    results.registerOnSelect((completion, element) {
      print(['hints select: ${completion}']);
    });
    results.registerOnPick((completion) {
      print(['hints pick: ${completion}']);
    });
    results.registerOnUpdate(() => print('hints update'));
    results.registerOnClose(() => print('hints close'));

    return results;
  }

//void _hintRenderer(Element element, HintResult hint) {
//  element.children.add(new DivElement()..text = hint.text);
//}

//void _hintApplier(CodeMirror editor, HintResult hint, Position from, Position to) {
//  editor.getDoc().replaceRange(hint.text + "_foo_", from, to);
//}

  Future<HintResults> _dartCompleterAsync(CodeMirror editor, [HintsOptions options]) {
    Position cur = editor.getCursor();
    String word = _getCurrentWord(editor).toLowerCase();
    List<String> list = List.from(_numbers.where((s) => s.startsWith(word)));

    return Future.delayed(Duration(milliseconds: 200), () {
      return HintResults.fromStrings(
          list, Position(cur.line, cur.ch - word.length), Position(cur.line, cur.ch));
    });
  }

  final List _numbers = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];

  final RegExp _ids = RegExp(r'[a-zA-Z_0-9]');

  String _getCurrentWord(CodeMirror editor) {
    Position cur = editor.getCursor();
    String line = editor.getLine(cur.line);
    StringBuffer buf = StringBuffer();

    for (int i = cur.ch - 1; i >= 0; i--) {
      String c = line[i];
      if (_ids.hasMatch(c)) {
        buf.write(c);
      } else {
        break;
      }
    }

    return String.fromCharCodes(buf.toString().codeUnits.reversed);
  }
}
