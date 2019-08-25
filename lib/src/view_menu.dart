import 'dart:html';

import 'model_ui.dart';
import 'app.dart';

class MenuViewComponent {
  final DivElement root_element;

  final SpanElement file_buttons_elt = SpanElement();
  final ButtonElement save_button = ButtonElement();

  final SpanElement show_dna_elt = SpanElement();
  final SpanElement show_editor_elt = SpanElement();
  final FileUploadInputElement file_chooser = FileUploadInputElement();
  final CheckboxInputElement show_dna_checkbox = CheckboxInputElement();
  final CheckboxInputElement show_editor_checkbox = CheckboxInputElement();

  MenuViewComponent(this.root_element);

  render() {
    this.root_element.children.clear();
    this.root_element.children.add(this.file_buttons_elt);
    this.root_element.children.add(this.show_dna_elt);
    this.root_element.children.add(this.show_editor_elt);

    this.render_file_buttons();
    this.render_show_dna_checkbox();
    this.render_show_editor_checkbox();

    // should do this after file buttons are rendered since they are simulate-clicked
    this.setup_keyboard_shortcuts();
  }

  render_show_dna_checkbox() {
    this.show_dna_elt.children.clear();
    this.show_dna_checkbox.checked = app.model.show_dna;
    var label_show_dna = LabelElement();
    var span_show_dna = SpanElement();
    show_dna_elt.children.add(span_show_dna);
    span_show_dna.children.add(this.show_dna_checkbox);
    span_show_dna.children.add(label_show_dna);
    label_show_dna.text = "show DNA sequence";
    label_show_dna.onClick.listen((_) => this.show_dna_checkbox.click());
  }

  render_show_editor_checkbox() {
    this.show_editor_elt.children.clear();
    this.show_editor_checkbox.checked = app.model.show_editor;
    var label_show_editor = LabelElement();
    var span_show_editor = SpanElement();
    show_dna_elt.children.add(span_show_editor);
    span_show_editor.children.add(this.show_editor_checkbox);
    span_show_editor.children.add(label_show_editor);
    label_show_editor.text = "show editor";
    label_show_editor.onClick.listen((_) => this.show_editor_checkbox.click());
  }

  render_file_buttons() {
    this.file_buttons_elt.children.clear();

    // save button
    this.file_buttons_elt.children.add(save_button);
    this.save_button.text = "Save";
    this.save_button.disabled = !app.model.changed_since_last_save;

    // load button
    this.file_buttons_elt.children.add(new LabelElement()..text = "Load:");
    this.file_buttons_elt.children.add(file_chooser);
    this.file_chooser.accept = ALLOWED_EXTENSIONS_DESIGN.map((ext) => '.' + ext).join(",");
  }

  setup_keyboard_shortcuts() {
    // "save to file" Ctrl+S and "open file" Ctrl+O keyboard shortcuts
    // it matters that these are onKeyDown, not onKeyPress:
    // https://stackoverflow.com/questions/11000826/ctrls-preventdefault-in-chrome
//    KeyEvent.keyDownEvent.forTarget(document.body).listen((KeyEvent event) {
//    document.body.onKeyDown.listen((KeyboardEvent event) {
    Element.keyDownEvent.forTarget(window, useCapture: true).listen((KeyboardEvent ev) {
//      print('key pressed');
      if (ev.ctrlKey && !ev.shiftKey && !ev.altKey && ev.code == 'KeyS' && !save_button.disabled) {
        print('Ctrl+${ev.code} clicked');
        this.save_button.click();
        ev.preventDefault();
        ev.stopPropagation();
      }
      //TODO: Chrome clicks more than once on a single Ctrl+O;
      // Firefox registers both but seems only to open the file dialog once
      if (ev.ctrlKey && !ev.shiftKey && !ev.altKey && ev.code == 'KeyO') {
        print('Ctrl+${ev.code} clicked');
        this.file_chooser.click();
        ev.preventDefault();
        ev.stopPropagation();
      }
    });
  }
}
