import 'dart:html';

import 'model.dart';
import 'app.dart';

class MenuViewElement {
  final DivElement menu_elt = querySelector('#menu');

  final SpanElement file_buttons_elt = SpanElement();
  final SpanElement show_dna_elt = SpanElement();
  final FileUploadInputElement file_chooser = FileUploadInputElement();
  final CheckboxInputElement show_dna_checkbox = CheckboxInputElement();
  final ButtonElement save_button = ButtonElement();

  MenuViewElement();

  render() {
//    print("rendering menu view. stack trace: ${StackTrace.current}");
    this.menu_elt.children.clear();
    this.menu_elt.children.add(this.file_buttons_elt);
    this.menu_elt.children.add(this.show_dna_elt);

    this.render_file_buttons();
    this.render_show_dna_checkbox();

    // should do this after file buttons are rendered since they are simulate-clicked
    this.setup_keyboard_shortcuts();
  }

  render_show_dna_checkbox() {
    this.show_dna_elt.children.clear();
    this.show_dna_checkbox.checked = app.model.show_dna;
    var label = LabelElement();
    var span = SpanElement();
    show_dna_elt.children.add(span);
    span.children.add(show_dna_checkbox);
    span.children.add(label);
    label.text = "show DNA sequence";
    label.onClick.listen((_) => show_dna_checkbox.click());
  }

  render_file_buttons() {
    this.file_buttons_elt.children.clear();

    // save button
    file_buttons_elt.children.add(save_button);
    this.save_button.text = "Save";
    this.save_button.disabled = !app.model.changed_since_last_save;

    // load button
    this.file_buttons_elt.children.add(new LabelElement()..text = "Load:");
    this.file_buttons_elt.children.add(file_chooser);
    this.file_chooser.accept = ALLOWED_EXTENSIONS.map((ext) => '.' + ext).join(",");
  }

  setup_keyboard_shortcuts() {
    // "save to file" Ctrl+S and "open file" Ctrl+O keyboard shortcuts
    // it matters that these are onKeyDown, not onKeyPress:
    // https://stackoverflow.com/questions/11000826/ctrls-preventdefault-in-chrome
    document.body.onKeyDown.listen((KeyboardEvent event) {
      if (event.ctrlKey && !event.shiftKey && !event.altKey && (event.code == 'KeyS' || event.code == 'KeyO')) {
        print('Ctrl + ${event.code} default behavior prevented');
        event.preventDefault();
      }
      if (event.ctrlKey && !event.shiftKey && !event.altKey && event.code == 'KeyS' && !save_button.disabled) {
        print("save button disabled after Ctrl+S pressed? ${save_button.disabled}");
        this.save_button.click();
      }
      if (event.ctrlKey && !event.shiftKey && !event.altKey && event.code == 'KeyO') {
        this.file_chooser.click();
      }
    });
  }
}
