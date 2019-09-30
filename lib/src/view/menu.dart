import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';

import '../model/composite_stores.dart';
import '../model/model_ui.dart';
import '../app.dart';

part 'menu.over_react.g.dart';

@Factory()
UiFactory<MenuProps> Menu = _$Menu;

@Props()
class _$MenuProps extends FluxUiProps<ShowStore, ShowStore> {}

@Component()
class MenuComponent extends FluxUiComponent<MenuProps> {
  @override
  Map getDefaultProps() => (newProps());

  /*
  // this is needed in case the user selects the same filename, to reload the file in case it has changed.
  // If not, then the onChange event won't fire and we won't reload the file.
  var file_chooser = app.view.menu_view.file_chooser;
  file_chooser.onClick.listen((_) {
    file_chooser.value = null;
  });
  file_chooser.onChange.listen((_) {
    request_load_file_from_file_chooser(file_chooser);
  });
   */

  @override
  render() {
    bool show_dna = this.props.store.show_dna_store.show_dna;
    bool show_mismatches = this.props.store.show_mismatches_store.show_mismatches;
//    bool show_editor = this.props.store.show_editor_store.show_editor;
    return Dom.div()(
      //XXX: I like to keep this button around to simulate random things that require user interaction
//        (Dom.button()
//          ..onClick = (_) {
//            print('dummy button clicked');
//          }
//          ..key = 'dummy'
//          ..className = 'dummy-button')('Dummy'),
        (Dom.button()
          ..className = 'menu-item'
          ..onClick = (_) {
            app.model.dna_design.save_dna_file();
          }
          ..className = 'save-button-dna-file'
          ..key = 'save')('Save'),
        (Dom.label()
          ..className = 'load-button-dna-file menu-item'
          ..key = 'load')([
          'Load:',
          (Dom.input()
            ..type = 'file'
            ..accept = ALLOWED_EXTENSIONS_DESIGN.map((ext) => '.' + ext).join(",")
            // this is needed in case the user selects the same filename, to reload the file in case it has changed.
            // If not, then the onChange event won't fire and we won't reload the file.
            ..onClick = (e) {
              (e.target).value = null;
            }
            ..onChange = (e) {
              request_load_file_from_file_chooser(e.target);
            }
            ..key = 'load-input')()
        ]),
        (Dom.span()
          ..className = 'show-dna-span menu-item'
          ..key = 'show-dna')(
          (Dom.label()..key = 'show-dna-label')(
            (Dom.input()
              ..checked = show_dna
              ..onChange = (_) {
                app.model.main_view_ui_model.show_dna_store.set_show_dna(!show_dna);
              }
              ..type = 'checkbox')(),
            'show DNA',
          ),
        ),
        //XXX: let's keep this commented out until we need it
//        (Dom.span()
//          ..key = 'show-editor menu-item'
//          ..className = 'show-editor-span')(
//          (Dom.label()..key = 'show-editor-label')(
//            (Dom.input()
//              ..checked = show_editor
//              ..onChange = (_) {
//                app.model.main_view_ui_model.show_editor_store.set_show_editor(!show_editor);
//              }
//              ..type = 'checkbox')(),
//            'show editor',
//          ),
//        ),
        (Dom.span()
          ..className = 'show-mismatches-span menu-item'
          ..key = 'show-mismatches')(
          (Dom.label()..key = 'show-mismatches-label')(
            (Dom.input()
              ..checked = show_mismatches
              ..onChange = (_) {
                app.model.main_view_ui_model.show_mismatches_store.set_show_mismatches(!show_mismatches);
              }
              ..type = 'checkbox')(),
            'show mismatches',
          ),
        ),
        (Dom.a()
          ..className = 'docs-link menu-item'
          ..href = './docs/'
          ..target = '_blank')('Docs'));
  }
}

request_load_file_from_file_chooser(FileUploadInputElement file_chooser) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

  var basefilename = path.basenameWithoutExtension(file.name);

  FileReader file_reader = new FileReader();
  //XXX: Technically to be clean Flux (or Elm architecture), this should be an Action,
  // and what is done in file_loaded should be another Action.
  file_reader.onLoad.listen((_) => file_loaded(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((_) => window.alert(err_msg));
  file_reader.readAsText(file);
}

file_loaded(FileReader file_reader, String filename) {
  app.model.menu_view_ui_model.loaded_filename = filename;
  var json_model_text = file_reader.result;
  app.model.set_new_design_from_json(json_model_text);
}

