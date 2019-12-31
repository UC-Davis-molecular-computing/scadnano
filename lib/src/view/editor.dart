import 'dart:async';
import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:codemirror/codemirror.dart';
import 'package:codemirror/hints.dart';

import '../app.dart';
import '../state/app_ui_state.dart';

//TODO: compile Python scripts in the browser using pyodide (or something)

/// This should only be created once in the app lifetime, so not much happens in the render() method.
/// Since it uses the CodeMirror library, it falls a bit outside of the reactive component framework of the
/// rest of the view and acts more like an outside agent communicating with the rest of the app.
/// (except for the fact that the app can choose to hide or show it, but it remains "rendered" in the background
/// and is simply removed from/added to the DOM)
///
/// However, other than being hidden/shown, this does not react to any changes happening outside of its element.
/// The updating of its source code goes through the normal event loop but only involves elements in this component.
class EditorViewComponent {
  DivElement root_element;
  ParagraphElement footer_element = ParagraphElement()..attributes = {'id': 'footer'};
  CodeMirror editor;

  final SpanElement controls_element = SpanElement();
  final ButtonElement save_button = ButtonElement();
  final ButtonElement compile_button = ButtonElement();
  final FileUploadInputElement file_chooser = FileUploadInputElement();

  SelectElement theme_select_element = SelectElement();

  EditorViewComponent(this.root_element) {
    this.render_controls();

    var editor_div_element = DivElement()..attributes = {'id': 'editor'};
    this.root_element.children.add(editor_div_element);

    this.root_element.children.add(footer_element);

    Map options = {
      'theme': 'mbo',
      'continueComments': {'continueLineComment': false},
      'autoCloseTags': true,
      'mode': 'python',
      'lineNumbers': true,
      'indentUnit': 4,
      'extraKeys': {'Ctrl-Space': 'autocomplete', 'Cmd-/': 'toggleComment', 'Ctrl-/': 'toggleComment'}
    };

    this.editor = CodeMirror.fromElement(editor_div_element, options: options);

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

    Hints.registerHintsHelper('dart', _dartCompleter);
    Hints.registerHintsHelperAsync('dart', _dartCompleterAsync);

    // Status line.
    _updateFooter(editor);
    editor.onCursorActivity.listen((_) => _updateFooter(editor));

    CodeMirror.addCommand('find', (foo) {
      /*LineHandle handle =*/ editor.getDoc().getLineHandle(editor.getCursor().line);

      print('todo: handle find');
    });

    editor.onDoubleClick.listen((MouseEvent evt) {
      Doc doc = editor.getDoc();
      print('[${doc.getLine(doc.getCursor().line).trim()}]');
    });

    editor.getDoc().setValue(app.state.editor_content);
  }

  render() {
    editor.refresh();
  }

  void render_controls() {
    this.controls_element.children.clear();

    this.controls_element.children.add(this.compile_button);

    this.root_element.children.add(this.controls_element);

    // compile button
    this.controls_element.children.add(compile_button);
    this.compile_button.text = "Compile";

    // save button
    this.controls_element.children.add(save_button);
    this.save_button.text = "Save";
    this.save_button.disabled = !app.state.ui_state.changed_since_last_save;

    // load button
    this.controls_element.children.add(new LabelElement()..text = "Load:");
    this.controls_element.children.add(file_chooser);
    this.file_chooser.accept = ALLOWED_EXTENSIONS_SCRIPT.map((ext) => '.' + ext).join(",");

    // Theme control.
    var theme_label_element = LabelElement()..attributes = {'for': 'theme'};
    theme_label_element.setInnerHtml('Theme:');
    this.theme_select_element = SelectElement()..attributes = {'id': 'theme'};
    controls_element.children.addAll([theme_label_element, this.theme_select_element]);
    this.root_element.children.add(controls_element);
  }

  void _updateFooter(CodeMirror editor) {
    Position pos = editor.getCursor();
    int off = editor.getDoc().indexFromPos(pos);
    String str = 'line ${pos.line} • column ${pos.ch} • offset ${off}' +
        (editor.getDoc().isClean() ? '' : ' • (modified)');
    this.footer_element.text = str;
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


//TODO: there's a lot of repeated code between here and the functions that save/load the .dna files
// handle file saving/loading for script files
script_save_file() async {
  Blob blob = new Blob([app.state.editor_content], 'text/plain;charset=utf-8');
  String url = Url.createObjectUrlFromBlob(blob);
  String filename = app.state.ui_state.loaded_script_filename;
  var link = new AnchorElement()
    ..href = url
    ..download = filename;

  document.body.children.add(link);
  await link.click();
  link.remove();
}

request_script_load_file_from_file_chooser(FileUploadInputElement file_chooser) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

  var basefilename = path.basenameWithoutExtension(file.name);

  FileReader file_reader = new FileReader();
  file_reader.onLoad.listen((_) => script_file_loaded(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((_) => window.alert(err_msg));
  file_reader.readAsText(file);
}

script_file_loaded(FileReader file_reader, String filename) {
  //FIXME: send an action to update the fields loaded_script_filename and editor_content
//  app.state.ui_model.loaded_script_filename = filename;
//  app.state.editor_content = file_reader.result;
//  print('in dart, just put this script file contents into state: ${app.state.editor_content}');
  app.view.editor_view.render();
}
