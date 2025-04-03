import 'dart:convert';
import 'dart:html';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as path;
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/base_pair_display_type.dart';

import 'react_bootstrap.dart';

import '../dna_file_type.dart';
import '../json_serializable.dart';
import '../middleware/local_storage.dart';
import '../middleware/system_clipboard.dart';
import '../state/selectable.dart';
import '../state/design.dart';
import '../state/dna_end.dart';
import '../state/export_dna_format_strand_order.dart';
import '../state/geometry.dart';
import '../state/undo_redo.dart';
import '../middleware/export_dna_sequences.dart' as export_dna_sequences;
import '../state/dialog.dart';
import '../state/example_designs.dart';
import '../state/export_dna_format.dart';
import '../state/grid.dart';
import '../state/local_storage_design_choice.dart';
import '../view/menu_number.dart';
import '../view/redraw_counter_component_mixin.dart';
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

MenuProps set_menu_props(MenuProps elt, AppState state) => elt..state = state;

UiFactory<MenuProps> ConnectedMenu = connect<AppState, MenuProps>(
  mapStateToProps: (AppState state) => set_menu_props(Menu(), state),
  // Used for component test.
  forwardRef: true,
)(Menu);

UiFactory<MenuProps> Menu = _$Menu;

mixin MenuProps on UiProps {
  late AppState state;
}

class MenuComponent extends UiComponent2<MenuProps> {
  bool get enable_copy => props.state.ui_state.selectables_store.selected_strands.isNotEmpty;

  bool get no_grid_is_none =>
      props.state.maybe_design == null
          ? false
          : props.state.design.groups.values.every((group) => group.grid != Grid.none);

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
      {'bg': 'light', 'expand': 'lg'},
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
        },
      },
      'Dummy',
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // file menu

  file_menu() {
    return NavDropdown(
      {'title': 'File', 'id': 'file-nav-dropdown'},
      [
        (MenuDropdownItem()
          ..on_click = ((_) => app.disable_keyboard_shortcuts_while(load_example_dialog))
          ..display = '📄 Load example'
          ..key = 'load-example')(),
        (MenuFormFile()
          ..id_ = 'open-form-file'
          ..accept = constants.all_scadnano_file_extensions.map((ext) => '.' + ext).join(",")
          ..on_change = ((e) => request_load_file_from_file_chooser(e.target, scadnano_file_loaded))
          ..display = '📂 Open'
          ..keyboard_shortcut = 'Ctrl+O'
          ..key = 'open-form-file')(),
        DropdownDivider({'key': 'divider-file-load'}),
        (MenuDropdownItem()
          ..on_click = ((_) => app.dispatch(actions.SaveDNAFile()))
          ..display = '💾 Save'
          ..keyboard_shortcut = 'Ctrl+S'
          ..key = 'save-file')(),
        (MenuBoolean()
          ..value = props.state.ui_state.warn_on_exit_if_unsaved
          ..display = 'Warn on exit if unsaved'
          ..tooltip = '''\
If checked, before attempting to close or refresh the page, if the design has 
changed since it was last saved, a warning dialog is displayed to ask if you
really want to exit without saving.'''
          ..on_change =
              ((_) => app.dispatch(
                actions.WarnOnExitIfUnsavedSet(warn: !props.state.ui_state.warn_on_exit_if_unsaved),
              ))
          ..key = 'warn-on-exit-if-unsaved')(),
        DropdownDivider({'key': 'divider-save'}),
        (MenuFormFile()
          ..id_ = 'import-cadnano-form-file'
          ..accept = '.json'
          ..on_change = ((e) => request_load_file_from_file_chooser(e.target, cadnano_file_loaded))
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
              app.dispatch(actions.ResetLocalStorage());
            }
          })
          ..display = 'Reset local storage'
          ..tooltip = '''\
Clear the stored design, reset all local settings, and reload the page.'''
          ..key = 'reset-local-storage')(),
        file_menu_save_design_local_storage_options(),
        DropdownDivider({'key': 'divide-clear-helix-selection-when-loading-new-design'}),
        (MenuBoolean()
          ..value = props.state.ui_state.clear_helix_selection_when_loading_new_design
          ..display = 'Clear helix selection when loading new design'
          ..on_change =
              ((_) => app.dispatch(
                actions.ClearHelixSelectionWhenLoadingNewDesignSet(
                  clear: !props.state.ui_state.clear_helix_selection_when_loading_new_design,
                ),
              ))
          ..tooltip = '''\
If checked, the selected helices will be clear when loading a new design.
Otherwise, helix selection is not cleared, meaning that all the selected helices in the current
design will be selected (based on helix index) on the loaded design.'''
          ..key = 'clear-helix-selection-when-loading-new-design')(),
      ],
    );
  }

  ReactElement file_menu_save_design_local_storage_options() => (MenuDropdownRight()
    ..title_ = 'Local storage design save options'
    ..id_ = 'file_menu_local-storage-options'
    ..key = 'file_menu_local-storage-options'
    ..className = 'submenu_item')([
    (MenuBoolean()
      ..value = props.state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.on_edit
      ..display = 'Save design in localStorage on every edit'
      ..tooltip = '''\
On every edit, save current design in localStorage (in your web browser).

Disabling this minimizes the time needed to render large designs.'''
      ..on_change =
          ((_) => app.dispatch(
            actions.LocalStorageDesignChoiceSet(
              choice: props.state.ui_state.local_storage_design_choice.to_on_edit(),
            ),
          ))
      ..key = 'save-dna-design-in-local-storage')(),
    (MenuBoolean()
      ..value = props.state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.on_exit
      ..display = 'Save design in localStorage before exiting'
      ..tooltip = '''\
Before exiting, save current design in localStorage (in your web browser). 
For large designs, this is faster than saving on every edit, but if the browser crashes, 
all changes made will be lost, so it is not as safe as storing on every edit.'''
      ..on_change =
          ((_) => app.dispatch(
            actions.LocalStorageDesignChoiceSet(
              choice: props.state.ui_state.local_storage_design_choice.to_on_exit(),
            ),
          ))
      ..key = 'save-dna-design-in-local-storage-on-exit')(),
    (MenuBoolean()
      ..value = props.state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.never
      ..display = 'Do not save design in localStorage'
      ..tooltip = '''\
Never saves the design in localStorage.

WARNING: you must save your design manually by pressing Ctrl+S or selecting 
File-->Save, or your design will be lost when you close the browser tab.'''
      ..on_change =
          ((_) => app.dispatch(
            actions.LocalStorageDesignChoiceSet(
              choice: props.state.ui_state.local_storage_design_choice.to_never(),
            ),
          ))
      ..key = 'never-save-dna-design-in-local-storage')(),
    (MenuBoolean()
      ..value = props.state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.periodic
      ..display = 'Save design in localStorage periodically'
      ..tooltip = '''\
Every <period> seconds, save current design in localStorage (in your web browser). 
Also saves before exiting.
This is safer than never saving, or saving only before exiting, but will not save edits
that occurred between the last save and a browser crash.'''
      ..on_change =
          ((_) => app.dispatch(
            actions.LocalStorageDesignChoiceSet(
              choice: props.state.ui_state.local_storage_design_choice.to_periodic(),
            ),
          ))
      ..key = 'save-dna-design-in-local-storage-periodically')(),
    (MenuNumber()
      ..display = 'period (seconds)'
      ..min_value = 1
      ..default_value = props.state.ui_state.local_storage_design_choice.period_seconds
      ..hide = props.state.ui_state.local_storage_design_choice.option != LocalStorageDesignOption.periodic
      ..tooltip = 'Number of seconds between saving design to localStorage.'
      ..on_new_value =
          ((num period) => app.dispatch(
            actions.LocalStorageDesignChoiceSet(
              choice: LocalStorageDesignChoice(LocalStorageDesignOption.periodic, period.toInt()),
            ),
          ))
      ..key = 'period-of-save-dna-design-in-local-storage-periodically')(),
  ]);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // edit menu

  edit_menu() {
    return NavDropdown(
      {'title': 'Edit', 'id': 'edit-nav-dropdown'},
      (MenuDropdownRight()
        ..title_ = 'Undo'
        ..id_ = "edit_menu_undo-dropdown"
        ..keyboard_shortcut = 'Ctrl+Z'
        ..disabled = props.state.undo_redo.undo_stack.isEmpty)(undo_dropdowns),
      (MenuDropdownRight()
        ..title_ = 'Redo'
        ..id_ = "edit_menu_redo-dropdown"
        ..keyboard_shortcut = 'Ctrl+Shift+Z'
        ..disabled = props.state.undo_redo.redo_stack.isEmpty)(redo_dropdowns),
      DropdownDivider({}),
      edit_menu_copy_paste(),
      DropdownDivider({}),
      ///////////////////////////////////////////////////////////////
      // Dynamic helix updations
      (MenuBoolean()
        ..display = 'Dynamically update helices'
        ..tooltip = '''\
Expand helices dynamically when strand(s) is moved or created according to the strand(s) movement
If checked, helices will update with strand movement'''
        ..name = 'dynamically-update-helices'
        ..key = 'dynamically-update-helices'
        ..on_change =
            ((_) => app.dispatch(
              actions.DynamicHelixUpdateSet(
                dynamically_update_helices: !props.state.ui_state.dynamically_update_helices,
              ),
            ))
        ..value = props.state.ui_state.dynamically_update_helices)(),

      DropdownDivider({}),
      ///////////////////////////////////////////////////////////////
      // inline insertions/deletions
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.InlineInsertionsDeletions()))
        ..display = 'Inline insertions/deletions'
        ..disabled = !(props.state.maybe_design?.has_insertions_or_deletions == true)
        ..tooltip = '''\
Remove insertions and deletions from the design and replace them with domains
whose lengths correspond to the true strand length. Also moves major tick 
marks on helices so that they are adjacent to the same bases as before.''')(),
      DropdownDivider({}),
      ///////////////////////////////////////////////////////////////
      // Connect selected ends by crossovers
      (MenuDropdownItem()
        // ..on_click = ((_) => connect_ends_by_crossovers(props.selected_ends))
        ..on_click = ((_) => app.dispatch(actions.JoinStrandsByMultipleCrossovers()))
        ..display = 'Connect selected ends by crossovers'
        ..disabled = props.state.ui_state.selectables_store.selected_dna_ends.isEmpty
        ..tooltip = '''\
Connect selected ends by crossovers. 

Ends are connected by crossovers as follows. Within each HelixGroup: 

Iterate over ends in the following order: first by helix, then by 
forward/reverse, then by offset. For each end e1 in this order, join it 
to the first end e2 after it in this order, if 
1) e1 and e2 have the same offset (making a "vertical" crossover), 
2) e1 is "above" e2 (lower helix idx; more generally earlier in helices_view_order), 
3) opposite direction (one is forward and the other reverse), and 
4) opposite side of a strand (i.e., one is 5' and the other 3').''')(),
      DropdownDivider({}),
      edit_menu_helix_rolls(),
      ///////////////////////////////////////////////////////////////
      // Set geometric parameters
      DropdownDivider({}),
      (MenuDropdownItem()
        ..on_click =
            ((_) => app.disable_keyboard_shortcuts_while(
              () => ask_for_geometry(props.state.maybe_design?.geometry),
            ))
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
It uses cadnano code that crashes on many designs, so it is not guaranteed to work properly. 
It will also only work on scadnano designs that are exportable to cadnano.
        ''')(),
    );
  }

  List<ReactElement> get undo_dropdowns {
    return undo_or_redo_dropdowns((i) => actions.Undo(i), props.state.undo_redo.undo_stack, "Undo");
  }

  List<ReactElement> get redo_dropdowns {
    return undo_or_redo_dropdowns((i) => actions.Redo(i), props.state.undo_redo.redo_stack, "Redo");
  }

  List<ReactElement> undo_or_redo_dropdowns(
    ActionFromIntCreator undo_or_redo_action_creator,
    BuiltList<UndoRedoItem> stack,
    String action_name,
  ) {
    List<ReactElement> dropdowns = [];
    int num_times = 1;
    bool most_recent = true;
    for (var item in stack.reversed) {
      dropdowns.add(
        undo_or_redo_dropdown(item, undo_or_redo_action_creator, num_times, action_name, most_recent),
      );
      num_times += 1;
      most_recent = false;
    }
    return dropdowns;
  }

  ReactElement undo_or_redo_dropdown(
    UndoRedoItem item,
    ActionFromIntCreator undo_or_redo_action_creator,
    int num_times,
    String action_name,
    bool is_most_recent,
  ) {
    String key = '${action_name.toLowerCase()}-${num_times}';
    return (MenuDropdownItem()
      ..display = '${action_name} "${item.short_description}"' + (is_most_recent ? " [Most Recent]" : "")
      ..key = key
      ..on_click = (_) => app.dispatch(undo_or_redo_action_creator(num_times)))();
  }

  ReactElement edit_menu_copy_paste() {
    return (MenuDropdownRight()
      ..title_ = 'Copy/Paste/Select'
      ..id_ = 'edit_menu_copy-paste'
      ..key = 'edit_menu_copy-paste'
      ..className = 'submenu-item')(
      (MenuDropdownItem()
        ..on_click = (_) {
          if (this.enable_copy) {
            window.dispatchEvent(new KeyEvent('keydown', keyCode: KeyCode.C, ctrlKey: true).wrapped);
          }
        }
        ..display = 'Copy'
        ..keyboard_shortcut = 'Ctrl+C'
        ..tooltip = '''\
Copy the currently selected strand(s). They can be pasted into this design,
or into another design in another browser or tab. You can also paste into
a text document to see a JSON description of the copied strand(s).'''
        ..disabled = !this.enable_copy)(),
      (MenuDropdownItem()
        ..on_click = (_) {
          if (this.enable_copy) {
            app.dispatch(actions.CopySelectedStandsToClipboardImage());
          }
        }
        ..display = 'Copy image'
        ..keyboard_shortcut = 'Ctrl+I'
        ..tooltip = '''\
Copy a (PNG bitmap) image of the currently selected strand(s) to the system
clipboard. This image can be pasted into graphics programs such as Powerpoint
or Inkscape. Note that the bitmap image will be pixelated on zoom-in, unlike
SVG (scaled vector graphics). To retain the vector graphics in the image so
that it stays sharp on zoom-in, use the option Export-->SVG of selected strands
to save an SVG file of the selected strands.'''
        ..disabled = !this.enable_copy)(),
      (MenuDropdownItem()
        ..on_click =
            ((_) => window.dispatchEvent(new KeyEvent('keydown', keyCode: KeyCode.V, ctrlKey: true).wrapped))
        ..display = 'Paste'
        ..tooltip = '''\
Paste the previously copied strand(s). They can be pasted into this design,
or into another design in another browser or tab. You can also paste into
a text document to see a JSON description of the copied strand(s).
'''
        ..keyboard_shortcut = 'Ctrl+V')(),
      (MenuDropdownItem()
        ..on_click = ((_) => paste_strands_auto())
        ..display = 'Autopaste'
        ..tooltip = '''\
This automatically pastes copied strands to an automatically selected position
in the design, which can be faster to create many copies of strand(s) than
manually selecting each position to paste. First copy some strand(s), then
manually paste them using the menu Edit-->Paste or pressing Ctrl+V. Once this
is done once, by selecting Edit-->Autopaste (or pressing Shift+Ctrl+V),
another copy of the same strand(s) are pasted, in the same "direction" as the
first paste.

For example, if the first paste was one helix down from the the copied strand(s),
and 10 offset positions to the right, then Autopaste will make the next paste
also one helix down from the first paste, and 10 offset positions to its right.

You can also Autopaste immediately after copying, without having pasted first,
with some default direction chosen. Play with it and see!
'''
        ..keyboard_shortcut = 'Ctrl+Shift+V')(),
      (MenuDropdownItem()
        ..on_click =
            ((_) => window.dispatchEvent(new KeyEvent('keydown', keyCode: KeyCode.A, ctrlKey: true).wrapped))
        ..display = 'Select all'
        ..tooltip = 'Select all strands in the design.'
        ..keyboard_shortcut = 'Ctrl+A')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.SelectAllSelectable(current_helix_group_only: true)))
        ..display = 'Select all in helix group'
        ..tooltip = 'Select all selectable strands in the current helix group.'
        ..keyboard_shortcut = 'Ctrl+Shift+A')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.disable_keyboard_shortcuts_while(ask_for_select_all_with_same_as_selected))
        ..display = 'Select all with same...'
        ..tooltip = 'Select all strands that share given trait(s) as the currently selected strand(s).'
        ..keyboard_shortcut = 'Alt+Shift+A')(),
      (MenuBoolean()
        ..value = props.state.ui_state.selection_box_intersection
        ..display = 'Selection box intersection'
        ..tooltip = '''\
In Select mode, one does Shift+drag to create a selection box, and in rope select mode,
one can draw a more general selection "rope" polygon. This checkbox determines the rule 
for how objects are selected by these shape.

If unchecked, select any object *entirely contained within* the selection shape.

If checked, select any object *intersecting* the selection shape, even if some parts lie 
outside the selection shape.'''
        ..on_change =
            ((_) => app.dispatch(
              actions.SelectionBoxIntersectionRuleSet(
                intersect: !props.state.ui_state.selection_box_intersection,
              ),
            )))(),
      (MenuBoolean()
        ..value = props.state.ui_state.strand_paste_keep_color
        ..display = 'Pasted strands keep original color'
        ..tooltip = '''\
If checked, when copying and pasting a strand, the color is preserved.
If unchecked, then a new color is generated.'''
        ..on_change =
            ((_) => app.dispatch(
              actions.StrandPasteKeepColorSet(keep: !props.state.ui_state.strand_paste_keep_color),
            )))(),
    );
  }

  ReactElement edit_menu_helix_rolls() {
    return (MenuDropdownRight()
      ..title_ = 'Helix rolls'
      ..id_ = 'edit_menu_helix-rolls'
      ..key = 'edit_menu_helix-rolls'
      ..className = 'submenu-item')(
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.RelaxHelixRolls(only_selected: false)))
        ..display = 'Set helix rolls to unstrain crossovers'
        ..tooltip = '''\
Sets all helix rolls to "relax" them based on their crossovers.

This calculates the "strain" of each crossover c as the absolute value d_c of 
the distance between the angle to the helix to which it is connected and the 
angle of that crossover given the current helix roll. It minimizes sum_c d_c^2, 
i.e., minimize the sum of the squares of the strains (if modeling crossovers
as rotational springs, this minimizes the total energy stored in each spring). 
This can be used to create a design with "reasonable" crossover locations and 
then set the rolls to match the crossover locations as best as possible.
''')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.RelaxHelixRolls(only_selected: true)))
        ..display = 'Set *selected* helix rolls to unstrain crossovers'
        ..tooltip = '''\
Same as option "Set helix rolls based on crossovers and helix coordinates" above,
but changes the rolls only of selected helices.''')(),
      DropdownDivider({'key': 'dropdown1'}),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.HelicesPositionsSetBasedOnCrossovers()))
        ..display = 'Set helix coordinates based on crossovers'
        ..disabled = this.no_grid_is_none
        ..tooltip = '''\
The grid must be set to none to enable this.${this.no_grid_is_none ? " (Currently disabled since the grid is not none.)" : ""}

Select some crossovers and some helices. If no helices are selected, then all
helices are processed. At most one crossover between pairs of adjacent (in
view order) helices can be selected. If a pair of adjacent helices has no
crossover selected, it is assumed to be the first crossover.

New grid coordinates are calculated based on the crossovers to ensure that each
pair of adjacent helices has crossover angles that point the backbone angles
directly at the adjoining helix.''')(),
      (MenuBoolean()
        ..value = props.state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls
        ..display = 'default to leftmost scaffold crossover'
        ..tooltip = '''\
When selecting "Set helix coordinates based on crossovers", if two adjacent 
helices do not have a crossover selected, determines which types to select 
automatically.

If this is checked and "default to leftmost staple crossover" is unchecked,
then the leftmost scaffold crossover will be used.

If both are checked, the leftmost crossover of any type will be used.

Ignored if design is not an origami (i.e., does not have at least one scaffold).'''
        ..on_change = (_) {
          // disallow if both would be unchecked
          if (props.state.ui_state.default_crossover_type_staple_for_setting_helix_rolls) {
            app.dispatch(
              actions.DefaultCrossoverTypeForSettingHelixRollsSet(
                scaffold: !props.state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls,
                staple: props.state.ui_state.default_crossover_type_staple_for_setting_helix_rolls,
              ),
            );
          }
        })(),
      (MenuBoolean()
        ..value = props.state.ui_state.default_crossover_type_staple_for_setting_helix_rolls
        ..display = 'default to leftmost staple crossover'
        ..tooltip = '''\
When selecting "Set helix coordinates based on crossovers", if two adjacent 
helices do not have a crossover selected, determines which types to select 
automatically.

If this is checked and "default to leftmost scaffold crossover" is unchecked,
then the leftmost staple crossover will be used.

If both are checked, the leftmost crossover of any type will be used.

Ignored if design is not an origami (i.e., does not have at least one scaffold).'''
        ..on_change = (_) {
          // disallow if both would be unchecked
          if (props.state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls) {
            app.dispatch(
              actions.DefaultCrossoverTypeForSettingHelixRollsSet(
                scaffold: props.state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls,
                staple: !props.state.ui_state.default_crossover_type_staple_for_setting_helix_rolls,
              ),
            );
          }
        })(),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // view menu

  view_menu() {
    var elts = [
      view_menu_warnings(),
      view_menu_autofit(),
      view_menu_show_labels(),
      view_menu_mods(),
      view_menu_helices(),
      view_menu_display_major_ticks_options(),
      view_menu_base_pairs(),
      view_menu_dna(),
      DropdownDivider({'key': 'divider-dna'}),
      ...view_menu_show_oxview(),
      DropdownDivider({'key': 'divider-oxview'}),
      ...view_menu_zoom_speed(),
      DropdownDivider({'key': 'divider-zoom_speed'}),
      ...view_menu_misc(),
    ];
    return NavDropdown({'title': 'View', 'id': 'view-nav-dropdown'}, elts);
  }

  ReactElement view_menu_autofit() {
    return (MenuDropdownRight()
      ..title_ = 'Autofit'
      ..id_ = 'view_menu_autofit-dropdown'
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
        ..value = props.state.ui_state.autofit
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
        ..on_change = ((_) => app.dispatch(actions.AutofitSet(autofit: !props.state.ui_state.autofit)))
        ..key = 'autofit-on-loading-new-design')(),
    ]);
  }

  ReactElement view_menu_warnings() {
    return (MenuDropdownRight()
      ..title_ = 'Warnings'
      ..id_ = 'view_menu_show_warnings'
      ..key = 'view_menu_show_warnings'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.show_mismatches
        ..display = 'Show DNA base mismatches'
        ..tooltip = '''\
Show mismatches between DNA assigned to one strand and the strand on the same
helix with the opposite orientation.'''
        ..on_change = (_) {
          app.dispatch(actions.ShowMismatchesSet(!props.state.ui_state.show_mismatches));
        }
        ..key = 'show-mismatches')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_domain_name_mismatches
        ..display = 'Show domain name mismatches'
        ..tooltip = '''\
Show mismatches between domain names assigned to one strand and the strand on the same
helix with the opposite orientation.'''
        ..on_change = (_) {
          app.dispatch(
            actions.ShowDomainNameMismatchesSet(!props.state.ui_state.show_domain_name_mismatches),
          );
        }
        ..key = 'show-domain-name-mismatches')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_unpaired_insertion_deletions
        ..display = 'Show unpaired insertion/deletions'
        ..tooltip = '''\
Show unpaired deletions and insertions. This is defined to be an insertion/deletion on
a strand, where another strand is at the same (helix,offset) (in the opposite direction),
which lacks the insertion/deletion. It does NOT show a warning if there is no other
strand at the same (helix,offset).'''
        ..on_change = (_) {
          app.dispatch(
            actions.ShowUnpairedInsertionDeletionsSet(
              !props.state.ui_state.show_unpaired_insertion_deletions,
            ),
          );
        }
        ..key = 'show-unpaired-insertion-deletions')(),
    ]);
  }

  ReactElement view_menu_show_labels() {
    return (MenuDropdownRight()
      ..title_ = 'Strand/domain names/labels'
      ..id_ = 'view_menu_show_labels-dropdown'
      ..key = 'view_menu_show_labels-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.show_strand_names
        ..display = 'Show strand names'
        ..tooltip = "Show strand names near 5' domain of strand."
        ..on_change =
            ((_) => app.dispatch(actions.ShowStrandNamesSet(!props.state.ui_state.show_strand_names)))
        ..key = 'show-strand-name')(),
      (MenuNumber()
        ..display = 'strand name font size'
        ..default_value = props.state.ui_state.strand_name_font_size
        ..hide = !props.state.ui_state.show_strand_names
        ..tooltip = 'Adjust the font size of strand names.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.StrandNameFontSizeSet(font_size: font_size.toDouble())))
        ..key = 'strand-name-font-size')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_strand_labels
        ..display = 'Show strand labels'
        ..tooltip = "Show strand labels near 5' domain of strand."
        ..on_change =
            ((_) => app.dispatch(actions.ShowStrandLabelsSet(!props.state.ui_state.show_strand_labels)))
        ..key = 'show-strand-label')(),
      (MenuNumber()
        ..display = 'strand label font size'
        ..default_value = props.state.ui_state.strand_label_font_size
        ..hide = !props.state.ui_state.show_strand_labels
        ..tooltip = 'Adjust the font size of strand labels.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.StrandLabelFontSizeSet(font_size: font_size.toDouble())))
        ..key = 'strand-label-font-size')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_domain_names
        ..display = 'Show domain names'
        ..tooltip = 'Show domain and loopout names.'
        ..on_change =
            ((_) => app.dispatch(actions.ShowDomainNamesSet(!props.state.ui_state.show_domain_names)))
        ..key = 'show-domain-name')(),
      (MenuNumber()
        ..display = 'domain name font size'
        ..default_value = props.state.ui_state.domain_name_font_size
        ..hide = !props.state.ui_state.show_domain_names
        ..tooltip = 'Adjust the font size of domain/loopout/extension names.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.DomainNameFontSizeSet(font_size: font_size.toDouble())))
        ..key = 'domain-name-font-size')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_domain_labels
        ..display = 'Show domain labels'
        ..tooltip = "Show domain labels near 5' domain of strand."
        ..on_change =
            ((_) => app.dispatch(actions.ShowDomainLabelsSet(!props.state.ui_state.show_domain_labels)))
        ..key = 'show-domain-label')(),
      (MenuNumber()
        ..display = 'domain label font size'
        ..default_value = props.state.ui_state.domain_label_font_size
        ..hide = !props.state.ui_state.show_domain_labels
        ..tooltip = 'Adjust the font size of domain labels.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.DomainLabelFontSizeSet(font_size: font_size.toDouble())))
        ..key = 'domain-label-font-size')(),
    ]);
  }

  ReactElement view_menu_mods() {
    return (MenuDropdownRight()
      ..title_ = 'Modifications'
      ..id_ = 'view_menu_mods-dropdown'
      ..key = 'view_menu_mods-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.show_modifications
        ..display = 'Show modifications'
        ..tooltip = 'Check to show DNA modifications (e.g., biotins, fluorophores).'
        ..on_change =
            ((_) => app.dispatch(actions.ShowModificationsSet(!props.state.ui_state.show_modifications)))
        ..key = 'show-mods')(),
      (MenuBoolean()
        ..value = props.state.ui_state.modification_display_connector
        ..hide = !props.state.ui_state.show_modifications
        ..display = 'Display modification connector'
        ..tooltip = """\
Check to display DNA modification "connectors", short lines that connect 
the 5'/3' end, or DNA base (for internal modifications), to the modification. 
This is useful to keep the modification from visually obstructing the design.
If this is unchecked, then the modification is displayed directly on top of 
the 5'/3' end or the base. This is useful for visualizing the exact position
of the modifications, e.g., to see where a pattern of biotins will appear on
the surface of a DNA origami."""
        ..on_change =
            ((_) => app.dispatch(
              actions.SetModificationDisplayConnector(!props.state.ui_state.modification_display_connector),
            ))
        ..key = 'display-mod-connector')(),
      (MenuNumber()
        ..display = 'Modification font size'
        ..default_value = props.state.ui_state.modification_font_size
        ..hide = !props.state.ui_state.show_modifications
        ..tooltip = 'Adjust the font size of modification text representation.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.ModificationFontSizeSet(font_size.toDouble())))
        ..key = 'mod-font-size')(),
    ]);
  }

  ReactElement view_menu_helices() {
    return (MenuDropdownRight()
      ..title_ = 'Helices'
      ..id_ = 'view_menu_helices-dropdown'
      ..key = 'view_menu_helices-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.only_display_selected_helices
        ..display = 'Display only selected helices'
        ..tooltip = 'Only helices selected in the side view are displayed in the main view.'
        ..name = 'display-only-selected-helices'
        ..on_change =
            ((_) => app.dispatch(
              actions.SetOnlyDisplaySelectedHelices(!props.state.ui_state.only_display_selected_helices),
            ))
        ..key = 'display-only-selected-helices')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_helix_components_main_view
        ..display = 'Show main view helices'
        ..tooltip = '''\
Shows helix representation in main view. Hiding them hides all view elements 
associated with a helix: grid lines depicting offsets, circles with helix index,
major tick offsets.'''
        ..name = 'show-helix-components-main-view'
        ..on_change =
            ((_) => app.dispatch(
              actions.ShowHelixComponentsMainViewSet(
                show_helix_components: !props.state.ui_state.show_helix_components_main_view,
              ),
            ))
        ..key = 'show-helix-components-main-view')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_helix_circles_main_view
        ..display = 'Show main view helix circles/idx'
        ..tooltip = '''\
Shows helix circles and idx's in main view. You may want to hide them for
designs that have overlapping non-parallel helices.

To hide all view elements associated with helices (e.g., major ticks),
toggle "Show main view helices".'''
        ..name = 'show-helix-circles-main-view'
        ..on_change =
            ((_) => app.dispatch(
              actions.ShowHelixCirclesMainViewSet(
                show_helix_circles_main_view: !props.state.ui_state.show_helix_circles_main_view,
              ),
            ))
        ..key = 'show-helix-circles-main-view')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_grid_coordinates_side_view
        ..display = 'Show helix coordinates in side view'
        ..tooltip = '''\
Displays coordinates of each helix in the side view (either grid coordinates 
or real coordinates in nanometers, depending on whether a grid is selected).'''
        ..name = 'show-grid-coordinates-side-view'
        ..on_change =
            ((_) => app.dispatch(
              actions.ShowGridCoordinatesSideViewSet(
                show_grid_coordinates_side_view: !props.state.ui_state.show_grid_coordinates_side_view,
              ),
            ))
        ..key = 'show-grid-coordinates-side-view')(),
    ]);
  }

  ReactElement view_menu_display_major_ticks_options() {
    return (MenuDropdownRight()
      ..title_ = 'Major ticks'
      ..id_ = 'view_menu_display_major_tick_offsets-dropdown'
      ..key = 'view_menu_display_major_tick_offsets-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.display_base_offsets_of_major_ticks
        ..display = 'Display major tick offsets'
        ..tooltip = 'Display the integer base offset to the right of each major tick, on the first helix.'
        ..on_change =
            ((_) => app.dispatch(
              actions.DisplayMajorTicksOffsetsSet(!props.state.ui_state.display_base_offsets_of_major_ticks),
            ))
        ..key = 'display-major-tick-offsets')(),
      (MenuBoolean()
        ..value = !props.state.ui_state.display_base_offsets_of_major_ticks_only_first_helix
        ..hide = !props.state.ui_state.display_base_offsets_of_major_ticks
        ..display = '... on all helices'
        ..tooltip = 'Display the integer base offset to the right of each major tick, for all helices.'
        ..on_change =
            ((_) => app.dispatch(
              actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(
                !props.state.ui_state.display_base_offsets_of_major_ticks_only_first_helix,
              ),
            ))
        ..key = 'display-major-tick-offsets-on-all-helices')(),
      (MenuNumber()
        ..display = 'major tick offset font size'
        ..default_value = props.state.ui_state.major_tick_offset_font_size
        ..hide = !props.state.ui_state.display_base_offsets_of_major_ticks
        ..tooltip = 'Adjust to change the font size of major tick offsets.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.MajorTickOffsetFontSizeSet(font_size.toDouble())))
        ..key = 'major-tick-offset-font-size')(),
      DropdownDivider({'key': 'divider-major-tick-offset-from-width'}),
      (MenuBoolean()
        ..value = props.state.ui_state.display_major_tick_widths
        ..display = 'Display major tick widths'
        ..tooltip =
            'Display the number of bases between each adjacent pair of major ticks, on the first helix.'
        ..on_change =
            ((_) => app.dispatch(
              actions.SetDisplayMajorTickWidths(!props.state.ui_state.display_major_tick_widths),
            ))
        ..key = 'display-major-tick-widths')(),
      (MenuBoolean()
        ..value = props.state.ui_state.display_major_tick_widths_all_helices
        ..hide = !props.state.ui_state.display_major_tick_widths
        ..display = '...on all helices'
        ..tooltip = 'Display the number of bases between each adjacent pair of major ticks, on all helices.'
        ..on_change =
            ((_) => app.dispatch(
              actions.SetDisplayMajorTickWidthsAllHelices(
                !props.state.ui_state.display_major_tick_widths_all_helices,
              ),
            ))
        ..key = 'display-major-tick-widths-on-all-helices')(),
      (MenuNumber()
        ..display = 'Major tick width font size'
        ..default_value = props.state.ui_state.major_tick_width_font_size
        ..hide = !props.state.ui_state.display_major_tick_widths
        ..tooltip = 'Adjust to change the font size of major tick offsets.'
        ..on_new_value =
            ((num font_size) => app.dispatch(actions.MajorTickWidthFontSizeSet(font_size.toDouble())))
        ..key = 'major-tick-width-font-size')(),
    ]);
  }

  ReactElement view_menu_base_pairs() {
    return (MenuDropdownRight()
      ..title_ = 'Base pairs'
      ..id_ = 'view_menu_base_pairs'
      ..key = 'view_menu_base_pairs-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.base_pair_display_type == BasePairDisplayType.lines
        ..display = 'Display as ${BasePairDisplayType.lines.display_name()}'
        ..key = 'base-pair-display-lines'
        ..on_change = (_) {
          if (props.state.ui_state.base_pair_display_type == BasePairDisplayType.lines) {
            app.dispatch(actions.BasePairTypeSet(selected_idx: BasePairDisplayType.none.toIndex()));
          } else if (props.state.ui_state.base_pair_display_type == BasePairDisplayType.none) {
            app.dispatch(actions.BasePairTypeSet(selected_idx: BasePairDisplayType.lines.toIndex()));
          }
        })(),
      (MenuBoolean()
        ..value = props.state.ui_state.export_base_pair_lines_if_other_strand_not_selected
        ..hide = props.state.ui_state.base_pair_display_type != BasePairDisplayType.lines
        ..display = 'Export base pair lines if other strand not selected'
        ..tooltip = '''\
When exporting an image of strands while base pair lines are displayed, either through 
Edit-->Copy/Paste/Select-->Copy image (Ctrl+I), or through 
Export-->SVG of selected strands, where it is possible that some strands are not selected,
but are bound to strands that are selected, this determines whether to export the base pair 
lines connecting the exported strand to the other (non-exported) strand.'''
        ..on_change =
            ((_) => app.dispatch(
              actions.ExportBasePairLinesIfOtherStrandNotSelectedSet(
                export_base_pair_lines_if_other_strand_not_selected:
                    !props.state.ui_state.export_base_pair_lines_if_other_strand_not_selected,
              ),
            ))
        ..key = 'display-major-tick-offsets-on-all-helices')(),
      (MenuBoolean()
        ..value = props.state.ui_state.base_pair_display_type.toIndex() == 2
        ..display = 'Display as ${BasePairDisplayType.rectangle.display_name()}'
        ..key = 'base-pair-display-rectangle'
        ..on_change = (_) {
          if (props.state.ui_state.base_pair_display_type == BasePairDisplayType.rectangle) {
            app.dispatch(actions.BasePairTypeSet(selected_idx: BasePairDisplayType.none.toIndex()));
          } else if (props.state.ui_state.base_pair_display_type == BasePairDisplayType.none) {
            app.dispatch(actions.BasePairTypeSet(selected_idx: BasePairDisplayType.rectangle.toIndex()));
          }
        })(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_base_pair_lines_with_mismatches
        ..display = '... even if bases mismatch'
        ..key = 'base-pair-display-even-if-bases-mismatch'
        ..hide = props.state.ui_state.base_pair_display_type.toIndex() == 0
        ..tooltip = '''\
Lines are drawn between all pairs of bases at the same offset on the same helix, 
regardless of whether the bases are complementary. If unchecked then lines are 
only shown between pairs of complementary bases.'''
        ..on_change =
            (_) => app.dispatch(
              actions.ShowBasePairLinesWithMismatchesSet(
                show_base_pair_lines_with_mismatches:
                    !props.state.ui_state.show_base_pair_lines_with_mismatches,
              ),
            ))(),
    ]);
  }

  ReactElement view_menu_dna() {
    return (MenuDropdownRight()
      ..title_ = 'DNA'
      ..id_ = 'view_menu_dna'
      ..key = 'view_menu_dna-dropdown'
      ..className = 'submenu_item')([
      (MenuBoolean()
        ..value = props.state.ui_state.show_dna
        ..display = 'DNA sequences'
        ..tooltip = '''\
Show DNA sequences that have been assigned to strands. In a large design, this
can slow down the performance of panning and zooming navigation, so uncheck it
to speed up navigation.'''
        ..on_change = ((_) => app.dispatch(actions.ShowDNASet(!props.state.ui_state.show_dna)))
        ..key = 'show-dna-sequences')(),
      (MenuBoolean()
        ..value = props.state.ui_state.display_reverse_DNA_right_side_up
        ..display = 'Display reverse DNA right-side up'
        ..tooltip = '''\
Displays DNA right-side up on reverse strands.'''
        ..name = 'display-reverse-DNA-right-side-up'
        ..hide = !props.state.ui_state.show_dna
        ..on_change = (_) {
          app.dispatch(
            actions.DisplayReverseDNARightSideUpSet(!props.state.ui_state.display_reverse_DNA_right_side_up),
          );
        }
        ..key = 'display-reverse-DNA-right-side-up')(),
    ]);
  }

  List<ReactElement> view_menu_show_oxview() {
    return [
      (MenuBoolean()
        ..value = props.state.ui_state.show_oxview
        ..display = 'Show oxView'
        ..tooltip = '''\
Displays an embedded oxView window to visualize the 3D structure of the design.

Currently the view is "read-only", it will export the scadnano design and show 
it in the oxView window, but changes made in the oxView window are not propagated
back to the scadnano design. Any changes will be lost the next time the scadnano
design is edited.

The oxView window will just show the structure at first, but if you press the `m`
key, it will show the oxView controls. (But bear in mind any edits will be lost
upon the next scadnano design change.)

After clicking in the oxView window, the focus is lost from the scadnano app,
and keyboard shortcuts (e.g., Ctrl+Z to undo, or Delete to delete selected strands)
will not be recognized by scadnano, even if you click in the scadnano main view.
Clicking on the menu or the slider bars will return focus to scadnano so that
keyboard shortcuts will be recognized by scadnano again.'''
        ..name = 'show-oxview'
        ..on_change = (_) {
          app.dispatch(actions.OxviewShowSet(!props.state.ui_state.show_oxview));
        }
        ..key = 'show-oxview')(),
    ];
  }

  List<ReactElement> view_menu_zoom_speed() {
    return [
      (MenuNumber()
        ..display = 'Zoom speed'
        ..default_value = props.state.ui_state.zoom_speed
        ..min_value = 0
        ..step = 0.05
        ..tooltip = 'The speed at which the mouse wheel or two-finger scroll zooms the view in and out.'
        ..on_new_value =
            ((num new_zoom_speed) => app.dispatch(actions.ZoomSpeedSet(speed: new_zoom_speed as double)))
        ..key = 'zoom-speed')(),
    ];
  }

  List<ReactElement> view_menu_misc() {
    return [
      (MenuBoolean()
        ..value = props.state.ui_state.invert_y
        ..display = 'Invert y-axis'
        ..tooltip = '''\
Invert the y-axis by rotating 180 degrees about the z-axis (within the x/y plane).

If unchecked, then use "screen coordinates", where increasing y moves down. 

If checked, then use Cartesian coordinates where increasing y moves up.

To inspect how all axes change, check View --> Show axis arrows.'''
        ..name = 'invert-y-axis'
        ..on_change = ((_) => app.dispatch(actions.InvertYSet(invert_y: !props.state.ui_state.invert_y)))
        ..key = 'invert-y-axis')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_helices_axis_arrows
        ..display = 'Axis arrows'
        ..tooltip = '''\
Show axis arrows in side and main view
Red : X-axis
Green : Y-axis
Blue : Z-axis'''
        ..name = 'show-helices-axis-arrows'
        ..on_change =
            ((_) => app.dispatch(
              actions.ShowAxisArrowsSet(
                show_helices_axis_arrows: !props.state.ui_state.show_helices_axis_arrows,
              ),
            ))
        ..key = 'show-helices-axis-arrows')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_loopout_extension_length
        ..display = 'Loopout/extension lengths'
        ..tooltip = '''\
When selected, the length of each loopout and extension is displayed next to it.'''
        ..name = 'show-loopout-extension-length'
        ..on_change =
            ((_) => app.dispatch(
              actions.ShowLoopoutExtensionLengthSet(
                show_length: !props.state.ui_state.show_loopout_extension_length,
              ),
            ))
        ..key = 'show-loopout-extension-length')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_slice_bar
        ..display = 'Slice bar'
        ..tooltip = '''\
When selected, a slicebar is displayed, which users can drag and move to
display the DNA backbone angle of all helices at a particular offset.
        '''
        ..name = 'show-slice-bar'
        ..on_change = (_) {
          app.dispatch(actions.ShowSliceBarSet(!props.state.ui_state.show_slice_bar));
        }
        ..key = 'show-slice-bar')(),
      (MenuBoolean()
        ..value = props.state.ui_state.show_mouseover_data
        ..display = 'Strand and helix details in footer'
        ..tooltip = '''\
When selected, the footer will display details about the design based
on where the cursor is located. If the cursor is on a helix, the helix
index and cursor's base offset location is displayed. If the cursor is
on a strand, then the strand details will also be displayed.

In a large design, this can slow down the performance, so uncheck it when not in use.
        '''
        ..name = 'show-mouseover-data'
        ..on_change = (_) {
          app.dispatch(actions.ShowMouseoverDataSet(!props.state.ui_state.show_mouseover_data));
        }
        ..key = 'show-mouseover-data')(),
      (MenuBoolean()
        ..value = props.state.ui_state.disable_png_caching_dna_sequences
        ..display = 'Disable PNG caching of DNA sequences'
        ..tooltip = '''\
DNA sequences are displayed as SVG (scaled vector graphics), which slow down the program
significantly when zoomed far out on a large design and hundreds or thousands of DNA bases 
are displayed simultaneously. To prevent this, the image of DNA sequences is converted 
to a PNG image when zoomed out sufficiently far, which is much faster to display.

Select this option to disable this PNG caching of DNA sequences. This can be useful when 
debugging, but be warned that it will be very slow to render a large number of DNA bases.'''
        ..name = 'disable-png-caching-dna-sequences'
        ..on_change = (_) {
          app.dispatch(
            actions.DisablePngCachingDnaSequencesSet(!props.state.ui_state.disable_png_caching_dna_sequences),
          );
        }
        ..key = 'disable-png-caching-dna-sequences')(),
      (MenuBoolean()
        ..value = props.state.ui_state.retain_strand_color_on_selection
        ..display = 'Retain strand color on selection'
        ..tooltip = '''\
Selected strands are normally highlighted in hot pink, which overrides the strand's color.
Select this option to not override the strand's color when it is selected.
A highlighting effect will still appear.
        '''
        ..name = 'retain-strand-color-on-selection'
        ..on_change = (_) {
          app.dispatch(
            actions.RetainStrandColorOnSelectionSet(!props.state.ui_state.retain_strand_color_on_selection),
          );
        }
        ..key = 'retain-strand-color-on-selection')(),
    ];
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // export menu

  export_menu() {
    return NavDropdown(
      {'title': 'Export', 'id': 'export-nav-dropdown'},
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportSvg(type: actions.ExportSvgType.side)))
        ..tooltip = "Export SVG figure of side view (cross-section of helices on the left side of screen)."
        ..display = 'SVG side view')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportSvg(type: actions.ExportSvgType.main)))
        ..tooltip = "Export SVG figure of main view (design shown in center of screen)."
        ..display = 'SVG main view')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportSvg(type: actions.ExportSvgType.selected)))
        ..tooltip = "Export SVG figure of selected strands"
        ..display = 'SVG of selected strands')(),
      (MenuBoolean()
        ..value = props.state.ui_state.export_svg_text_separately
        ..display = 'export svg text separately (PPT)'
        ..tooltip = '''\
When selected, every symbol of the text in a DNA sequence is exported as a separate
SVG text element. This is useful if the SVG will be imported into Powerpoint, which 
is less expressive than SVG and can render the text strangely.'''
        ..name = 'export-svg-text-separately'
        ..on_change = (_) {
          app.dispatch(actions.ExportSvgTextSeparatelySet(!props.state.ui_state.export_svg_text_separately));
        }
        ..key = 'export-svg-text-separately')(),
      DropdownDivider({'key': 'divider-export-svg'}),
      (MenuDropdownItem()
        ..on_click = ((_) => app.disable_keyboard_shortcuts_while(export_dna_sequences.export_dna))
        ..tooltip = "Export DNA sequences of strands to a file."
        ..display = 'DNA sequences')(),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportCanDoDNA()))
        ..tooltip =
            "Export design's DNA sequences as a CSV in the same way as cadnano v2.\n"
            "This is useful, for example, with CanDo's atomic model generator."
        ..display = 'DNA sequences (cadnano v2 format)')(),
      DropdownDivider({'key': 'divider-export-dna'}),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportCadnanoFile(whitespace: true)))
        ..tooltip = "Export design to cadnano (version 2) .json file."
        ..display = 'cadnano v2'
        ..key = 'export-cadnano')(),
      DropdownItem({
        'href': 'https://scadnano-python-package.readthedocs.io/en/latest/#interoperability-cadnano-v2',
        'target': '_blank',
        'title': """\
Read constraints that the scadnano design must obey to exportable to cadnano v2.
The constraints are the same for the scadnano Python package (described at the 
linked page) as for the web interface.
""",
      }, 'cadnano v2 export instructions'),
      (MenuDropdownItem()
        ..on_click = ((_) => app.dispatch(actions.ExportCadnanoFile(whitespace: false)))
        ..tooltip = """\
Export design to cadnano (version 2) .json file with no whitespace or newlines.
This is necessary to use the cadnano file with CanDo, which causes a confusing error 
cadnano files that have whitespace. ("Bad .json file format is detected in 
'structure.json'. Or no dsDNA or strand crossovers exist.")"""
        ..display = 'cadnano v2 no whitespace'
        ..key = 'export-cadnano-no-whitespace')(),
      DropdownDivider({'key': 'divider-cadnano'}),
      (MenuDropdownItem()
        ..on_click =
            ((_) => app.dispatch(
              actions.OxviewExport(
                selected_strands_only: props.state.ui_state.ox_export_only_selected_strands,
              ),
            ))
        ..tooltip = "Export design to oxView files, which can be loaded in oxView."
        ..display = 'oxView'
        ..key = 'export-oxview')(),
      (MenuDropdownItem()
        ..on_click =
            ((_) => app.dispatch(
              actions.OxdnaExport(
                selected_strands_only: props.state.ui_state.ox_export_only_selected_strands,
              ),
            ))
        ..tooltip = "Export design to oxDNA .dat and .top files, which can be loaded in oxDNA or oxView."
        ..display = 'oxDNA'
        ..key = 'export-oxdna')(),
      (MenuBoolean()
        ..value = props.state.ui_state.ox_export_only_selected_strands
        ..display = 'export only selected strands'
        ..tooltip = '''\
When selected, only selected strands will be exported to oxDNA or oxView formats.'''
        ..name = 'ox-export-only-selected-strands'
        ..on_change = (_) {
          app.dispatch(
            actions.OxExportOnlySelectedStrandsSet(
              only_selected: !props.state.ui_state.ox_export_only_selected_strands,
            ),
          );
        }
        ..key = 'ox-export-only-selected-strands')(),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // help menu

  help_menu() {
    List<ReactElement> version_dropdown_items = [];
    bool first = true;
    for (var version in constants.scadnano_versions_to_link) {
      var version_dropdown_item = DropdownItem({
        'href': 'https://scadnano.org/v${version}/index.html',
        'target': '_blank',
        'key': version,
        'title': '''\
    Version v${version} of scadnano, located at https://scadnano.org/v${version}/index.html.''',
      }, 'v${version}' + (first ? ' (current version)' : ''));
      first = false;
      version_dropdown_items.add(version_dropdown_item);
    }

    return NavDropdown(
      {'title': 'Help', 'id': 'help-nav-dropdown'},
      DropdownItem({
        'href': 'https://github.com/UC-Davis-molecular-computing/scadnano#readme',
        'target': '_blank',
      }, 'help (web interface)'),
      DropdownItem({
        'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/blob/main/tutorial/tutorial.md',
        'target': '_blank',
      }, 'tutorial (web interface)'),
      DropdownItem({
        'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package#readme',
        'target': '_blank',
      }, 'help (Python scripting)'),
      DropdownItem({
        'href':
            'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/main/tutorial/tutorial.md',
        'target': '_blank',
      }, 'tutorial (Python scripting)'),
      DropdownItem({
        'href': 'https://scadnano-python-package.readthedocs.io',
        'target': '_blank',
      }, 'Python scripting API'),
      DropdownItem({
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
the .sc file in a .zip file, then it can be uploaded.''',
      }, 'Bug report/feature request (web interface)'),
      DropdownItem({
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
the .sc file in a .zip file, then it can be uploaded.''',
      }, 'Bug report/feature request (Python scripting)'),
      DropdownItem({
        'href': 'https://github.com/UC-Davis-molecular-computing/scadnano/releases',
        'target': '_blank',
      }, 'Release notes (web interface)'),
      DropdownItem({
        'href': 'https://github.com/UC-Davis-molecular-computing/scadnano-python-package/releases',
        'target': '_blank',
      }, 'Release notes (Python scripting)'),
      // older_versions_link_dropdown,
      (MenuDropdownRight()
        ..title_ = "Other versions"
        ..id_ = "older-version-dropdown"
        ..disallow_overflow = true
        ..tooltip = '''\
Older versions of scadnano, as well as the newest development version.

Starting from v0.12.1, every released (master branch) version of scadnano 
is deployed to https://scadnano.org/{version}. 

https://scadnano.org/dev is the newest version, containing newer features 
(those marked "closed in dev" on the scadnano issues page: 
https://github.com/UC-Davis-molecular-computing/scadnano/issues), 
but it may be less stable than the current version.''')([
        DropdownItem({
          'href': 'https://scadnano.org/dev',
          'target': '_blank',
          'key': 'dev',
          'title': '''\
Development version of scadnano, located at https://scadnano.org/dev.

This site is updated more frequently than the main site at https://scadnano.org.

This includes open issues that have been handled in the dev branch but not the main branch:
https://github.com/UC-Davis-molecular-computing/scadnano/labels/closed%20in%20dev

However, it may be less stable than the main site.''',
        }, 'dev'),
        version_dropdown_items,
      ]),
      (MenuDropdownItem()
        ..on_click =
            ((_) => window.alert(
              ''
              'scadnano version ${constants.CURRENT_VERSION}'
              '\n\nscadnano is a program for designing synthetic DNA structures such as DNA origami. '
              '\n\nscadnano is a standalone project developed and maintained by the UC Davis Molecular Computing group. '
              'Though similar in design, scadnano is distinct from cadnano (https://cadnano.org), '
              'which is developed and maintained by the Douglas lab (https://bionano.ucsf.edu/) at UCSF.',
            ))
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

  Future<void> load_example_dialog() async {
    var dialog = Dialog(
      title: 'Load example DNA design',
      type: DialogType.load_example_dna_design,
      items: [DialogRadio(label: 'designs', options: props.state.ui_state.example_designs.filenames)],
    );
    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    int selected_idx = (results[0] as DialogRadio).selected_idx;
    app.dispatch(actions.ExampleDesignsLoad(selected_idx: selected_idx));
  }
}

typedef ActionFromIntCreator = actions.Action Function(int);

Future<void> ask_for_autobreak_parameters() async {
  int target_length_idx = 0;
  int min_length_idx = 1;
  int max_length_idx = 2;
  int min_distance_to_xover_idx = 3;
  var items = util.FixedList<DialogItem>(4);
  items[target_length_idx] = DialogInteger(label: 'target length', value: 49);
  items[min_length_idx] = DialogInteger(label: 'min length', value: 15);
  items[max_length_idx] = DialogInteger(label: 'max length', value: 60);
  items[min_distance_to_xover_idx] = DialogInteger(label: 'min distance to xover', value: 3);

  var dialog = Dialog(
    title: 'Choose autobreak parameters',
    type: DialogType.choose_autobreak_parameters,
    items: items,
  );
  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return;

  int target_length = (results[target_length_idx] as DialogInteger).value;
  int min_length = (results[min_length_idx] as DialogInteger).value;
  int max_length = (results[max_length_idx] as DialogInteger).value;
  int min_distance_to_xover = (results[min_distance_to_xover_idx] as DialogInteger).value;

  app.dispatch(
    actions.Autobreak(
      target_length: target_length,
      min_length: min_length,
      max_length: max_length,
      min_distance_to_xover: min_distance_to_xover,
    ),
  );
}

Future<void> ask_for_geometry(Geometry? geometry) async {
  if (geometry == null) {
    // if no design, then use default geometry for default values
    geometry = Geometry();
  }
  int rise_per_base_pair_idx = 0;
  int helix_radius_idx = 1;
  int inter_helix_gap_idx = 2;
  int bases_per_turn_idx = 3;
  int minor_groove_angle_idx = 4;

  var items = util.FixedList<DialogItem>(5);
  items[rise_per_base_pair_idx] = DialogFloat(
    label: 'rise per base pair (nm)',
    value: geometry.rise_per_base_pair,
  );
  items[helix_radius_idx] = DialogFloat(label: 'helix radius (nm)', value: geometry.helix_radius);
  items[inter_helix_gap_idx] = DialogFloat(label: 'inter helix gap (nm)', value: geometry.inter_helix_gap);
  items[bases_per_turn_idx] = DialogFloat(label: 'bases per turn', value: geometry.bases_per_turn);
  items[minor_groove_angle_idx] = DialogFloat(
    label: 'minor groove angle (degrees)',
    value: geometry.minor_groove_angle,
  );

  var dialog = Dialog(
    title: 'adjust geometric parameters',
    type: DialogType.adjust_geometric_parameters_design,
    items: items,
    use_saved_response: false,
  );
  List<DialogItem>? results = await util.dialog(dialog);
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
  FileUploadInputElement file_chooser,
  void Function(FileReader, String) onload_callback,
) {
  List<File>? files = file_chooser.files;
  if (files == null) {
    window.alert('No files selected');
    return;
  }
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
  String json_model_text = file_reader.result as String;
  app.dispatch(actions.PrepareToLoadDNAFile(content: json_model_text, filename: filename));
}

cadnano_file_loaded(FileReader file_reader, String filename) async {
  try {
    String json_cadnano_text = file_reader.result as String;
    filename = path.setExtension(filename, '.${constants.default_scadnano_file_extension}');
    app.dispatch(
      actions.PrepareToLoadDNAFile(
        content: json_cadnano_text,
        filename: filename,
        dna_file_type: DNAFileType.cadnano_file,
      ),
    );
  } on Exception catch (e) {
    window.alert('Error importing file: ${e}');
  }
}
