import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/example_dna_designs.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:smart_dialogs/smart_dialogs.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../state/app_ui_state.dart';
//import 'menu_card.dart';

part 'menu.over_react.g.dart';

UiFactory<MenuProps> ConnectedMenu = connect<AppState, MenuProps>(
  mapStateToProps: (state) => (Menu()
    ..show_dna = state.ui_state.show_dna
    ..show_mismatches = state.ui_state.show_mismatches
    ..grid = state.dna_design?.grid
    ..example_dna_designs = state.ui_state.example_dna_designs),
)(Menu);

@Factory()
UiFactory<MenuProps> Menu = _$Menu;

@Props()
class _$MenuProps extends UiProps with ConnectPropsMixin {
  bool show_dna;
  bool show_mismatches;
  Grid grid;
  ExampleDNADesigns example_dna_designs;
}

@Component2()
class MenuComponent extends UiComponent2<MenuProps> {
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
    bool show_dna = props.show_dna;
    bool show_mismatches = props.show_mismatches;
    Grid grid = props.grid;
//    bool show_editor = this.props.store.show_editor_store.show_editor;

    String load_example_title = 'Load example';

    return [
      (Dom.label()
        ..className = 'app-name menu-item'
        ..key = 'title-label')('scadnano'),
      //XXX: I like to keep this button around to simulate random things that require user interaction
//      (Dom.button()
//        ..onClick = (_) {
////          util.set_allow_pan(false);
//        }
//        ..key = 'dummy'
//        ..className = 'dummy-button menu-item')('Dummy'),
      (Dom.select()
        ..onChange = (ev) {
          int idx = ev.currentTarget.selectedIndex - 1; // subtract 1 due to title option
          props.dispatch(actions.ExampleDNADesignsIdxSet(selected_idx: idx));
        }
        ..defaultValue = load_example_title
        ..className = 'example-load'
        ..key = 'example-load')([
        (Dom.option()
          ..value = load_example_title
          ..disabled = true
          ..key = 'title')('Load example'),
        ...[
          for (var example_filename in props.example_dna_designs.filenames)
            (Dom.option()
              ..value = example_filename
              ..key = example_filename)(example_filename)
        ]
      ]),
      (Dom.button()
        ..className = 'menu-item'
        ..onClick = (_) {
          props.dispatch(actions.SaveDNAFile());
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
          // If the user selects the same filename as last time they used the fileLoader,
          // we still want to reload the file (it may have changed).
          // But if we don't set (e.target).value to null, if the user selects the same filename,
          // then the onChange event won't fire and we won't reload the file.
          ..onClick = (e) {
            (e.target).value = null;
          }
          ..onChange = (e) {
            request_load_file_from_file_chooser(e.target);
          }
          ..key = 'load-input')()
      ]),
      //XXX: let's keep this commented out until we need it
//        (Dom.span()
//          ..key = 'show-editor menu-item'
//          ..className = 'show-editor-span')(
//          (Dom.label()..key = 'show-editor-label')(
//            (Dom.input()
//              ..checked = show_editor
//              ..onChange = (_) {
//                app.state.main_view_ui_model.show_editor_store.set_show_editor(!show_editor);
//              }
//              ..type = 'checkbox')(),
//            'show editor',
//          ),
//        ),
//      (Dom.button()
//        ..className = 'menu-item'
//        ..onClick = (_) {
//          props.dispatch(dispatcher.ExportSvgSide());
//        }
//        ..className = 'export-svg'
//        ..key = 'export-svg-side')('Export SVG side'),
//      (Dom.button()
//        ..className = 'menu-item'
//        ..onClick = (_) {
//          props.dispatch(dispatcher.ExportSvgMain());
//        }
//        ..className = 'export-svg'
//        ..key = 'export-svg-main')('Export SVG main'),
      (Dom.button()
        ..onClick = //((_) => export_dna())
            ((_) => app.disable_keyboard_shortcuts_while(export_dna))
        ..className = 'export-dna-sequences-button menu-item'
        ..key = 'export-dna-sequences')('Export DNA'),
      (Dom.button()
        ..onClick =
            ((_) => app.dispatch(actions.InlineInsertionsDeletions()))
        ..className = 'inline-ins-del-button menu-item'
        ..key = 'inline-ins-del')('Inline I/D'),
      (Dom.span()
        ..className = 'show-dna-span menu-item'
        ..key = 'show-dna')(
        (Dom.label()..key = 'show-dna-label')(
          (Dom.input()
            ..checked = show_dna
            ..onChange = (_) {
              props.dispatch(actions.SetShowDNA(!show_dna));
            }
            ..type = 'checkbox')(),
          'show DNA',
        ),
      ),
      (Dom.span()
        ..className = 'show-mismatches-span menu-item'
        ..key = 'show-mismatches')(
        (Dom.label()..key = 'show-mismatches-label')(
          (Dom.input()
            ..checked = show_mismatches
            ..onChange = (_) {
//                Actions.set_show_mismatches(!show_mismatches);
              props.dispatch(actions.SetShowMismatches(!show_mismatches));
            }
            ..type = 'checkbox')(),
          'show mismatches',
        ),
      ),
      (Dom.select()
        ..name = 'Grid'
        ..onChange = ((ev) {
          int idx = ev.currentTarget.selectedIndex - 1; // subtract 1 due to Grid title option
          props.dispatch(actions.GridChange(grid: grid_options[idx]));
        })
        ..value = grid.toString()
        ..key = 'grid')([
        (Dom.option()
          ..value = 'Grid'
          ..disabled = true
          ..key = 'title')('Grid type'),
        ...[
          for (var grid in grid_options)
            (Dom.option()
              ..value = grid.toString()
              ..key = grid.toString())(grid.toString())
        ]
      ]),
      (Dom.a()
        ..className = 'docs-link menu-item'
        ..href = 'README.html'
        //TODO: when repository is public, make the github link the official documentation link
//        ..href = 'https://github.com/UC-Davis-molecular-computing/scadnano'
        ..target = '_blank'
        ..key = 'help-link')('Help'),
      (Dom.a()
        ..className = 'docs-link menu-item'
        ..href = './docs/'
        ..target = '_blank'
        ..key = 'script-help-link')('Script Docs'),
    ];
  }

  final List<Grid> grid_options = [Grid.square, Grid.honeycomb, Grid.hex, Grid.none];

  Future<void> export_dna() async {
    // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
    String buttontype = DiaAttr.CHECKBOX;
    String htmlTitleText = 'export DNA sequences';
    List<String> textLabels = ['include scaffold?', 'output type'];
    List<List<String>> comboInfo = [null, ExportDNAFormat.values.map((v) => v.toString()).toList()];
    List<String> defaultInputTexts = [null, ExportDNAFormat.idt_bulk.toString()];
    List<int> widths = [0, 20];
    List<String> isChecked = ['false', null];
    bool alternateRowColor = false;
    List<String> buttonLabels = ['OK', 'Cancel'];

    UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
        widths, isChecked, alternateRowColor, buttonLabels);

    if (result.buttonCode != 'DIA_ACT_OK') {
      return;
    }

    bool include_scaffold = result.getCheckedState(0) == 'true';
    String format_str = result.getUserInput(1)[0];
    ExportDNAFormat format = ExportDNAFormat.fromString(format_str);

    props.dispatch(actions.ExportDNA(include_scaffold: include_scaffold, export_dna_format: format));
  }
}

request_load_file_from_file_chooser(FileUploadInputElement file_chooser) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

//  var basefilename = path.basenameWithoutExtension(file.name);
  var basefilename = path.basename(file.name);

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
  var json_model_text = file_reader.result;
  app.dispatch(actions.LoadDNAFile(content: json_model_text, filename: filename));
}
