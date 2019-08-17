import 'dart:async';
import 'dart:html';

import 'package:codemirror/codemirror.dart';
import 'package:codemirror/hints.dart';

import 'actions.dart';

import 'app.dart';

class EditorViewComponent {

  DivElement element;
  ParagraphElement footer_element;
  CodeMirror editor;

  /*
    <div class="split" id="editor-pane">
        <div id="controls">
            <label for="theme">Theme:</label>
            <select id="theme"></select>
        </div>
        <div id="editor"></div>
        <p id="footer"></p>
    </div>
   */

  EditorViewComponent(this.element) {
    var controls_element = DivElement()..attributes = {'id': 'controls'};
    var theme_label_element = LabelElement()..attributes = {'for': 'theme'};
    theme_label_element.setInnerHtml('Theme:');
    var theme_select_element = SelectElement()..attributes = {'id': 'theme'};
    controls_element.children.addAll([theme_label_element, theme_select_element]);
    this.element.children.add(controls_element);

    var editor_div_element = DivElement()..attributes = {'id': 'editor'};
    this.element.children.add(editor_div_element);

    this.footer_element = ParagraphElement()..attributes = {'id': 'footer'};
    this.element.children.add(footer_element);

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
    for (String theme in CodeMirror.THEMES) {
      theme_select_element.children.add(OptionElement(value: theme)..text = theme);
      if (theme == editor.getTheme()) {
        theme_select_element.selectedIndex = theme_select_element.length - 1;
      }
    }
    theme_select_element.onChange.listen((e) {
      String themeName = theme_select_element.options[theme_select_element.selectedIndex].value;
      editor.setTheme(themeName);
    });

    // Status line.
    _updateFooter(editor);
    editor.onCursorActivity.listen((_) => _updateFooter(editor));

    editor.refresh();

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
    //TODO: make editor unfocused somewhen clicking outside of it
  }

  void _updateFooter(CodeMirror editor) {
    Position pos = editor.getCursor();
    int off = editor.getDoc().indexFromPos(pos);
    String str = 'line ${pos.line} • column ${pos.ch} • offset ${off}' +
        (editor.getDoc().isClean() ? '' : ' • (modified)');
    this.footer_element.text = str;
//    querySelector('#footer').text = str;
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
