import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/example_dna_designs.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/view/redraw_counter_component_mixin.dart';
import 'package:scadnano/src/view/react_bootstrap.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'package:smart_dialogs/smart_dialogs.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../state/app_ui_state.dart';
import '../util.dart' as util;

part 'menu.over_react.g.dart';

UiFactory<MenuProps> ConnectedMenu = connect<AppState, MenuProps>(
  mapStateToProps: (state) => (Menu()
    ..show_dna = state.ui_state.show_dna
    ..show_modifications = state.ui_state.show_modifications
    ..show_mismatches = state.ui_state.show_mismatches
    ..autofit = state.ui_state.autofit
    ..grid = state.dna_design?.grid
    ..example_dna_designs = state.ui_state.example_dna_designs
    ..design_has_insertions_or_deletions = state.dna_design?.has_insertions_or_deletions == true
    ..undo_stack_empty = state.undo_redo.undo_stack.isEmpty
    ..redo_stack_empty = state.undo_redo.redo_stack.isEmpty),
  // Used for component test.
  forwardRef: true,
)(Menu);

@Factory()
UiFactory<MenuProps> Menu = _$Menu;

@Props()
class _$MenuProps extends UiProps with ConnectPropsMixin {
  bool show_dna;
  bool show_modifications;
  bool show_mismatches;
  bool autofit;
  Grid grid;
  ExampleDNADesigns example_dna_designs;
  bool design_has_insertions_or_deletions;
  bool undo_stack_empty;
  bool redo_stack_empty;
}

@Component2()
class MenuComponent extends UiComponent2<MenuProps> with RedrawCounterMixin {
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
    return Navbar(
      {
        'bg': 'light',
        'expand': 'lg',
      },
      NavbarBrand({}, 'scadnano'),
      NavDropdown(
        {
          'title': 'File',
          'id': 'file-nav-dropdown',
        },
        DropdownItem(
          {
            'onClick': (_) {
              app.disable_keyboard_shortcuts_while(load_example_dialog);
            },
          },
          '📄 Load example',
        ),
        FormFile(
          {
            'id': 'open-form-file',
            'className': 'form-file-dropdown',
            'accept': ALLOWED_EXTENSIONS_DESIGN.map((ext) => '.' + ext).join(","),
            // If the user selects the same filename as last time they used the fileLoader,
            // we still want to reload the file (it may have changed).
            // But if we don't set (e.target).value to null, if the user selects the same filename,
            // then the onChange event won't fire and we won't reload the file.
            'onClick': (e) {
              (e.target).value = null;
            },
            'onChange': (e) {
              request_load_file_from_file_chooser(e.target, scadnano_file_loaded);
            },
            'label': '📂 Open...',
            'custom': 'false',
          },
        ),
        DropdownDivider({}),
        DropdownItem(
          {
            'onClick': (_) {
              props.dispatch(actions.SaveDNAFile());
            },
          },
          '💾 Save...',
        ),
        DropdownDivider({}),
        FormFile(
          {
            'id': 'import-cadnano-form-file',
            'className': 'form-file-dropdown',
            'accept': '.json',
            // If the user selects the same filename as last time they used the fileLoader,
            // we still want to reload the file (it may have changed).
            // But if we don't set (e.target).value to null, if the user selects the same filename,
            // then the onChange event won't fire and we won't reload the file.
            'onClick': (e) {
              (e.target).value = null;
            },
            'onChange': (e) {
              request_load_file_from_file_chooser(e.target, cadnano_file_loaded);
            },
            'label': 'Import cadnano v2',
            'custom': 'false',
          },
        ),
        DropdownItem(
          {
            'onClick': (_) {
              props.dispatch(actions.ExportCadnanoFile());
            },
          },
          'Export cadnano v2',
        ),
      ),
      NavDropdown(
        {
          'title': 'Edit',
          'id': 'edit-nav-dropdown',
        },
        DropdownItem(
          {
            'disabled': props.undo_stack_empty,
            'onClick': (_) {
              props.dispatch(actions.Undo());
            },
          },
          'Undo',
          (Dom.span()
            ..style = {
              'marginLeft': '2em',
              // 'opacity': '50%',
            })(
            'Ctrl+Z',
          ),
        ),
        DropdownItem(
          {
            'disabled': props.redo_stack_empty,
            'onClick': (_) {
              props.dispatch(actions.Redo());
            },
          },
          'Redo',
          (Dom.span()
            ..style = {
              'marginLeft': '2em',
              // 'opacity': '50%',
            })(
            'Ctrl+Shift+Z',
          ),
        ),
        DropdownDivider({}),
        DropdownItem(
          {
            'disabled': !props.design_has_insertions_or_deletions,
            'onClick': (_) {
              props.dispatch(actions.InlineInsertionsDeletions());
            },
          },
          'Inline Insertions/Deletions',
        ),
      ),
      NavDropdown(
        {
          'title': 'View',
          'id': 'view-nav-dropdown',
        },
        (Dom.span()
          ..title = '''Check to show DNA sequences that have been assigned to strands.
In a large design, this can slow down the performance of panning and
zooming navigation, so uncheck it to speed up navigation.'''
          ..className = 'show-dna-span menu-item'
          ..style = {'display': 'block'}
          ..key = 'show-dna')(
          (Dom.label()..key = 'show-dna-label')(
            (Dom.input()
              ..style = {'marginRight': '1em'}
              ..checked = props.show_dna
              ..onChange = (_) {
                props.dispatch(actions.ShowDNASet(!props.show_dna));
              }
              ..addTestId('scadnano.MenuComponent.input.show_dna')
              ..type = 'checkbox')(),
            'Show DNA sequences',
          ),
        ),
        (Dom.span()
          ..title = '''Check to show DNA modifications (e.g., biotins, fluorophores).'''
          ..className = 'show-modifications-span menu-item'
          ..style = {'display': 'block'}
          ..key = 'show-modifications')(
          (Dom.label()..key = 'show-modifications-label')(
            (Dom.input()
              ..style = {'marginRight': '1em'}
              ..checked = props.show_modifications
              ..onChange = (_) {
                props.dispatch(actions.ShowModificationsSet(!props.show_modifications));
              }
              ..addTestId('scadnano.MenuComponent.input.show_modifications')
              ..type = 'checkbox')(),
            'Show modifications',
          ),
        ),
        (Dom.span()
          ..className = 'show-mismatches-span menu-item'
          ..style = {'display': 'block'}
          ..key = 'show-mismatches')(
          (Dom.label()
            ..title = '''Check to show mismatches between DNA assigned to one strand
and the strand on the same helix with the opposite orientation.'''
            ..key = 'show-mismatches-label')(
            (Dom.input()
              ..style = {'marginRight': '1em'}
              ..checked = props.show_mismatches
              ..onChange = (_) {
                props.dispatch(actions.ShowMismatchesSet(!props.show_mismatches));
              }
              ..addTestId('scadnano.MenuComponent.input.show_mismatches')
              ..type = 'checkbox')(),
            'Show DNA base mismatches',
          ),
        ),
        (Dom.span()
          ..className = 'center-on-load-span menu-item'
          ..style = {'display': 'block'}
          ..key = 'center-on-load')(
          (Dom.label()
            ..title = '''Check this so that, when loading a new design, the side and main views will be
translated to show the lowest-index helix in the upper-left. otherwise, after
loading the design, you may not be able to see it because it is translated off
the screen.

You may want to uncheck this when working on a design with the scripting library.
in that case, when repeatedly re-running the script to modify the design and then
re-loading it, it is preferable to keep the design centered at the same location
you had before, in order to be able to see the same part of the design you were
looking at before changing the script.'''
            ..key = 'center-on-load-label')(
            (Dom.input()
              ..style = {'marginRight': '1em'}
              ..checked = props.autofit
              ..onChange = (_) {
                props.dispatch(actions.AutofitSet(autofit: !props.autofit));
              }
              ..addTestId('scadnano.MenuComponent.input.center_on_load')
              ..type = 'checkbox')(),
            'auto-fit on loading new design',
          ),
        ),
        //XXX: let's keep this commented out until we need it
        // (Dom.span()
        //   ..key = 'show-editor menu-item'
        //   ..className = 'show-editor-span')(
        //   (Dom.label()..key = 'show-editor-label')(
        //     (Dom.input()
        //       ..checked = show_editor
        //       ..onChange = (_) {
        //         app.state.main_view_ui_model.show_editor_store.set_show_editor(!show_editor);
        //       }
        //       ..type = 'checkbox')(),
        //     'show editor',
        //   ),
        // ),
      ),
      NavDropdown(
        {
          'title': 'Grid',
          'id': 'grid-nav-dropdown',
        },
        [
          for (var grid in grid_options)
            DropdownItem(
              {
                'active': grid == props.grid,
                'disabled': grid == props.grid,
                'key': grid.toString(),
                'onClick': (ev) {
                  props.dispatch(actions.GridChange(grid: grid));
                },
              },
              grid.toString(),
            )
        ],
      ),
      NavDropdown(
        {
          'title': 'Export',
          'id': 'export-nav-dropdown',
        },
        DropdownItem(
          {
            'onClick': (_) {
              props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.side));
            },
          },
          'SVG side view',
        ),
        DropdownItem(
          {
            'onClick': (_) {
              props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.main));
            },
          },
          'SVG main view',
        ),
        DropdownItem(
          {
            'onClick': (_) {
              app.disable_keyboard_shortcuts_while(export_dna);
            },
          },
          'SVG DNA',
        ),
      ),
      NavDropdown(
        {
          'title': 'Help',
          'id': 'help-nav-dropdown',
        },
        DropdownItem(
          {
            'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/blob/master/README.md',
            'target': '_blank',
          },
          'Guide',
        ),
        DropdownItem(
          {
            'href': 'https://scadnano-python-package.readthedocs.io',
            'target': '_blank',
          },
          'Python scripting documentation',
        ),
      ),
      //XXX: I like to keep this button around to simulate random things that require user interaction
      // Button(
      //   {
      //     'variant': 'light',
      //     'onClick': (_) {
      //       window.alert('Dummy!');
      //     }
      //   },
      //   'Dummy',
      // ),
    );
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

  Future<void> load_example_dialog() async {
    var dialog = Dialog(title: 'Load example DNA design', items: [
      DialogRadio(
        label: 'designs',
        options: props.example_dna_designs.filenames,
      ),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    int selected_idx = (results[0] as DialogRadio).selected_idx;
    props.dispatch(actions.ExampleDNADesignsLoad(selected_idx: selected_idx));
  }
}

request_load_file_from_file_chooser(
    FileUploadInputElement file_chooser, void Function(FileReader, String) onload_callback) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

//  var basefilename = path.basenameWithoutExtension(file.name);
  var basefilename = path.basename(file.name);

  FileReader file_reader = new FileReader();
  //XXX: Technically to be clean Flux (or Elm architecture), this should be an Action,
  // and what is done in file_loaded should be another Action.
  file_reader.onLoad.listen((_) => onload_callback(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((_) => window.alert(err_msg));
  file_reader.readAsText(file);
}

scadnano_file_loaded(FileReader file_reader, String filename) {
  var json_model_text = file_reader.result;
  app.dispatch(actions.LoadDNAFile(content: json_model_text, filename: filename));
}

cadnano_file_loaded(FileReader file_reader, String filename) async {
  var json_cadnano_text = file_reader.result;
  var response = await http.post(
    constants.import_url,
    body: json_cadnano_text,
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    var json_model_text = response.body;
    filename = path.setExtension(filename, '.dna');
    app.dispatch(actions.LoadDNAFile(content: json_model_text, filename: filename));
  } else {
    Map response_body_json = jsonDecode(response.body);
    window.alert('Error importing file: ${response_body_json['error']}');
  }
}
