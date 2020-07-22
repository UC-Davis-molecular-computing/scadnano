import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/example_designs.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/local_storage_design_choice.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/view/menu_number.dart';
import 'package:scadnano/src/view/redraw_counter_component_mixin.dart';
import 'package:scadnano/src/view/react_bootstrap.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'package:smart_dialogs/smart_dialogs.dart';
import 'package:scadnano/src/view/menu_boolean.dart';
import 'package:scadnano/src/view/menu_dropdown_item.dart';
import 'package:scadnano/src/view/menu_form_file.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

part 'menu.over_react.g.dart';

UiFactory<MenuProps> ConnectedMenu = connect<AppState, MenuProps>(
  mapStateToProps: (state) => (Menu()
    ..show_dna = state.ui_state.show_dna
    ..show_modifications = state.ui_state.show_modifications
    ..show_mismatches = state.ui_state.show_mismatches
    ..strand_paste_keep_color = state.ui_state.strand_paste_keep_color
    ..autofit = state.ui_state.autofit
    ..only_display_selected_helices = state.ui_state.only_display_selected_helices
    ..grid = state.design?.grid
    ..example_designs = state.ui_state.example_designs
    ..design_has_insertions_or_deletions = state.design?.has_insertions_or_deletions == true
    ..undo_stack_empty = state.undo_redo.undo_stack.isEmpty
    ..redo_stack_empty = state.undo_redo.redo_stack.isEmpty
    ..enable_copy = (app.state.ui_state.edit_modes.contains(EditModeChoice.select) &&
        app.state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand) &&
        app.state.ui_state.selectables_store.selected_items.isNotEmpty)
    ..modification_font_size = state.ui_state.modification_font_size
    ..major_tick_offset_font_size = state.ui_state.major_tick_offset_font_size
    ..major_tick_width_font_size = state.ui_state.major_tick_width_font_size
    ..modification_display_connector = state.ui_state.modification_display_connector
    ..display_of_major_ticks_offsets = state.ui_state.display_base_offsets_of_major_ticks
    ..display_base_offsets_of_major_ticks_only_first_helix =
        state.ui_state.display_base_offsets_of_major_ticks_only_first_helix
    ..display_major_tick_widths = state.ui_state.display_major_tick_widths
    ..display_major_tick_widths_all_helices = state.ui_state.display_major_tick_widths_all_helices
    ..invert_yz = state.ui_state.invert_yz
    ..show_helix_circles_main_view = state.ui_state.show_helix_circles_main_view
    ..warn_on_exit_if_unsaved = state.ui_state.warn_on_exit_if_unsaved
    ..show_grid_coordinates_side_view = state.ui_state.show_grid_coordinates_side_view
    ..local_storage_design_choice = state.ui_state.local_storage_design_choice
    ..default_crossover_type_scaffold_for_setting_helix_rolls =
        state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls
    ..default_crossover_type_staple_for_setting_helix_rolls =
        state.ui_state.default_crossover_type_staple_for_setting_helix_rolls),
  // Used for component test.
  forwardRef: true,
)(Menu);

UiFactory<MenuProps> Menu = _$Menu;

mixin MenuPropsMixin on UiProps {
  bool show_dna;
  bool show_modifications;
  num modification_font_size;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool modification_display_connector;
  bool show_mismatches;
  bool strand_paste_keep_color;
  bool autofit;
  bool only_display_selected_helices;
  Grid grid;
  ExampleDesigns example_designs;
  bool design_has_insertions_or_deletions;
  bool undo_stack_empty;
  bool redo_stack_empty;
  bool enable_copy;
  bool display_of_major_ticks_offsets;
  bool display_base_offsets_of_major_ticks_only_first_helix;
  bool display_major_tick_widths;
  bool display_major_tick_widths_all_helices;
  bool invert_yz;
  bool warn_on_exit_if_unsaved;
  bool show_helix_circles_main_view;
  bool show_grid_coordinates_side_view;
  bool default_crossover_type_scaffold_for_setting_helix_rolls;
  bool default_crossover_type_staple_for_setting_helix_rolls;
  LocalStorageDesignChoice local_storage_design_choice;
}

class MenuProps = UiProps with MenuPropsMixin, ConnectPropsMixin;

class MenuComponent extends UiComponent2<MenuProps> with RedrawCounterMixin {
  @override
  get consumedProps => propsMeta.forMixins({MenuPropsMixin});

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
      file_menu(),
      edit_menu(),
      view_menu(),
      grid_menu(),
      export_menu(),
      help_menu(),
//      dummy_button(),
    );
  }

  dummy_button() {
    return Button(
      //XXX: I like to keep this button around to simulate random things that require user interaction
      {
        'variant': 'light',
        'onClick': (_) {
          window.alert('Dummy!');
        }
      },
      'Dummy',
    );
  }

  file_menu() {
    return NavDropdown({
      'title': 'File',
      'id': 'file-nav-dropdown',
    }, [
      (MenuDropdownItem()
        ..on_click = ((_) => app.disable_keyboard_shortcuts_while(load_example_dialog))
        ..display = '📄 Load example'
        ..key = 'load-example')(),
      (MenuFormFile()
        ..id = 'open-form-file'
        ..accept = constants.all_scadnano_file_extensions.map((ext) => '.' + ext).join(",")
        ..onChange = ((e) => request_load_file_from_file_chooser(e.target, scadnano_file_loaded))
        ..display = '📂 Open...'
        ..keyboard_shortcut = 'Ctrl+O'
        ..key = 'open-form-file')(),
      DropdownDivider({'key': 'divider-file-load'}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.SaveDNAFile()))
        ..display = '💾 Save...'
        ..keyboard_shortcut = 'Ctrl+S'
        ..key = 'save-file')(),
      (MenuBoolean()
        ..value = props.warn_on_exit_if_unsaved
        ..display = 'Warn on exit if unsaved'
        ..tooltip = '''\
If checked, before attempting to close or refresh the page, if the design has 
changed since it was last saved, a warning dialog is displayed to ask if you
really want to exit without saving.'''
        ..onChange =
            ((_) => props.dispatch(actions.WarnOnExitIfUnsavedSet(warn: !props.warn_on_exit_if_unsaved)))
        ..key = 'warn-on-exit-if-unsaved')(),
      DropdownDivider({'key': 'divider-save'}),
      (MenuFormFile()
        ..id = 'import-cadnano-form-file'
        ..accept = '.json'
        ..onChange = ((e) => request_load_file_from_file_chooser(e.target, cadnano_file_loaded))
        ..display = 'Import cadnano v2'
        ..key = 'import-cadnano')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportCadnanoFile()))
        ..display = 'Export cadnano v2'
        ..key = 'export-cadnano')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportCodenanoFile()))
        ..display = 'Export codenano'
        ..key = 'export-codenano')(),
      DropdownDivider({'key': 'divider-export'}),
      ...file_menu_save_design_local_storage_options(),
    ]);
  }

  edit_menu() {
    return NavDropdown(
      {
        'title': 'Edit',
        'id': 'edit-nav-dropdown',
      },
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.Undo()))
        ..display = 'Undo'
        ..keyboard_shortcut = 'Ctrl+Z'
        ..disabled = props.undo_stack_empty)(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.Redo()))
        ..display = 'Redo'
        ..keyboard_shortcut = 'Ctrl+Shift+Z'
        ..disabled = props.redo_stack_empty)(),
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = (_) {
          if (props.enable_copy) {
            window.dispatchEvent(new KeyEvent('keydown', keyCode: KeyCode.C, ctrlKey: true).wrapped);
          }
        }
        ..display = 'Copy'
        ..keyboard_shortcut = 'Ctrl+C'
        ..disabled = !props.enable_copy)(),
      (MenuDropdownItem()
        ..on_click =
            ((_) => window.dispatchEvent(new KeyEvent('keydown', keyCode: KeyCode.V, ctrlKey: true).wrapped))
        ..display = 'Paste'
        ..keyboard_shortcut = 'Ctrl+V')(),
      DropdownDivider({}),
      (MenuBoolean()
        ..value = props.strand_paste_keep_color
        ..display = 'Pasted Strands Keep Original Color'
        ..tooltip = '''\
If checked, when copying and pasting a strand, the color is preserved.
If unchecked, then a new color is generated.'''
        ..onChange =
            ((_) => props.dispatch(actions.StrandPasteKeepColorSet(keep: !props.strand_paste_keep_color))))(),
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.InlineInsertionsDeletions()))
        ..display = 'Inline Insertions/Deletions'
        ..disabled = !props.design_has_insertions_or_deletions
        ..tooltip = ''
            '''
Remove insertions and deletions from the design and replace them with domains
whose lengths correspond to the true strand length. Also moves major tick 
marks on helices so that they are adjacent to the same bases as before.''')(),
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.HelicesPositionsSetBasedOnCrossovers()))
        ..display = 'Set helix coordinates based on crossovers'
        ..disabled = props.grid != Grid.none
        ..tooltip = '''\
The grid must be set to none to enable this.

Select some crossovers and some helices. If no helices are selected, then all
helices are processed. At most one crossover between pairs of adjacent (in 
view order) helices can be selected. If a pair of adjacent helices has no 
crossover selected, it is assumed to be the first crossover.  

New grid coordinates are calculated based on the crossovers to ensure that each 
pair of adjacent helices has crossover angles that point the backbone angles 
directly at the adjoining helix.''')(),
      (MenuBoolean()
        ..value = props.default_crossover_type_scaffold_for_setting_helix_rolls
        ..display = 'default to leftmost scaffold crossover'
        ..tooltip = '''\
When selecting "Set helix coordinates based on crossovers", if two adjacent 
helices do not have a crossover selected, determines which types to select 
automatically.

If this is checked and "default to leftmost staple crossover" is unchecked,
then the leftmost scaffold crossover will be used.

If both are checked, the leftmost crossover of any type will be used.

Ignored if design is not an origami (i.e., does not have at least one scaffold).'''
        ..onChange = (_) {
          // disallow if both would be unchecked
          if (props.default_crossover_type_staple_for_setting_helix_rolls) {
            props.dispatch(actions.DefaultCrossoverTypeForSettingHelixRollsSet(
                scaffold: !props.default_crossover_type_scaffold_for_setting_helix_rolls,
                staple: props.default_crossover_type_staple_for_setting_helix_rolls));
          }
        })(),
      (MenuBoolean()
        ..value = props.default_crossover_type_staple_for_setting_helix_rolls
        ..display = 'default to leftmost staple crossover'
        ..tooltip = '''\
When selecting "Set helix coordinates based on crossovers", if two adjacent 
helices do not have a crossover selected, determines which types to select 
automatically.

If this is checked and "default to leftmost scaffold crossover" is unchecked,
then the leftmost staple crossover will be used.

If both are checked, the leftmost crossover of any type will be used.

Ignored if design is not an origami (i.e., does not have at least one scaffold).'''
        ..onChange = (_) {
          // disallow if both would be unchecked
          if (props.default_crossover_type_scaffold_for_setting_helix_rolls) {
            props.dispatch(actions.DefaultCrossoverTypeForSettingHelixRollsSet(
                scaffold: props.default_crossover_type_scaffold_for_setting_helix_rolls,
                staple: !props.default_crossover_type_staple_for_setting_helix_rolls));
          }
        })(),
      DropdownDivider({}),
    );
  }

  view_menu() {
    var elts = [
      ...view_menu_show_dna(),
      DropdownDivider({'key': 'divider-show-dna'}),
      ...view_menu_mods(),
      DropdownDivider({'key': 'divider-mods'}),
      ...view_menu_display_major_tick_offsets(),
      DropdownDivider({'key': 'divider-major-tick-offsets'}),
      ...view_menu_display_major_tick_widths(),
      DropdownDivider({'key': 'divider-major-tick-widths'}),
      ...view_menu_misc()
    ];
    return NavDropdown({
      'title': 'View',
      'id': 'view-nav-dropdown',
    }, elts);
  }

  List view_menu_show_dna() {
    return [
      (MenuBoolean()
        ..value = props.show_dna
        ..display = 'Show DNA Sequences'
        ..tooltip = '''\
Show DNA sequences that have been assigned to strands. In a large design, this
can slow down the performance of panning and zooming navigation, so uncheck it
to speed up navigation.'''
        ..onChange = ((_) => props.dispatch(actions.ShowDNASet(!props.show_dna)))
        ..key = 'show-dna-sequences')(),
      (MenuBoolean()
        ..value = props.show_mismatches
        ..display = 'Show DNA Base Mismatches'
        ..tooltip = '''\
Show mismatches between DNA assigned to one strand and the strand on the same
helix with the opposite orientation.'''
        ..onChange = (_) {
          props.dispatch(actions.ShowMismatchesSet(!props.show_mismatches));
        }
        ..key = 'show-mismatches')(),
    ];
  }

  List view_menu_mods() {
    return [
      (MenuBoolean()
        ..value = props.show_modifications
        ..display = 'Show Modifications'
        ..tooltip = 'Check to show DNA modifications (e.g., biotins, fluorophores).'
        ..onChange = ((_) => props.dispatch(actions.ShowModificationsSet(!props.show_modifications)))
        ..key = 'show-mods')(),
      (MenuBoolean()
        ..value = props.modification_display_connector
        ..hide = !props.show_modifications
        ..display = 'Display Modification Connector'
        ..tooltip = 'Check to display DNA modification connectors.'
        ..onChange = ((_) =>
            props.dispatch(actions.SetModificationDisplayConnector(!props.modification_display_connector)))
        ..key = 'display-mod-connector')(),
      (MenuNumber()
        ..display = 'Modification font size'
        ..default_value = props.modification_font_size
        ..hide = !props.show_modifications
        ..tooltip = 'Adjust to change the font size of text display for modifications.'
        ..on_new_value = ((num font_size) => props.dispatch(actions.ModificationFontSizeSet(font_size)))
        ..key = 'mod-font-size')(),
    ];
  }

  List view_menu_display_major_tick_offsets() {
    return [
      (MenuBoolean()
        ..value = props.display_of_major_ticks_offsets
        ..display = 'Display Major Tick Offsets'
        ..tooltip = 'Display the integer base offset to the right of each major tick, on the first helix.'
        ..onChange = ((_) =>
            props.dispatch(actions.DisplayMajorTicksOffsetsSet(!props.display_of_major_ticks_offsets)))
        ..key = 'display-major-tick-offsets')(),
      (MenuBoolean()
        ..value = !props.display_base_offsets_of_major_ticks_only_first_helix
        ..hide = !props.display_of_major_ticks_offsets
        ..display = '... On All Helices'
        ..tooltip = 'Display the integer base offset to the right of each major tick, for all helices.'
        ..onChange = ((_) => props.dispatch(actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(
            !props.display_base_offsets_of_major_ticks_only_first_helix)))
        ..key = 'display-major-tick-offsets-on-all-helices')(),
      (MenuNumber()
        ..display = 'Major tick offset font size'
        ..default_value = props.major_tick_offset_font_size
        ..hide = !props.display_of_major_ticks_offsets
        ..tooltip = 'Adjust to change the font size of major tick offsets.'
        ..on_new_value = ((num font_size) => props.dispatch(actions.MajorTickOffsetFontSizeSet(font_size)))
        ..key = 'major-tick-offset-font-size')(),
    ];
  }

  List view_menu_display_major_tick_widths() {
    return [
      (MenuBoolean()
        ..value = props.display_major_tick_widths
        ..display = 'Display Major Tick Widths'
        ..tooltip =
            'Display the number of bases between each adjacent pair of major ticks, on the first helix.'
        ..onChange =
            ((_) => props.dispatch(actions.SetDisplayMajorTickWidths(!props.display_major_tick_widths)))
        ..key = 'display-major-tick-widths')(),
      (MenuBoolean()
        ..value = props.display_major_tick_widths_all_helices
        ..hide = !props.display_major_tick_widths
        ..display = '...On All Helices'
        ..tooltip = 'Display the number of bases between each adjacent pair of major ticks, on all helices.'
        ..onChange = ((_) => props.dispatch(
            actions.SetDisplayMajorTickWidthsAllHelices(!props.display_major_tick_widths_all_helices)))
        ..key = 'display-major-tick-widths-on-all-helices')(),
      (MenuNumber()
        ..display = 'Major tick width font size'
        ..default_value = props.major_tick_width_font_size
        ..hide = !props.display_major_tick_widths
        ..tooltip = 'Adjust to change the font size of major tick offsets.'
        ..on_new_value = ((num font_size) => props.dispatch(actions.MajorTickWidthFontSizeSet(font_size)))
        ..key = 'major-tick-width-font-size')(),
    ];
  }

  List<ReactElement> view_menu_misc() {
    return [
      (MenuBoolean()
        ..value = props.autofit
        ..display = 'Auto-fit On Loading New Design'
        ..tooltip = '''\
When loading a new design, the side and main views will be translated to show 
the lowest-index helix in the upper-left. otherwise, after loading the design, 
you may not be able to see it because it is translated off the screen.

You may want to uncheck this when working on a design with the scripting 
library. In that case, when repeatedly re-running the script to modify the 
design and then re-loading it, it is preferable to keep the design centered 
at the same location you had before, in order to be able to see the same part 
of the design you were looking at before changing the script.'''
        ..name = 'center-on-load'
        ..onChange = ((_) => props.dispatch(actions.AutofitSet(autofit: !props.autofit)))
        ..key = 'autofit-on-loading-new-design')(),
      (MenuBoolean()
        ..value = props.only_display_selected_helices
        ..display = 'Display only selected helices'
        ..tooltip = 'Only helices selected in the side view are displayed in the main view.'
        ..name = 'display-only-selected-helices'
        ..onChange = ((_) =>
            props.dispatch(actions.SetOnlyDisplaySelectedHelices(!props.only_display_selected_helices)))
        ..key = 'display-only-selected-helices')(),
      (MenuBoolean()
        ..value = props.invert_yz
        ..display = 'Invert y- and z-axes'
        ..tooltip = '''\
In the main view, invert the y-axis, and in the side view, invert both the 
y-axis and the z-axis. 

If unchecked, then use "screen coordinates", where increasing y moves down. 

If checked, then use Cartesian coordinates where increasing y moves up. 
Also invert the z-axis to maintain chirality, so this has the net effect of 
rotating the side view by 180 degrees.'''
        ..name = 'invert-yz-axes'
        ..onChange = ((_) => props.dispatch(actions.InvertYZSet(invert_yz: !props.invert_yz)))
        ..key = 'invert-yz-axes')(),
      (MenuBoolean()
        ..value = props.show_helix_circles_main_view
        ..display = 'Show main view Helix circles/idx'
        ..tooltip = '''\
Shows helix circles and idx's in main view. You may want to hide them for
designs that have overlapping non-parallel helices.'''
        ..name = 'show-helix-circles-main-view'
        ..onChange = ((_) => props.dispatch(actions.ShowHelixCirclesMainViewSet(
            show_helix_circles_main_view: !props.show_helix_circles_main_view)))
        ..key = 'show-helix-circles-main-view')(),
      (MenuBoolean()
        ..value = props.show_grid_coordinates_side_view
        ..display = 'Show grid coordinates in side view'
        ..tooltip = '''\
Shows grid coordinates in the side view under the helix index.'''
        ..name = 'show-grid-coordinates-side-view'
        ..onChange = ((_) => props.dispatch(actions.ShowGridCoordinatesSideViewSet(
            show_grid_coordinates_side_view: !props.show_grid_coordinates_side_view)))
        ..key = 'show-grid-coordinates-side-view')(),
    ];
  }

  grid_menu() {
    return NavDropdown(
      {
        'title': 'Grid',
        'id': 'grid-nav-dropdown',
      },
      [
        for (var grid in Grid.values)
          DropdownItem(
            {
              'active': grid == props.grid,
              'disabled': grid == props.grid,
              'key': grid.toString(),
              'onClick': ((ev) => props.dispatch(actions.GridChange(grid: grid))),
            },
            grid.toString(),
          )
      ],
    );
  }

  export_menu() {
    return NavDropdown(
      {
        'title': 'Export',
        'id': 'export-nav-dropdown',
      },
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.side)))
        ..display = 'SVG Side View')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.main)))
        ..display = 'SVG Main View')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.disable_keyboard_shortcuts_while(export_dna))
        ..display = 'DNA Sequences')(),
    );
  }

  help_menu() {
    return NavDropdown(
      {
        'title': 'Help',
        'id': 'help-nav-dropdown',
      },
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano#readme',
          'target': '_blank',
        },
        'Web Interface Help',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/blob/master/tutorial/tutorial.md',
          'target': '_blank',
        },
        'Web Interface Tutorial',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package#readme',
          'target': '_blank',
        },
        'Python Scripting Help',
      ),
      DropdownItem(
        {
          'href':
              'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/tutorial/tutorial.md',
          'target': '_blank',
        },
        'Python Scripting Tutorial',
      ),
      DropdownItem(
        {
          'href': 'https://scadnano-python-package.readthedocs.io',
          'target': '_blank',
        },
        'Python Scripting API',
      ),
      DropdownItem(
        {
          'href': 'https://scadnano.org/dev',
          'target': '_blank',
          'title': '''\
Development version of scadnano, located at https://scadnano.org/dev.

This is updated more frequently than the main site at https://scadnano.org.

This includes open issues that have been handled in the dev branch but not the main branch:
https://github.com/UC-Davis-molecular-computing/scadnano/labels/closed%20in%20dev'''
        },
        'scadnano dev version',
      ),
    );
  }

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
        options: props.example_designs.filenames,
      ),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    int selected_idx = (results[0] as DialogRadio).selected_idx;
    props.dispatch(actions.ExampleDesignsLoad(selected_idx: selected_idx));
  }

  List<ReactElement> file_menu_save_design_local_storage_options() => [
        (MenuBoolean()
          ..value = props.local_storage_design_choice.option == LocalStorageDesignOption.on_edit
          ..display = 'Save design in localStorage on every edit'
          ..tooltip = '''\
On every edit, save current design in localStorage (in your web browser).

Disabling this minimizes the time needed to render large designs.'''
          ..onChange = ((_) => props.dispatch(
              actions.LocalStorageDesignChoiceSet(choice: props.local_storage_design_choice.to_on_edit())))
          ..key = 'save-dna-design-in-local-storage')(),
        (MenuBoolean()
          ..value = props.local_storage_design_choice.option == LocalStorageDesignOption.on_exit
          ..display = 'Save design in localStorage before exiting'
          ..tooltip = '''\
Before exiting, save current design in localStorage (in your web browser). 
This is much faster than saving on every edit, but if the browser crashes, 
all changes made will be lost, so it is not as safe as storing on every edit.'''
          ..onChange = ((_) => props.dispatch(
              actions.LocalStorageDesignChoiceSet(choice: props.local_storage_design_choice.to_on_exit())))
          ..key = 'save-dna-design-in-local-storage-on-exit')(),
        (MenuBoolean()
          ..value = props.local_storage_design_choice.option == LocalStorageDesignOption.never
          ..display = 'Do not save design in localStorage'
          ..tooltip = '''\
Never saves the design in localStorage.'''
          ..onChange = ((_) => props.dispatch(
              actions.LocalStorageDesignChoiceSet(choice: props.local_storage_design_choice.to_never())))
          ..key = 'never-save-dna-design-in-local-storage')(),
        (MenuBoolean()
          ..value = props.local_storage_design_choice.option == LocalStorageDesignOption.periodic
          ..display = 'Save design in localStorage periodically'
          ..tooltip = '''\
Every <period> seconds, save current design in localStorage (in your web browser). 
Also saves before exiting.
This is safer than never saving, or saving only before exiting, but will not save edits
that occurred between the last edit and a browser crash.'''
          ..onChange = ((_) => props.dispatch(
              actions.LocalStorageDesignChoiceSet(choice: props.local_storage_design_choice.to_periodic())))
          ..key = 'save-dna-design-in-local-storage-periodically')(),
        (MenuNumber()
          ..display = 'period (seconds)'
          ..min_value = 1
          ..default_value = props.local_storage_design_choice.period_seconds
          ..hide = props.local_storage_design_choice.option != LocalStorageDesignOption.periodic
          ..tooltip = 'Number of seconds between saving design to localStorage.'
          ..on_new_value = ((num period) => props.dispatch(actions.LocalStorageDesignChoiceSet(
              choice: LocalStorageDesignChoice(LocalStorageDesignOption.periodic, period))))
          ..key = 'period-of-save-dna-design-in-local-storage-periodically')(),
      ];
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
    filename = path.setExtension(filename, '.${constants.default_scadnano_file_extension}');
    app.dispatch(actions.LoadDNAFile(content: json_model_text, filename: filename));
  } else {
    Map response_body_json = jsonDecode(response.body);
    window.alert('Error importing file: ${response_body_json['error']}');
  }
}
