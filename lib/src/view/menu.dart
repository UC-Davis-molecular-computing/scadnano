import 'dart:convert';
import 'dart:html';
import 'package:built_collection/built_collection.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/dna_file_type.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/middleware/local_storage.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import '../state/dialog.dart';
import '../state/example_designs.dart';
import '../state/export_dna_format.dart';
import '../state/grid.dart';
import '../state/local_storage_design_choice.dart';
import '../view/menu_number.dart';
import '../view/redraw_counter_component_mixin.dart';
import '../view/react_bootstrap.dart';
import '../constants.dart' as constants;
import '../view/menu_boolean.dart';
import '../view/menu_dropdown_item.dart';
import '../view/menu_dropdown_right.dart';
import '../view/menu_form_file.dart';
import 'design.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

part 'menu.over_react.g.dart';

UiFactory<MenuProps> ConnectedMenu = connect<AppState, MenuProps>(
  mapStateToProps: (AppState state) {
    return (Menu()
      ..selected_ends = state.ui_state.selectables_store.selected_dna_ends
      ..geometry = state.design?.geometry
      ..no_grid_is_none =
          state.design == null ? false : state.design.groups.values.every((group) => group.grid != Grid.none)
      ..show_dna = state.ui_state.show_dna
      ..show_domain_names = state.ui_state.show_domain_names
      ..show_strand_names = state.ui_state.show_strand_names
      ..domain_name_font_size = state.ui_state.domain_name_font_size
      ..strand_name_font_size = state.ui_state.strand_name_font_size
      ..show_modifications = state.ui_state.show_modifications
      ..show_mismatches = state.ui_state.show_mismatches
      ..show_domain_name_mismatches = state.ui_state.show_domain_name_mismatches
      ..show_unpaired_insertion_deletions = state.ui_state.show_unpaired_insertion_deletions
      ..strand_paste_keep_color = state.ui_state.strand_paste_keep_color
      ..zoom_speed = state.ui_state.zoom_speed
      ..autofit = state.ui_state.autofit
      ..only_display_selected_helices = state.ui_state.only_display_selected_helices
//    ..grid = state.design?.grid
      ..example_designs = state.ui_state.example_designs
      ..design_has_insertions_or_deletions = state.design?.has_insertions_or_deletions == true
      ..undo_stack_empty = state.undo_redo.undo_stack.isEmpty
      ..redo_stack_empty = state.undo_redo.redo_stack.isEmpty
      ..enable_copy = app.state.ui_state.selectables_store.selected_strands.isNotEmpty
      ..modification_font_size = state.ui_state.modification_font_size
      ..major_tick_offset_font_size = state.ui_state.major_tick_offset_font_size
      ..major_tick_width_font_size = state.ui_state.major_tick_width_font_size
      ..modification_display_connector = state.ui_state.modification_display_connector
      ..display_of_major_ticks_offsets = state.ui_state.display_base_offsets_of_major_ticks
      ..display_base_offsets_of_major_ticks_only_first_helix =
          state.ui_state.display_base_offsets_of_major_ticks_only_first_helix
      ..display_major_tick_widths = state.ui_state.display_major_tick_widths
      ..display_major_tick_widths_all_helices = state.ui_state.display_major_tick_widths_all_helices
      ..invert_y = state.ui_state.invert_y
      ..show_helix_circles_main_view = state.ui_state.show_helix_circles_main_view
      ..show_helix_components_main_view = state.ui_state.show_helix_components_main_view
      ..warn_on_exit_if_unsaved = state.ui_state.warn_on_exit_if_unsaved
      ..show_grid_coordinates_side_view = state.ui_state.show_grid_coordinates_side_view
      ..show_helices_axis_arrows = state.ui_state.show_helices_axis_arrows
      ..show_loopout_extension_length = state.ui_state.show_loopout_extension_length
      ..show_slice_bar = state.ui_state.show_slice_bar
      ..show_mouseover_data = state.ui_state.show_mouseover_data
      ..local_storage_design_choice = state.ui_state.local_storage_design_choice
      ..clear_helix_selection_when_loading_new_design =
          state.ui_state.clear_helix_selection_when_loading_new_design
      ..default_crossover_type_scaffold_for_setting_helix_rolls =
          state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls
      ..default_crossover_type_staple_for_setting_helix_rolls =
          state.ui_state.default_crossover_type_staple_for_setting_helix_rolls
      ..undo_redo = state.undo_redo);
  },
  // Used for component test.
  forwardRef: true,
)(Menu);

UiFactory<MenuProps> Menu = _$Menu;

mixin MenuPropsMixin on UiProps {
  BuiltSet<DNAEnd> selected_ends;
  bool no_grid_is_none;
  bool show_dna;
  bool show_domain_names;
  bool show_strand_names;
  num domain_name_font_size;
  num strand_name_font_size;
  num zoom_speed;
  bool show_modifications;
  num modification_font_size;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool modification_display_connector;
  bool show_mismatches;
  bool show_domain_name_mismatches;
  bool show_unpaired_insertion_deletions;
  bool strand_paste_keep_color;
  bool autofit;
  bool only_display_selected_helices;
  ExampleDesigns example_designs;
  bool design_has_insertions_or_deletions;
  bool undo_stack_empty;
  bool redo_stack_empty;
  bool enable_copy;
  bool display_of_major_ticks_offsets;
  bool display_base_offsets_of_major_ticks_only_first_helix;
  bool display_major_tick_widths;
  bool display_major_tick_widths_all_helices;
  bool invert_y;
  bool warn_on_exit_if_unsaved;
  bool show_helix_circles_main_view;
  bool show_helix_components_main_view;
  bool show_grid_coordinates_side_view;
  bool show_helices_axis_arrows;
  bool show_loopout_extension_length;
  bool show_slice_bar;
  bool show_mouseover_data;
  bool default_crossover_type_scaffold_for_setting_helix_rolls;
  bool default_crossover_type_staple_for_setting_helix_rolls;
  LocalStorageDesignChoice local_storage_design_choice;
  bool clear_helix_selection_when_loading_new_design;
  Geometry geometry;
  UndoRedo undo_redo;
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
      export_menu(),
      help_menu(),
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// file menu

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
        ..display = '📂 Open'
        ..keyboard_shortcut = 'Ctrl+O'
        ..key = 'open-form-file')(),
      DropdownDivider({'key': 'divider-file-load'}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.SaveDNAFile()))
        ..display = '💾 Save'
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
      DropdownDivider({'key': 'divider-import-cadnano'}),
      (MenuDropdownItem()
        ..on_click = ((_) {
          bool reset = window.confirm('''\
WARNING! This will reset all local settings stored in your browser, 
including the current design.

Are you sure you want to continue?''');
          if (reset) {
            props.dispatch(actions.ResetLocalStorage());
          }
        })
        ..display = 'Reset local storage'
        ..tooltip = '''\
Clear the stored design, reset all local settings, and reload the page.'''
        ..key = 'reset-local-storage')(),
      file_menu_save_design_local_storage_options(),
      DropdownDivider({'key': 'divide-clear-helix-selection-when-loading-new-design'}),
      (MenuBoolean()
        ..value = props.clear_helix_selection_when_loading_new_design
        ..display = 'Clear helix selection when loading new design'
        ..onChange = ((_) => props.dispatch(actions.ClearHelixSelectionWhenLoadingNewDesignSet(
            clear: !props.clear_helix_selection_when_loading_new_design)))
        ..tooltip = '''\
If checked, the selected helices will be clear when loading a new design.
Otherwise, helix selection is not cleared, meaning that all the selected helices in the current
design will be selected (based on helix index) on the loaded design.'''
        ..key = 'clear-helix-selection-when-loading-new-design')(),
    ]);
  }

  ReactElement file_menu_save_design_local_storage_options() => (MenuDropdownRight()
        ..title = 'Local storage design save options'
        ..id = 'file_menu_local-storage-options'
        ..key = 'file_menu_local-storage-options'
        ..className = 'submenu_item')([
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
For large designs, this is faster than saving on every edit, but if the browser crashes, 
all changes made will be lost, so it is not as safe as storing on every edit.'''
          ..onChange = ((_) => props.dispatch(
              actions.LocalStorageDesignChoiceSet(choice: props.local_storage_design_choice.to_on_exit())))
          ..key = 'save-dna-design-in-local-storage-on-exit')(),
        (MenuBoolean()
          ..value = props.local_storage_design_choice.option == LocalStorageDesignOption.never
          ..display = 'Do not save design in localStorage'
          ..tooltip = '''\
Never saves the design in localStorage.

WARNING: you must save your design manually by pressing Ctrl+S or selecting 
File-->Save, or your design will be lost when you close the browser tab.'''
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
that occurred between the last save and a browser crash.'''
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
      ]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// edit menu

  edit_menu() {
    return NavDropdown(
      {
        'title': 'Edit',
        'id': 'edit-nav-dropdown',
      },
      ///////////////////////////////////////////////////////////////
      // cut/copy/paste
      (MenuDropdownRight()
        ..title = 'Undo'
        ..id = "edit_menu_undo-dropdown"
        ..disabled = props.undo_stack_empty)(undo_dropdowns),
      (MenuDropdownRight()
        ..title = 'Redo'
        ..id = "edit_menu_redo-dropdown"
        ..disabled = props.redo_stack_empty)(redo_dropdowns),
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
      (MenuDropdownItem()
        ..on_click = ((_) => paste_strands_auto())
        ..display = 'Autopaste'
        ..keyboard_shortcut = 'Ctrl+Shift+V')(),
      ///////////////////////////////////////////////////////////////
      // pasted strands keep original color
      DropdownDivider({}),
      (MenuBoolean()
        ..value = props.strand_paste_keep_color
        ..display = 'Pasted strands keep original color'
        ..tooltip = '''\
If checked, when copying and pasting a strand, the color is preserved.
If unchecked, then a new color is generated.'''
        ..onChange =
            ((_) => props.dispatch(actions.StrandPasteKeepColorSet(keep: !props.strand_paste_keep_color))))(),
      ///////////////////////////////////////////////////////////////
      // inline insertions/deletions
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.InlineInsertionsDeletions()))
        ..display = 'Inline insertions/deletions'
        ..disabled = !props.design_has_insertions_or_deletions
        ..tooltip = ''
            '''
Remove insertions and deletions from the design and replace them with domains
whose lengths correspond to the true strand length. Also moves major tick 
marks on helices so that they are adjacent to the same bases as before.''')(),
      ///////////////////////////////////////////////////////////////
      ///////////////////////////////////////////////////////////////
      // Connect selected ends by crossovers
      DropdownDivider({}),
      (MenuDropdownItem()
        // ..on_click = ((_) => connect_ends_by_crossovers(props.selected_ends))
        ..on_click = ((_) => props.dispatch(actions.JoinStrandsByMultipleCrossovers()))
        ..display = 'Connect selected ends by crossovers'
        ..disabled = props.selected_ends.isEmpty
        ..tooltip = ''
            '''Connect selected ends by crossovers. 

Ends are connected by crossovers as follows. Within each HelixGroup: 

Iterate over ends in the following order: first by helix, then by 
forward/reverse, then by offset. For each end e1 in this order, join it 
to the first end e2 after it in this order, if 
1) e1 and e2 have the same offset (making a "vertical" crossover), 
2) e1 is "above" e2 (lower helix idx; more generally earlier in helices_view_order), 
3) opposite direction (one is forward and the other reverse), and 
4) opposite side of a strand (i.e., one is 5' and the other 3').''')(),
      ///////////////////////////////////////////////////////////////
      // Set helix coordinates based on crossovers
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.HelicesPositionsSetBasedOnCrossovers()))
        ..display = 'Set helix coordinates based on crossovers'
        ..disabled = props.no_grid_is_none
        ..tooltip = '''\
The grid must be set to none to enable this.${props.no_grid_is_none ? " (Currently disabled since the grid is not none.)" : ""}

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
      ///////////////////////////////////////////////////////////////
      // Set geometric parameters
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => ask_for_geometry(props.geometry))
        ..display = 'Set geometric parameters'
        ..tooltip = '''\
Set geometric parameters affecting how the design is displayed.

- rise per base pair: This is the number of nanometers a single base pair occupies (i.e., width in main view)
                      default ${constants.default_rise_per_base_pair} nm

- helix radius:       The radius of a helix in nanometers.
                      default ${constants.default_helix_radius} nm

- inter-helix gap:    The distance between two adjacent helices. The value 2*helix_radius+inter_helix_gap
                      is the distance between the centers of two adjacent helices.
                      default ${constants.default_inter_helix_gap} nm

- bases per turn:     The number of bases in a single full turn of DNA.
                      default ${constants.default_bases_per_turn}

- minor groove angle: The angle in degrees of the minor groove, when looking at the helix in the direction
                      of its long axis.
                      default ${constants.default_minor_groove_angle} degrees''')(),
      ///////////////////////////////////////////////////////////////
      // autostaple/autobreak
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.Autostaple()))
        ..display = 'Autostaple (experimental)'
        ..tooltip = '''\
Removes all staple strands and puts long "precursor" staples everywhere the scaffold appears.
WARNING: this is an experimental feature and may be modified or removed. It uses cadnano code,
so will only work on scadnano designs that are exportable to cadnano.
        ''')(),
      (MenuDropdownItem()
        ..on_click = ((_) => ask_for_autobreak_parameters())
        ..display = 'Autobreak (experimental)'
        ..tooltip = '''\
Puts nicks in long staple strands automatically.
WARNING: Autobreak is an experimental feature and may be modified or removed.
It uses cadnano code that crashes on many designs, so it is not guaranteed to work properly. It will also only work on scadnano designs that are exportable to cadnano.
        ''')(),
    );
  }

  List<ReactElement> get undo_dropdowns {
    return undo_or_redo_dropdowns((i) => actions.Undo(i), props.undo_redo.undo_stack, "Undo");
  }

  List<ReactElement> get redo_dropdowns {
    return undo_or_redo_dropdowns((i) => actions.Redo(i), props.undo_redo.redo_stack, "Redo");
  }

  List<ReactElement> undo_or_redo_dropdowns(ActionFromIntCreator undo_or_redo_action_creator,
      BuiltList<UndoRedoItem> undo_or_redo_stack, String action_name) {
    List<ReactElement> dropdowns = [];
    int num_times = 1;
    bool most_recent = true;
    for (var item in undo_or_redo_stack.reversed) {
      dropdowns
          .add(undo_or_redo_dropdown(item, undo_or_redo_action_creator, num_times, action_name, most_recent));
      num_times += 1;
      most_recent = false;
    }
    return dropdowns;
  }

  ReactElement undo_or_redo_dropdown(UndoRedoItem item, ActionFromIntCreator undo_or_redo_action_creator,
      int num_times, String action_name, bool is_most_recent) {
    String most_recent_string = is_most_recent ? " [Most Recent]" : "";
    return (MenuDropdownItem()
      ..display = '${action_name} ${item.short_description}${most_recent_string}'
      ..key = '${action_name.toLowerCase()}-${num_times}'
      ..on_click = (_) => app.dispatch(undo_or_redo_action_creator(num_times)))();
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// view menu

  view_menu() {
    var elts = [
      view_menu_warnings(),
      // view_menu_show_dna(),
      view_menu_autofit(),
      view_menu_show_labels(),
      view_menu_mods(),
      view_menu_helices(),
      view_menu_display_major_ticks_options(),
      DropdownDivider({'key': 'divider-major-tick-widths'}),
      ...view_menu_zoom_speed(),
      DropdownDivider({'key': 'divider-zoom_speed'}),
      ...view_menu_misc()
    ];
    return NavDropdown({
      'title': 'View',
      'id': 'view-nav-dropdown',
    }, elts);
  }

  ReactElement view_menu_autofit() {
    return (MenuDropdownRight()
      ..title = 'Autofit'
      ..id = 'view_menu_autofit-dropdown'
      ..key = 'view_menu_autofit-dropdown'
      ..className = 'submenu-item')([
      (MenuDropdownItem()
        ..display = 'Auto-fit current design'
        ..tooltip = '''\
The side and main views will be translated to fit the current design in the window.
'''
        ..on_click = (_) {
          util.fit_and_center();
          util.dispatch_set_zoom_threshold(true);
        }
        ..key = 'autofit-current-design')(),
      (MenuBoolean()
        ..value = props.autofit
        ..display = 'Auto-fit on loading new design'
        ..tooltip = '''\
The side and main views will be translated to fit the current design in the window
whenever loading a new design. Otherwise, after loading the design, you may not 
be able to see it because it is translated off the screen in the current translation.

You may want to uncheck this when working on a design with the scripting 
library. In that case, when repeatedly re-running the script to modify the 
design and then re-loading it, it is preferable to keep the design centered 
at the same location you had before, in order to be able to see the same part 
of the design you were looking at before changing the script.

To autofit the current design without reloading, click "Auto-fit current design".'''
        ..name = 'center-on-load'
        ..onChange = ((_) => props.dispatch(actions.AutofitSet(autofit: !props.autofit)))
        ..key = 'autofit-on-loading-new-design')(),
    ]);
  }

  ReactElement view_menu_warnings() {
    return (MenuDropdownRight()
      ..title = 'Warnings'
      ..id = 'view_menu_show_warnings'
      ..key = 'view_menu_show_warnings'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.show_mismatches
        ..display = 'Show DNA base mismatches'
        ..tooltip = '''\
Show mismatches between DNA assigned to one strand and the strand on the same
helix with the opposite orientation.'''
        ..onChange = (_) {
          props.dispatch(actions.ShowMismatchesSet(!props.show_mismatches));
        }
        ..key = 'show-mismatches')(),
      (MenuBoolean()
        ..value = props.show_domain_name_mismatches
        ..display = 'Show domain name mismatches'
        ..tooltip = '''\
Show mismatches between domain names assigned to one strand and the strand on the same
helix with the opposite orientation.'''
        ..onChange = (_) {
          props.dispatch(actions.ShowDomainNameMismatchesSet(!props.show_domain_name_mismatches));
        }
        ..key = 'show-domain-name-mismatches')(),
      (MenuBoolean()
        ..value = props.show_unpaired_insertion_deletions
        ..display = 'Show unpaired insertion/deletions'
        ..tooltip = '''\
Show unpaired deletions and insertions. This is defined to be an insertion/deletion on
a strand, where another strand is at the same (helix,offset) (in the opposite direction),
which lacks the insertion/deletion. It does NOT show a warning if there is no other
strand at the same (helix,offset).'''
        ..onChange = (_) {
          props.dispatch(actions.ShowUnpairedInsertionDeletionsSet(!props.show_unpaired_insertion_deletions));
        }
        ..key = 'show-unpaired-insertion-deletions')(),
    ]);
  }

//   ReactElement view_menu_show_dna() {
//     return (MenuDropdownRight()
//       ..title = 'DNA sequences'
//       ..id = 'view_menu_show_dna-dropdown'
//       ..key = 'view_menu_show_dna-dropdown'
//       ..className = 'submenu_item')([
//       (MenuBoolean()
//         ..value = props.show_dna
//         ..display = 'Show DNA sequences'
//         ..tooltip = '''\
// Show DNA sequences that have been assigned to strands. In a large design, this
// can slow down the performance of panning and zooming navigation, so uncheck it
// to speed up navigation.'''
//         ..onChange = ((_) => props.dispatch(actions.ShowDNASet(!props.show_dna)))
//         ..key = 'show-dna-sequences')(),
//     ]);
//   }

  ReactElement view_menu_show_labels() {
    return (MenuDropdownRight()
      ..title = 'Strand/domain names'
      ..id = 'view_menu_show_labels-dropdown'
      ..key = 'view_menu_show_labels-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.show_strand_names
        ..display = 'Show strand names'
        ..tooltip = "Show strand names near 5' domain of strand."
        ..onChange = ((_) => props.dispatch(actions.ShowStrandNamesSet(!props.show_strand_names)))
        ..key = 'show-strand-name')(),
      (MenuNumber()
        ..display = 'strand name font size'
        ..default_value = props.strand_name_font_size
        ..hide = !props.show_strand_names
        ..tooltip = 'Adjust to change the font size of strand name.'
        ..on_new_value =
            ((num font_size) => props.dispatch(actions.StrandNameFontSizeSet(font_size: font_size)))
        ..key = 'strand-name-font-size')(),
      (MenuBoolean()
        ..value = props.show_domain_names
        ..display = 'Show domain names'
        ..tooltip = 'Show domain and loopout names.'
        ..onChange = ((_) => props.dispatch(actions.ShowDomainNamesSet(!props.show_domain_names)))
        ..key = 'show-domain-name')(),
      (MenuNumber()
        ..display = 'domain name font size'
        ..default_value = props.domain_name_font_size
        ..hide = !props.show_domain_names
        ..tooltip = 'Adjust to change the font size of domain and loopout name.'
        ..on_new_value =
            ((num font_size) => props.dispatch(actions.DomainNameFontSizeSet(font_size: font_size)))
        ..key = 'domain-name-font-size')(),
    ]);
  }

  ReactElement view_menu_mods() {
    return (MenuDropdownRight()
      ..title = 'Modifications'
      ..id = 'view_menu_mods-dropdown'
      ..key = 'view_menu_mods-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.show_modifications
        ..display = 'Show modifications'
        ..tooltip = 'Check to show DNA modifications (e.g., biotins, fluorophores).'
        ..onChange = ((_) => props.dispatch(actions.ShowModificationsSet(!props.show_modifications)))
        ..key = 'show-mods')(),
      (MenuBoolean()
        ..value = props.modification_display_connector
        ..hide = !props.show_modifications
        ..display = 'Display modification connector'
        ..tooltip = """\
Check to display DNA modification "connectors", short lines that connect 
the 5'/3' end, or DNA base (for internal modifications), to the modification. 
This is useful to keep the modification from visually obstructing the design.
If this is unchecked, then the modification is displayed directly on top of 
the 5'/3' end or the base. This is useful for visualizing the exact position
of the modifications, e.g., to see where a pattern of biotins will appear on
the surface of a DNA origami."""
        ..onChange = ((_) =>
            props.dispatch(actions.SetModificationDisplayConnector(!props.modification_display_connector)))
        ..key = 'display-mod-connector')(),
      (MenuNumber()
        ..display = 'Modification font size'
        ..default_value = props.modification_font_size
        ..hide = !props.show_modifications
        ..tooltip = 'Adjust the font size of modification text representation.'
        ..on_new_value = ((num font_size) => props.dispatch(actions.ModificationFontSizeSet(font_size)))
        ..key = 'mod-font-size')(),
    ]);
  }

  ReactElement view_menu_helices() {
    return (MenuDropdownRight()
      ..title = 'Helices'
      ..id = 'view_menu_helices-dropdown'
      ..key = 'view_menu_helices-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.only_display_selected_helices
        ..display = 'Display only selected helices'
        ..tooltip = 'Only helices selected in the side view are displayed in the main view.'
        ..name = 'display-only-selected-helices'
        ..onChange = ((_) =>
            props.dispatch(actions.SetOnlyDisplaySelectedHelices(!props.only_display_selected_helices)))
        ..key = 'display-only-selected-helices')(),
      (MenuBoolean()
        ..value = props.show_helix_components_main_view
        ..display = 'Show main view helices'
        ..tooltip = '''\
Shows helix representation in main view. Hiding them hides all view elements 
associated with a helix: grid lines depicting offsets, circles with helix index,
major tick offsets.'''
        ..name = 'show-helix-components-main-view'
        ..onChange = ((_) => props.dispatch(actions.ShowHelixComponentsMainViewSet(
            show_helix_components: !props.show_helix_components_main_view)))
        ..key = 'show-helix-components-main-view')(),
      (MenuBoolean()
        ..value = props.show_helix_circles_main_view
        ..display = 'Show main view helix circles/idx'
        ..tooltip = '''\
Shows helix circles and idx's in main view. You may want to hide them for
designs that have overlapping non-parallel helices.

To hide all view elements associated with helices (e.g., major ticks),
toggle "Show main view helices".'''
        ..name = 'show-helix-circles-main-view'
        ..onChange = ((_) => props.dispatch(actions.ShowHelixCirclesMainViewSet(
            show_helix_circles_main_view: !props.show_helix_circles_main_view)))
        ..key = 'show-helix-circles-main-view')(),
    ]);
  }

  ReactElement view_menu_display_major_ticks_options() {
    return (MenuDropdownRight()
      ..title = 'Major ticks'
      ..id = 'view_menu_display_major_tick_offsets-dropdown'
      ..key = 'view_menu_display_major_tick_offsets-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.display_of_major_ticks_offsets
        ..display = 'Display major tick offsets'
        ..tooltip = 'Display the integer base offset to the right of each major tick, on the first helix.'
        ..onChange = ((_) =>
            props.dispatch(actions.DisplayMajorTicksOffsetsSet(!props.display_of_major_ticks_offsets)))
        ..key = 'display-major-tick-offsets')(),
      (MenuBoolean()
        ..value = !props.display_base_offsets_of_major_ticks_only_first_helix
        ..hide = !props.display_of_major_ticks_offsets
        ..display = '... on all helices'
        ..tooltip = 'Display the integer base offset to the right of each major tick, for all helices.'
        ..onChange = ((_) => props.dispatch(actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(
            !props.display_base_offsets_of_major_ticks_only_first_helix)))
        ..key = 'display-major-tick-offsets-on-all-helices')(),
      (MenuNumber()
        ..display = 'major tick offset font size'
        ..default_value = props.major_tick_offset_font_size
        ..hide = !props.display_of_major_ticks_offsets
        ..tooltip = 'Adjust to change the font size of major tick offsets.'
        ..on_new_value = ((num font_size) => props.dispatch(actions.MajorTickOffsetFontSizeSet(font_size)))
        ..key = 'major-tick-offset-font-size')(),
      DropdownDivider({'key': 'divider-major-tick-offset-from-width'}),
      (MenuBoolean()
        ..value = props.display_major_tick_widths
        ..display = 'Display major tick widths'
        ..tooltip =
            'Display the number of bases between each adjacent pair of major ticks, on the first helix.'
        ..onChange =
            ((_) => props.dispatch(actions.SetDisplayMajorTickWidths(!props.display_major_tick_widths)))
        ..key = 'display-major-tick-widths')(),
      (MenuBoolean()
        ..value = props.display_major_tick_widths_all_helices
        ..hide = !props.display_major_tick_widths
        ..display = '...on all helices'
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
    ]);
  }

  List<ReactElement> view_menu_zoom_speed() {
    return [
      (MenuNumber()
        ..display = 'Zoom speed'
        ..default_value = props.zoom_speed
        ..min_value = 0
        ..step = 0.05
        ..tooltip = 'The speed at which the mouse wheel or two-finger scroll zooms the view in and out.'
        ..on_new_value = ((num new_zoom_speed) => props.dispatch(actions.ZoomSpeedSet(speed: new_zoom_speed)))
        ..key = 'zoom-speed')(),
    ];
  }

  List<ReactElement> view_menu_misc() {
    return [
      (MenuBoolean()
        ..value = props.show_dna
        ..display = 'Show DNA sequences'
        ..tooltip = '''\
Show DNA sequences that have been assigned to strands. In a large design, this
can slow down the performance of panning and zooming navigation, so uncheck it
to speed up navigation.'''
        ..onChange = ((_) => props.dispatch(actions.ShowDNASet(!props.show_dna)))
        ..key = 'show-dna-sequences')(),
      (MenuBoolean()
        ..value = props.invert_y
        ..display = 'Invert y-axis'
        ..tooltip = '''\
Invert the y-axis by rotating 180 degrees about the z-axis (within the x/y plane).

If unchecked, then use "screen coordinates", where increasing y moves down. 

If checked, then use Cartesian coordinates where increasing y moves up.

To inspect how all axes change, check View --> Show axis arrows.'''
        ..name = 'invert-y-axis'
        ..onChange = ((_) => props.dispatch(actions.InvertYSet(invert_y: !props.invert_y)))
        ..key = 'invert-y-axis')(),
      (MenuBoolean()
        ..value = props.show_grid_coordinates_side_view
        ..display = 'Show grid coordinates in side view'
        ..tooltip = '''\
Shows grid coordinates in the side view under the helix index.'''
        ..name = 'show-grid-coordinates-side-view'
        ..onChange = ((_) => props.dispatch(actions.ShowGridCoordinatesSideViewSet(
            show_grid_coordinates_side_view: !props.show_grid_coordinates_side_view)))
        ..key = 'show-grid-coordinates-side-view')(),
      (MenuBoolean()
        ..value = props.show_helices_axis_arrows
        ..display = 'Show axis arrows'
        ..tooltip = '''\
Show axis arrows in side and main view
Red : X-axis
Green : Y-axis
Blue : Z-axis'''
        ..name = 'show-helices-axis-arrows'
        ..onChange = ((_) => props
            .dispatch(actions.ShowAxisArrowsSet(show_helices_axis_arrows: !props.show_helices_axis_arrows)))
        ..key = 'show-helices-axis-arrows')(),
      (MenuBoolean()
        ..value = props.show_loopout_extension_length
        ..display = 'Show loopout/extension lengths'
        ..tooltip = '''\
When selected, the length of each loopout and extension is displayed next to it.'''
        ..name = 'show-loopout-extension-length'
        ..onChange = ((_) => props.dispatch(
            actions.ShowLoopoutExtensionLengthSet(show_length: !props.show_loopout_extension_length)))
        ..key = 'show-loopout-extension-length')(),
      (MenuBoolean()
        ..value = props.show_slice_bar
        ..display = 'Show slice bar'
        ..tooltip = '''\
When selected, a slicebar is displayed, which users can drag and move to
display the DNA backbone angle of all helices at a particular offset.
        '''
        ..name = 'show-slice-bar'
        ..onChange = (_) {
          props.dispatch(actions.ShowSliceBarSet(!props.show_slice_bar));
        }
        ..key = 'show-slice-bar')(),
      (MenuBoolean()
        ..value = props.show_mouseover_data
        ..display = 'Display strand and helix details in footer'
        ..tooltip = '''\
When selected, the footer will display details about the design based
on where the cursor is located. If the cursor is on a helix, the helix
index and cursor's base offset location is displayed. If the cursor is
on a strand, then the strand details will also be displayed.

In a large design, this can slow down the performance, so uncheck it when not in use.
        '''
        ..name = 'show-mouseover-data'
        ..onChange = (_) {
          props.dispatch(actions.ShowMouseoverDataSet(!props.show_mouseover_data));
        }
        ..key = 'show-mouseover-data')()
    ];
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// export menu

  export_menu() {
    return NavDropdown(
      {
        'title': 'Export',
        'id': 'export-nav-dropdown',
      },
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.side)))
        ..tooltip = "Export SVG figure of side view (cross-section of helices on the left side of screen)."
        ..display = 'SVG side view')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportSvg(type: actions.ExportSvgType.main)))
        ..tooltip = "Export SVG figure of main view (design shown in center of screen)."
        ..display = 'SVG main view')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.disable_keyboard_shortcuts_while(export_dna))
        ..tooltip = "Export DNA sequences of strands to a file."
        ..display = 'DNA sequences')(),
      DropdownDivider({'key': 'divider-not-full-design'}),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportCadnanoFile(whitespace: true)))
        ..tooltip = "Export design to cadnano (version 2) .json file."
        ..display = 'cadnano v2'
        ..key = 'export-cadnano')(),
      DropdownItem(
        {
          'href': 'https://scadnano-python-package.readthedocs.io/en/latest/#interoperability-cadnano-v2',
          'target': '_blank',
          'title': """\
Read constraints that the scadnano design must obey to exportable to cadnano v2.
The constraints are the same for the scadnano Python package (described at the 
linked page) as for the web interface.
"""
        },
        'cadnano v2 export instructions',
      ),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.ExportCadnanoFile(whitespace: false)))
        ..tooltip = """\
Export design to cadnano (version 2) .json file with no whitespace or newlines.
This is necessary to use the cadnano file with CanDo, which causes a confusing error 
cadnano files that have whitespace. ("Bad .json file format is detected in 
'structure.json'. Or no dsDNA or strand crossovers exist.")"""
        ..display = 'cadnano v2 no whitespace'
        ..key = 'export-cadnano-no-whitespace')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.OxdnaExport()))
        ..tooltip = "Export design to oxDNA .dat and .top files, which can be loaded in oxDNA or oxView."
        ..display = 'oxDNA'
        ..key = 'export-oxdna')(),
      (MenuDropdownItem()
        ..on_click = ((_) => props.dispatch(actions.OxdnaExport(selected_strands_only: true)))
        ..tooltip = "Export design to oxDNA .dat and .top files, which can be loaded in oxDNA or oxView.\n"
            "Only exports the currently selected strands."
        ..display = 'oxDNA (selected strands)'
        ..key = 'export-oxdna-selected-strands')(),
      //TODO: figure out if ENSnano is close to codenano format; if so this might work for exporting to it.
      // (MenuDropdownItem()
      //   ..on_click = ((_) => props.dispatch(actions.ExportCodenanoFile()))
      //   ..tooltip = "Export design to codenano format."
      //   ..display = 'codenano'
      //   ..key = 'export-codenano')(),
    );
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// help menu

  help_menu() {
    List<ReactElement> version_dropdown_items = [];
    bool first = true;
    for (var version in constants.scadnano_versions_to_link) {
      var version_dropdown_item = DropdownItem(
        {
          'href': 'https://scadnano.org/v${version}/index.html',
          'target': '_blank',
          'key': version,
          'title': '''\
    Version v${version} of scadnano, located at https://scadnano.org/v${version}/index.html.'''
        },
        'v${version}' + (first ? ' (current version)' : ''),
      );
      first = false;
      version_dropdown_items.add(version_dropdown_item);
    }

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
        'help (web interface)',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/blob/master/tutorial/tutorial.md',
          'target': '_blank',
        },
        'tutorial (web interface)',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package#readme',
          'target': '_blank',
        },
        'help (Python scripting)',
      ),
      DropdownItem(
        {
          'href':
              'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/tutorial/tutorial.md',
          'target': '_blank',
        },
        'tutorial (Python scripting)',
      ),
      DropdownItem(
        {
          'href': 'https://scadnano-python-package.readthedocs.io',
          'target': '_blank',
        },
        'Python scripting API',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/issues',
          'target': '_blank',
          'title': '''\
To file a bug report or feature request for the scadnano web interface, 
click on "New issue" on the top right of the Issues page on at the 
scadnano Github repository.

If it is a bug report, please include as much detailed information as 
possible, including screenshots if applicable, and a copy of the .sc file 
that caused the error, and an exact description of the steps needed to
help us reproduce the error.

Note that you cannot upload a .sc file directly to GitHub, but if you put 
the .sc file in a .zip file, then it can be uploaded.'''
        },
        'Bug report/feature request (web interface)',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/issues',
          'target': '_blank',
          'title': '''\
To file a bug report or feature request for the Python scripting library, 
click on "New issue" on the top right of the Issues page on at the 
scadnano-python-package Github repository.

If it is a bug report, please include as much detailed information as 
possible, including a copy of the .sc file that caused the error, and an 
exact description of the steps needed to help us reproduce the error.

Note that you cannot upload a .sc file directly to GitHub, but if you put 
the .sc file in a .zip file, then it can be uploaded.'''
        },
        'Bug report/feature request (Python scripting)',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/releases',
          'target': '_blank',
        },
        'Release notes (web interface)',
      ),
      DropdownItem(
        {
          'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/releases',
          'target': '_blank',
        },
        'Release notes (Python scripting)',
      ),
      // older_versions_link_dropdown,
      (MenuDropdownRight()
        ..title = "Other versions"
        ..id = "older-version-dropdown"
        ..disallow_overflow = true
        ..tooltip = '''\
Older versions of scadnano, as well as the newest development version.

Starting from v0.12.1, every released (master branch) version of scadnano 
is deployed to https://scadnano.org/{version}. 

https://scadnano.org/dev is the newest version, containing newer features 
(those marked "closed in dev" on the scadnano issues page: 
https://github.com/UC-Davis-molecular-computing/scadnano/issues), 
but it may be less stable than the current version.''')([
        DropdownItem(
          {
            'href': 'https://scadnano.org/dev',
            'target': '_blank',
            'key': 'dev',
            'title': '''\
Development version of scadnano, located at https://scadnano.org/dev.

This site is updated more frequently than the main site at https://scadnano.org.

This includes open issues that have been handled in the dev branch but not the main branch:
https://github.com/UC-Davis-molecular-computing/scadnano/labels/closed%20in%20dev

However, it may be less stable than the main site.'''
          },
          'dev',
        ),
        version_dropdown_items
      ]),
      (MenuDropdownItem()
        ..on_click = ((_) => window.alert(''
            'scadnano is a program for designing synthetic DNA structures such as DNA origami. '
            '\n\nscadnano is a standalone project developed and maintained by the UC Davis Molecular Computing group. '
            'Though similar in design, scadnano is distinct from cadnano (https://cadnano.org), '
            'which is developed and maintained by the Douglas lab (https://bionano.ucsf.edu/) at UCSF.'))
        ..display = 'About')(),
//       DropdownItem(
//         {
//           'href':
//           'https://github.com/UC-Davis-molecular-computing/scadnano/releases',
//           'target': '_blank',
//           //TODO: figure out how to give a DropdownItem a tooltip
// //          'title': 'Only a valid link on the main site scadnano.org, not on scadnano.org/dev'
//         },
//         'About',
//       ),
    );
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// helper methods

  Future<void> export_dna() async {
    List<String> export_options = ExportDNAFormat.values.map((v) => v.toString()).toList();
    List<String> sort_options = StrandOrder.values.map((v) => v.toString()).toList();

    int idx_include_scaffold = 0;
    int idx_include_only_selected_strands = 1;
    int idx_format_str = 2;
    int idx_sort = 3;
    int idx_column_major = 4;
    int idx_strand_order_str = 5;

    List<DialogItem> items = [null, null, null, null, null, null];
    items[idx_include_scaffold] = DialogCheckbox(label: 'include scaffold', value: false);
    items[idx_include_only_selected_strands] =
        DialogCheckbox(label: 'include only selected strands', value: false);
    items[idx_format_str] = DialogRadio(label: 'designs', options: export_options);
    items[idx_sort] = DialogCheckbox(label: 'sort strands', value: false);
    items[idx_column_major] =
        DialogCheckbox(label: 'column-major order (uncheck for row-major order)', value: true);
    items[idx_strand_order_str] = DialogRadio(label: 'strand part to sort by', options: sort_options);

    var dialog = Dialog(title: 'export DNA sequences', items: items, disable_when_any_checkboxes_off: {
      idx_column_major: [idx_sort],
      idx_strand_order_str: [idx_sort]
    });

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    bool include_scaffold = (results[idx_include_scaffold] as DialogCheckbox).value;
    bool include_only_selected_strands = (results[idx_include_only_selected_strands] as DialogCheckbox).value;
    String format_str = (results[idx_format_str] as DialogRadio).value;
    bool sort = (results[idx_sort] as DialogCheckbox).value;
    StrandOrder strand_order = null;
    bool column_major = true;
    if (sort) {
      column_major = (results[idx_column_major] as DialogCheckbox).value;
      String strand_order_str = (results[idx_strand_order_str] as DialogRadio).value;
      strand_order = StrandOrder.fromString(strand_order_str);
    }
    ExportDNAFormat format = ExportDNAFormat.fromString(format_str);

    props.dispatch(actions.ExportDNA(
        include_scaffold: include_scaffold,
        include_only_selected_strands: include_only_selected_strands,
        export_dna_format: format,
        strand_order: strand_order,
        column_major: column_major));
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
}

typedef ActionFromIntCreator = actions.Action Function(int);

Future<void> ask_for_autobreak_parameters() async {
  var items = List<DialogItem>.filled(4, null);
  int target_length_idx = 0;
  int min_length_idx = 1;
  int max_length_idx = 2;
  int min_distance_to_xover_idx = 3;
  items[target_length_idx] = DialogInteger(label: 'target length', value: 49);
  items[min_length_idx] = DialogInteger(label: 'min length', value: 15);
  items[max_length_idx] = DialogInteger(label: 'max length', value: 60);
  items[min_distance_to_xover_idx] = DialogInteger(label: 'min distance to xover', value: 3);

  var dialog = Dialog(title: 'Choose autobreak parameters', type: DialogType.choose_autobreak_parameters, items: items);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  int target_length = (results[target_length_idx] as DialogInteger).value;
  int min_length = (results[min_length_idx] as DialogInteger).value;
  int max_length = (results[max_length_idx] as DialogInteger).value;
  int min_distance_to_xover = (results[min_distance_to_xover_idx] as DialogInteger).value;

  app.dispatch(actions.Autobreak(
      target_length: target_length,
      min_length: min_length,
      max_length: max_length,
      min_distance_to_xover: min_distance_to_xover));
}

Future<void> ask_for_geometry(Geometry geometry) async {
  int rise_per_base_pair_idx = 0;
  int helix_radius_idx = 1;
  int inter_helix_gap_idx = 2;
  int bases_per_turn_idx = 3;
  int minor_groove_angle_idx = 4;

  var items = List<DialogItem>.filled(5, null);
  items[rise_per_base_pair_idx] =
      DialogFloat(label: 'rise per base pair (nm)', value: geometry.rise_per_base_pair);
  items[helix_radius_idx] = DialogFloat(label: 'helix radius (nm)', value: geometry.helix_radius);
  items[inter_helix_gap_idx] = DialogFloat(label: 'inter helix gap (nm)', value: geometry.inter_helix_gap);
  items[bases_per_turn_idx] = DialogFloat(label: 'bases per turn', value: geometry.bases_per_turn);
  items[minor_groove_angle_idx] =
      DialogFloat(label: 'minor groove angle (degrees)', value: geometry.minor_groove_angle);

  var dialog = Dialog(title: 'adjust geometric parameters', type: DialogType.adjust_geometric_parameters, items: items);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  double rise_per_base_pair = (results[rise_per_base_pair_idx] as DialogFloat).value;
  double helix_radius = (results[helix_radius_idx] as DialogFloat).value;
  double inter_helix_gap = (results[inter_helix_gap_idx] as DialogFloat).value;
  double bases_per_turn = (results[bases_per_turn_idx] as DialogFloat).value;
  double minor_groove_angle = (results[minor_groove_angle_idx] as DialogFloat).value;

  var new_geometry = Geometry(
    rise_per_base_pair: rise_per_base_pair,
    helix_radius: helix_radius,
    inter_helix_gap: inter_helix_gap,
    bases_per_turn: bases_per_turn,
    minor_groove_angle: minor_groove_angle,
  );
  app.dispatch(actions.GeometrySet(geometry: new_geometry));
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
  app.dispatch(actions.PrepareToLoadDNAFile(content: json_model_text, filename: filename));
}

cadnano_file_loaded(FileReader file_reader, String filename) async {
  try {
    var json_cadnano_text = file_reader.result;
    filename = path.setExtension(filename, '.${constants.default_scadnano_file_extension}');
    app.dispatch(actions.PrepareToLoadDNAFile(
        content: json_cadnano_text, filename: filename, dna_file_type: DNAFileType.cadnano_file));
  } on Exception catch (e) {
    window.alert('Error importing file: ${e}');
  }
}
