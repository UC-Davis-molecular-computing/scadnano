import 'dart:html';

import 'package:collection/collection.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:quiver/collection.dart';

import '../state/position3d.dart';
import '../state/grid.dart';
import '../state/dialog.dart';
import '../view/redraw_counter_component_mixin.dart';
import '../view/react_bootstrap.dart';
import '../state/group.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'menu_dropdown_item.dart';

part 'menu_side.over_react.g.dart';

UiFactory<SideMenuProps> ConnectedSideMenu = connect<AppState, SideMenuProps>(
  mapStateToProps: (state) => (SideMenu()
    ..groups = state.design?.groups
    ..displayed_group_name = state.ui_state.displayed_group_name),
  // Used for component test.
  forwardRef: true,
)(SideMenu);

UiFactory<SideMenuProps> SideMenu = _$SideMenu;

mixin SideMenuPropsMixin on UiProps {
  BuiltMap<String, HelixGroup> groups;
  String displayed_group_name;
}

class SideMenuProps = UiProps with SideMenuPropsMixin, ConnectPropsMixin;

class SideMenuComponent extends UiComponent2<SideMenuProps> with RedrawCounterMixin {
  @override
  get consumedProps => propsMeta.forMixins({SideMenuPropsMixin});

  @override
  render() {
    if (props.groups == null) {
      return null;
    }

    if (props.groups.length > 1 || props.displayed_group_name != constants.default_group_name) {
      return Navbar(
        {
          'bg': 'light',
          'expand': 'lg',
        },
        NavbarBrand({'key': 'side-menu-display-title'}, props.displayed_group_name),
        groups_menu(),
        grid_menu(),
      );
    } else {
      return Navbar(
        {
          'bg': 'light',
          'expand': 'lg',
        },
        groups_menu(),
        grid_menu(),
      );
    }
  }

  groups_menu() {
    var options = [];
    for (var name in props.groups.keys) {
      options.add((MenuDropdownItem()
        ..on_click = ((ev) => app.dispatch(actions.GroupDisplayedChange(group_name: name)))
        ..display = name
        ..active = name == props.displayed_group_name
        ..disabled = name == props.displayed_group_name
        ..key = 'key_for_group_name:$name')());
    }
    options.addAll([
      DropdownDivider({'key': 'divider-add-remove'}),
      (MenuDropdownItem()
        ..display = 'adjust current group'
        ..on_click = ((ev) => set_new_parameters_for_current_group())
        ..key = 'adjust-current-group')(),
      (MenuDropdownItem()
        ..display = 'new group'
        ..on_click = ((ev) => add_new_group(props.groups.keys))
        ..key = 'new-group')(),
      (MenuDropdownItem()
        ..display = 'duplicate group'
        ..on_click = ((ev) => add_duplicate_group())
        ..key = 'duplicate-group')(),
      (MenuDropdownItem()
        ..display = 'remove current group'
        ..disabled = props.groups.length == 1
        ..on_click = ((ev) => app.dispatch(actions.GroupRemove(name: props.displayed_group_name)))
        ..key = 'remove-current-group')(),
    ]);
    return NavDropdown({
      'title': 'Group',
      'id': 'group-nav-dropdown',
    }, options);
  }

  grid_menu() {
    return NavDropdown(
      {
        'title': 'Grid',
        'id': 'grid-nav-dropdown',
      },
      [
        for (var grid in Grid.values)
          (MenuDropdownItem()
            ..display = grid.toString()
            ..active = grid == props.groups[props.displayed_group_name].grid
            ..disabled = grid == props.groups[props.displayed_group_name].grid
            ..on_click = ((ev) =>
                props.dispatch(actions.GridChange(grid: grid, group_name: props.displayed_group_name)))
            ..key = grid.toString())()
      ],
    );
  }

  set_new_parameters_for_current_group() =>
      app.disable_keyboard_shortcuts_while(ask_new_parameters_for_current_group);

  add_new_group(Iterable<String> existing_names) =>
      app.disable_keyboard_shortcuts_while(() => ask_about_new_group(existing_names));

  Future<void> ask_about_new_group(Iterable<String> existing_names) async {
    var dialog = Dialog(title: 'create new Helix group', items: [
      DialogText(label: 'name'),
      DialogRadio(label: 'grid', options: ['square', 'honeycomb', 'hex', 'none'], selected_idx: 0),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    // get name
    String name = (results[0] as DialogText).value;
    if (existing_names.contains(name)) {
      var msg = 'Cannot use name ${name} for a new group because it is already in use.';
      window.alert(msg);
      return;
    }

    // get grid
    String grid_name_chosen = (results[1] as DialogRadio).value;
    Grid grid_chosen = Grid.valueOf(grid_name_chosen);
    // when we start there are no helices in the group
    HelixGroup group = HelixGroup(grid: grid_chosen, helices_view_order: []);

    app.dispatch(actions.GroupAdd(name: name, group: group));
  }

  Future<void> ask_new_parameters_for_current_group() async {
    var group = props.groups[props.displayed_group_name];
    var existing_grid = group.grid;

    int name_idx = 0;
    int position_x_idx = 1;
    int position_y_idx = 2;
    int position_z_idx = 3;
    int pitch_idx = 4;
    int roll_idx = 5;
    int yaw_idx = 6;
    int helices_view_order_idx = 7;
    var items = List<DialogItem>.filled(8, null);
    items[name_idx] = DialogText(label: 'name', value: props.displayed_group_name);
    items[position_x_idx] = DialogFloat(label: 'x', value: group.position.x);
    items[position_y_idx] = DialogFloat(label: 'y', value: group.position.y);
    items[position_z_idx] = DialogFloat(label: 'z', value: group.position.z);
    items[pitch_idx] = DialogFloat(label: 'pitch', value: group.pitch);
    items[roll_idx] = DialogFloat(label: 'roll', value: group.roll);
    items[yaw_idx] = DialogFloat(label: 'yaw', value: group.yaw);
    items[helices_view_order_idx] =
        DialogText(label: 'helices view order (space separated)', value: group.helices_view_order.join(' '));

    var dialog =
        Dialog(title: 'adjust current Helix group (to adjust grid use Grid menu on left)', items: items);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    // get name
    String new_name = (results[name_idx] as DialogText).value.trim();
    var existing_names = props.groups.keys;
    if (new_name != props.displayed_group_name && existing_names.contains(new_name)) {
      var msg = 'Cannot use name ${new_name} for a new group because it is already in use.';
      window.alert(msg);
      return;
    }

    // get helices_view_order
    List<int> helices_view_order_old_sorted = group.helices_view_order.toList();
    helices_view_order_old_sorted.sort();
    String helices_view_order_str = (results[helices_view_order_idx] as DialogText).value.trim();
    List<int> helices_view_order_chosen = [];
    if (helices_view_order_str.isNotEmpty) {
      List<String> helices_view_order_strs = helices_view_order_str.split(' ');

      for (var order_str in helices_view_order_strs) {
        int order = int.tryParse(order_str);
        if (order == null) {
          window.alert('${order_str} is not an integer');
          return;
        }
        if (!helices_view_order_old_sorted.contains(order)) {
          window.alert('${order} is not a valid helix index');
          return;
        }
        helices_view_order_chosen.add(order);
      }

      List<int> helices_view_order_chosen_sorted = List<int>.of(helices_view_order_chosen);
      helices_view_order_chosen_sorted.sort();
      var eq = ListEquality().equals;
      if (!eq(helices_view_order_old_sorted, helices_view_order_chosen_sorted)) {
        Set old_sorted = helices_view_order_old_sorted.toSet();
        Set chosen_sorted = helices_view_order_chosen_sorted.toSet();
        Set old_difference = old_sorted.difference(chosen_sorted);
        String error_message = "";
        if (old_difference.length != 0) {
          error_message += 'Missing the following helix indices: ${old_difference.toList()}\n';
        }

        if (!eq(chosen_sorted.toList(), helices_view_order_chosen_sorted)) {
          // finding duplicate values in helices_view_order_chosen_sorted
          List unique_vals = List();
          List duplicates = List();
          for (int i in helices_view_order_chosen_sorted) {
            if (unique_vals.contains(i))
              duplicates.add(i);
            else {
              unique_vals.add(i);
            }
          }
          error_message += 'The following helix indices are duplicated: ${duplicates.toSet().toList()}\n';
        }

        window.alert(error_message);
        return;
      }
    }

    // get position and orientation
    num position_x = (results[position_x_idx] as DialogFloat).value;
    num position_y = (results[position_y_idx] as DialogFloat).value;
    num position_z = (results[position_z_idx] as DialogFloat).value;
    num pitch = (results[pitch_idx] as DialogFloat).value;
    num roll = (results[roll_idx] as DialogFloat).value;
    num yaw = (results[yaw_idx] as DialogFloat).value;
    var position = Position3D(x: position_x, y: position_y, z: position_z);

    HelixGroup new_group = HelixGroup(
        grid: existing_grid,
        helices_view_order: helices_view_order_chosen,
        position: position,
        pitch: pitch,
        roll: roll,
        yaw: yaw);

    app.dispatch(
        actions.GroupChange(old_name: props.displayed_group_name, new_name: new_name, new_group: new_group));
  }

  add_duplicate_group() {
    app.dispatch(actions.GroupDuplicate(name: 'Copy of ' + props.displayed_group_name, groupToDuplicate: props.displayed_group_name));
  }
}
