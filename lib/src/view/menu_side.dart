import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/position3d.dart';

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
    ..groups = state.design.groups
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
        ..on_click = ((ev) => ask_new_parameters_for_current_group())
        ..key = 'adjust-current-group')(),
      (MenuDropdownItem()
        ..display = 'new group'
        ..on_click = ((ev) => ask_about_new_group(props.groups.keys))
        ..key = 'new-group')(),
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

  ask_new_parameters_for_current_group() async {
    var grid_name_list = ['square', 'honeycomb', 'hex', 'none'];
    var group = props.groups[props.displayed_group_name];
    var existing_grid = group.grid;
    int existing_grid_idx = grid_name_list.indexOf(existing_grid.name);

    int name_idx = 0;
    int grid_idx = 1;
    int position_x_idx = 2;
    int position_y_idx = 3;
    int position_z_idx = 4;
    int pitch_idx = 5;
    int roll_idx = 6;
    int yaw_idx = 7;
    int helices_view_order_idx = 8;
    var items = List<DialogItem>(9);
    items[name_idx] = DialogText(label: 'name', value: props.displayed_group_name);
    items[grid_idx] = DialogRadio(label: 'grid', options: grid_name_list, selected_idx: existing_grid_idx);
    items[position_x_idx] = DialogNumber(label: 'x', value: group.position.x);
    items[position_y_idx] = DialogNumber(label: 'y', value: group.position.y);
    items[position_z_idx] = DialogNumber(label: 'z', value: group.position.z);
    items[pitch_idx] = DialogNumber(label: 'pitch', value: group.pitch);
    items[roll_idx] = DialogNumber(label: 'roll', value: group.roll);
    items[yaw_idx] = DialogNumber(label: 'yaw', value: group.yaw);
    items[helices_view_order_idx] =
        DialogText(label: 'helices view order (space separated)', value: group.helices_view_order.join(' '));

    var dialog = Dialog(title: 'adjust current Helix group', items: items);
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

    // get grid
    String grid_name_chosen = (results[grid_idx] as DialogRadio).value;
    Grid grid_chosen = Grid.valueOf(grid_name_chosen);

    // get helices_view_order
    List<int> helices_view_order_old = group.helices_view_order.toList();
    helices_view_order_old.sort();
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
        if (!helices_view_order_old.contains(order)) {
          window.alert('${order} is not a valid helix index');
          return;
        }
        helices_view_order_chosen.add(order);
      }

      List<int> helices_view_order_chosen_sorted = List<int>.of(helices_view_order_chosen);
      helices_view_order_chosen_sorted.sort();
      if (helices_view_order_old != helices_view_order_chosen) {
        window.alert('The helix indices ${helices_view_order_old} must each appear exactly once.');
        return;
      }
    }

    // get position and orientation
    num position_x = (results[position_x_idx] as DialogNumber).value;
    num position_y = (results[position_y_idx] as DialogNumber).value;
    num position_z = (results[position_z_idx] as DialogNumber).value;
    num pitch = (results[pitch_idx] as DialogNumber).value;
    num roll = (results[roll_idx] as DialogNumber).value;
    num yaw = (results[yaw_idx] as DialogNumber).value;
    var position = Position3D(x: position_x, y: position_y, z: position_z);

    HelixGroup new_group = HelixGroup(
        grid: grid_chosen,
        helices_view_order: helices_view_order_chosen,
        position: position,
        pitch: pitch,
        roll: roll,
        yaw: yaw);

    app.dispatch(
        actions.GroupChange(old_name: props.displayed_group_name, new_name: new_name, new_group: new_group));
  }
}