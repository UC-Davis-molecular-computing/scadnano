import 'dart:html';

import 'package:built_collection/built_collection.dart';

import '../state/context_menu.dart';
import '../state/dialog.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import '../state/position3d.dart';
import '../state/helix.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

const SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION = "set helix tick marks";

BuiltList<ContextMenuItem> context_menu_helix(Helix helix, bool helix_change_apply_to_all) {
  Future<void> dialog_helix_set_min_offset() async {
    int min_idx = 0;
    int min_set_by_domain_idx = 1;
    int apply_to_all_idx = 2;

    var items = util.FixedList<DialogItem>(3);
    items[min_idx] = DialogInteger(label: 'minimum', value: helix.min_offset);
    items[min_set_by_domain_idx] = DialogCheckbox(label: 'set minimum by existing domains', value: false);
    items[apply_to_all_idx] = DialogCheckbox(label: 'apply to all helices', value: helix_change_apply_to_all);

    var dialog = Dialog(
      title: 'set helix minimum offset',
      type: DialogType.set_helix_minimum_offset,
      items: items,
      disable_when_any_checkboxes_on: {
        min_idx: [min_set_by_domain_idx],
      },
    );
    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    bool apply_to_all = (results[apply_to_all_idx] as DialogCheckbox).value;
    bool min_set_by_domain = (results[min_set_by_domain_idx] as DialogCheckbox).value;

    if (min_set_by_domain) {
      if (apply_to_all) {
        app.dispatch(actions.HelixMinOffsetSetByDomainsAll());
      } else {
        app.dispatch(actions.HelixMinOffsetSetByDomains(helix_idx: helix.idx));
      }
    } else {
      int min_offset = (results[min_idx] as DialogInteger).value;
      if (min_offset >= helix.max_offset) {
        window.alert(
          'minimum offset must be strictly less than maximum offset  ${helix.max_offset}, '
          'but you chose minimum offset ${min_offset}',
        );
        return;
      }
      if (apply_to_all) {
        app.dispatch(actions.HelixOffsetChangeAll(min_offset: min_offset));
      } else {
        app.dispatch(actions.HelixOffsetChange(helix_idx: helix.idx, min_offset: min_offset));
      }
    }
  }

  Future<void> dialog_helix_set_max_offset() async {
    int max_idx = 0;
    int max_set_by_domain_idx = 1;
    int apply_to_all_idx = 2;
    int take_max_of_all_idx = 3;

    var items = util.FixedList<DialogItem>(4);
    items[max_idx] = DialogInteger(label: 'maximum', value: helix.max_offset);
    items[max_set_by_domain_idx] = DialogCheckbox(label: 'set maximum by existing domains', value: false);
    items[apply_to_all_idx] = DialogCheckbox(label: 'apply to all helices', value: helix_change_apply_to_all);
    items[take_max_of_all_idx] = DialogCheckbox(label: 'give all same max', value: false);

    var dialog = Dialog(
      title: 'set helix maximum offset',
      type: DialogType.set_helix_maximum_offset,
      items: items,
      disable_when_any_checkboxes_on: {
        max_idx: [max_set_by_domain_idx],
      },
    );
    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    bool apply_to_all = (results[apply_to_all_idx] as DialogCheckbox).value;
    bool max_set_by_domain = (results[max_set_by_domain_idx] as DialogCheckbox).value;
    bool take_max_of_all = (results[take_max_of_all_idx] as DialogCheckbox).value;

    if (max_set_by_domain) {
      if (apply_to_all) {
        if (take_max_of_all) {
          app.dispatch(actions.HelixMaxOffsetSetByDomainsAllSameMax());
        } else {
          app.dispatch(actions.HelixMaxOffsetSetByDomainsAll());
        }
      } else {
        app.dispatch(actions.HelixMaxOffsetSetByDomains(helix_idx: helix.idx));
      }
    } else {
      int max_offset = (results[max_idx] as DialogInteger).value;
      if (helix.min_offset >= max_offset) {
        window.alert(
          'minimum offset ${helix.min_offset} must be strictly less than maximum offset, '
          'but you chose maximum offset ${max_offset}',
        );
        return;
      }
      if (apply_to_all) {
        app.dispatch(actions.HelixOffsetChangeAll(max_offset: max_offset));
      } else {
        app.dispatch(actions.HelixOffsetChange(helix_idx: helix.idx, max_offset: max_offset));
      }
    }
  }

  Future<void> dialog_helix_set_idx() async {
    var dialog = Dialog(
      title: 'set helix index',
      use_saved_response: false,
      type: DialogType.set_helix_index,
      items: [DialogInteger(label: 'new index', value: helix.idx)],
    );
    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    int new_idx = (results[0] as DialogInteger).value;

    app.dispatch(actions.HelixIdxsChange(idx_replacements: {helix.idx: new_idx}));
  }

  Future<void> dialog_helix_set_roll() async {
    int helix_idx = helix.idx;

    var dialog = Dialog(
      title: 'set helix roll (degrees)',
      type: DialogType.set_helix_roll_degrees,
      use_saved_response: false,
      items: [DialogFloat(label: 'roll', value: helix.roll)],
    );
    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    double roll = (results[0] as DialogFloat).value;
    roll = roll % 360;

    app.dispatch(actions.HelixRollSet(helix_idx: helix_idx, roll: roll));
  }

  Future<void> dialog_helix_set_major_tick_marks() async {
    int helix_idx = helix.idx;
    Grid grid = helix.grid;

    int default_regular_distance;
    List<int> default_periodic_distances;
    int default_start = helix.major_tick_start;
    if (helix.has_major_tick_distance) {
      default_regular_distance = helix.major_tick_distance!;
      default_periodic_distances = [default_regular_distance];
    } else if (helix.has_major_tick_periodic_distances) {
      default_regular_distance = helix.major_tick_periodic_distances.first;
      default_periodic_distances = helix.major_tick_periodic_distances.toList();
    } else {
      default_regular_distance = grid.default_major_tick_distance;
      default_periodic_distances = [default_regular_distance];
    }

    int regular_spacing_checkbox_idx = 0;
    int regular_spacing_distance_idx = 1;
    int major_tick_start_idx = 2;
    int periodic_spacing_checkbox_idx = 3;
    int periodic_spacing_distances_idx = 4;
    int major_ticks_checkbox_idx = 5;
    int major_ticks_distances_idx = 6;
    int apply_to_all_idx = 7;
    int apply_to_some_idx = 8;
    int apply_to_some_helices_idx = 9;
    var items = util.FixedList<DialogItem>(10);
    items[regular_spacing_checkbox_idx] = DialogCheckbox(
      label: 'regular spacing',
      value: helix.has_major_tick_distance,
    );
    items[regular_spacing_distance_idx] = DialogInteger(
      label: 'regular distance',
      value: default_regular_distance,
    );
    items[major_tick_start_idx] = DialogInteger(label: 'starting major tick', value: default_start);
    items[periodic_spacing_checkbox_idx] = DialogCheckbox(
      label: 'periodic spacing',
      value: helix.has_major_tick_periodic_distances,
    );
    items[periodic_spacing_distances_idx] = DialogText(
      label: 'periodic distances',
      value: "${default_periodic_distances.join(' ')}",
    );
    items[major_ticks_checkbox_idx] = DialogCheckbox(
      label: 'explicit list of major tick spacing',
      value: helix.has_major_ticks,
    );
    items[major_ticks_distances_idx] = DialogText(
      label: 'distances (space-separated)',
      value: helix.major_ticks == null ? '' : util.deltas(helix.major_ticks!).join(' '),
    );
    items[apply_to_all_idx] = DialogCheckbox(label: 'apply to all', value: helix_change_apply_to_all);
    items[apply_to_some_idx] = DialogCheckbox(label: 'apply to some', value: helix_change_apply_to_all);
    items[apply_to_some_helices_idx] = DialogText(label: 'helices (space-separated)', value: "");

    var dialog = Dialog(
      title: 'set helix tick marks',
      type: DialogType.set_helix_tick_marks,
      items: items,
      disable_when_any_checkboxes_off: {
        regular_spacing_distance_idx: [regular_spacing_checkbox_idx],
        periodic_spacing_distances_idx: [periodic_spacing_checkbox_idx],
        major_ticks_distances_idx: [major_ticks_checkbox_idx],
      },
      disable_when_any_checkboxes_on: {
        major_tick_start_idx: [major_ticks_checkbox_idx],
      },
      mutually_exclusive_checkbox_groups: [
        [regular_spacing_checkbox_idx, periodic_spacing_checkbox_idx, major_ticks_checkbox_idx],
        [apply_to_all_idx, apply_to_some_idx],
      ],
    );

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) {
      return;
    }

    bool use_major_tick_distance = (results[regular_spacing_checkbox_idx] as DialogCheckbox).value;
    bool use_major_tick_periodic_distances = (results[periodic_spacing_checkbox_idx] as DialogCheckbox).value;
    bool use_major_ticks = (results[major_ticks_checkbox_idx] as DialogCheckbox).value;
    if (!(use_major_tick_distance || use_major_tick_periodic_distances || use_major_ticks)) {
      return;
    }

    bool apply_to_all = (results[apply_to_all_idx] as DialogCheckbox).value;
    bool apply_to_some = (results[apply_to_some_idx] as DialogCheckbox).value;

    List<int>? major_ticks = null;
    int? major_tick_distance = null;
    List<int>? major_tick_periodic_distances = [];

    int major_tick_start = (results[major_tick_start_idx] as DialogInteger).value;
    if (major_tick_start < helix.min_offset) {
      window.alert('''\
${major_tick_start} is not a valid major tick because it is less than the 
minimum offset ${helix.min_offset} of helix ${helix.min_offset}.''');
      return;
    }

    if (use_major_ticks) {
      String major_ticks_str = (results[major_ticks_distances_idx] as DialogText).value;
      major_ticks = parse_major_ticks_and_check_validity(major_ticks_str, helix, apply_to_all);
      if (major_ticks == null) {
        return;
      }
    } else if (use_major_tick_distance) {
      major_tick_distance = (results[regular_spacing_distance_idx] as DialogInteger).value;
      if (major_tick_distance <= 0) {
        window.alert('${major_tick_distance} is not a valid distance because it is not positive.');
        return;
      }
    } else if (use_major_tick_periodic_distances) {
      String periodic_distances_str = (results[periodic_spacing_distances_idx] as DialogText).value;
      major_tick_periodic_distances = parse_major_tick_distances_and_check_validity(periodic_distances_str);
      if (major_tick_periodic_distances == null) {
        return;
      }
    } else {
      throw AssertionError('should not be reachable');
    }

    actions.Action action;
    if (apply_to_all) {
      if (use_major_tick_distance) {
        action = actions.BatchAction([
          actions.HelixMajorTickDistanceChangeAll(major_tick_distance: major_tick_distance!),
          actions.HelixMajorTickStartChangeAll(major_tick_start: major_tick_start),
        ], SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION);
      } else if (use_major_tick_periodic_distances) {
        action = actions.BatchAction([
          actions.HelixMajorTickPeriodicDistancesChangeAll(
            major_tick_periodic_distances: major_tick_periodic_distances.build(),
          ),
          actions.HelixMajorTickStartChangeAll(major_tick_start: major_tick_start),
        ], SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION);
      } else if (use_major_ticks) {
        action = actions.HelixMajorTicksChangeAll(major_ticks: major_ticks!.build());
      } else {
        throw AssertionError('should not be reachable');
      }
    } else if (apply_to_some) {
      String helix_idxs_str = (results[apply_to_some_helices_idx] as DialogText).value;
      List<int>? helix_idxs = parse_helix_idxs_and_check_validity(helix_idxs_str);
      if (helix_idxs == null) {
        return;
      }
      List<actions.UndoableAction> all_actions = [];
      for (int this_helix_idx in helix_idxs) {
        if (use_major_tick_distance) {
          all_actions.addAll([
            actions.HelixMajorTickDistanceChange(
              helix_idx: this_helix_idx,
              major_tick_distance: major_tick_distance!,
            ),
            actions.HelixMajorTickStartChange(helix_idx: this_helix_idx, major_tick_start: major_tick_start),
          ]);
        } else if (use_major_tick_periodic_distances) {
          all_actions.addAll([
            actions.HelixMajorTickPeriodicDistancesChange(
              helix_idx: this_helix_idx,
              major_tick_periodic_distances: major_tick_periodic_distances.build(),
            ),
            actions.HelixMajorTickStartChange(helix_idx: this_helix_idx, major_tick_start: major_tick_start),
          ]);
        } else if (use_major_ticks) {
          all_actions.add(
            actions.HelixMajorTicksChange(helix_idx: this_helix_idx, major_ticks: major_ticks!.build()),
          );
        } else {
          throw AssertionError('should not be reachable');
        }
      }
      action = actions.BatchAction(all_actions, SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION);
    } else {
      if (use_major_tick_distance) {
        action = actions.BatchAction([
          actions.HelixMajorTickDistanceChange(
            helix_idx: helix_idx,
            major_tick_distance: major_tick_distance!,
          ),
          actions.HelixMajorTickStartChange(helix_idx: helix_idx, major_tick_start: major_tick_start),
        ], SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION);
      } else if (use_major_tick_periodic_distances) {
        action = actions.BatchAction([
          actions.HelixMajorTickPeriodicDistancesChange(
            helix_idx: helix_idx,
            major_tick_periodic_distances: major_tick_periodic_distances.build(),
          ),
          actions.HelixMajorTickStartChange(helix_idx: helix_idx, major_tick_start: major_tick_start),
        ], SET_HELIX_TICK_MARKS_SHORT_DESCRIPTION);
      } else if (use_major_ticks) {
        action = actions.HelixMajorTicksChange(helix_idx: helix_idx, major_ticks: major_ticks!.build());
      } else {
        throw AssertionError('should not be reachable');
      }
    }
    app.dispatch(action);
  }

  Future<void> dialog_helix_set_grid_position() async {
    var grid_position = helix.grid_position ?? GridPosition(0, 0);

    var dialog = Dialog(
      title: 'set helix grid position',
      use_saved_response: false,
      type: DialogType.set_helix_grid_position,
      items: [
        DialogInteger(label: 'h', value: grid_position.h),
        DialogInteger(label: 'v', value: grid_position.v),
      ],
    );

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    int h = (results[0] as DialogInteger).value;
    int v = (results[1] as DialogInteger).value;

    app.dispatch(actions.HelixGridPositionSet(helix: helix, grid_position: GridPosition(h, v)));
  }

  Future<void> dialog_helix_set_position() async {
    var group = app.state.design.groups[helix.group]!;
    var geometry = group.geometry ?? app.state.design.geometry;
    var position = helix.position(geometry);

    var dialog = Dialog(
      title: 'set helix position',
      use_saved_response: false,
      type: DialogType.set_helix_position,
      items: [
        DialogFloat(label: 'x', value: position.x),
        DialogFloat(label: 'y', value: position.y),
        DialogFloat(label: 'z', value: position.z),
      ],
    );

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    double x = (results[0] as DialogFloat).value;
    double y = (results[1] as DialogFloat).value;
    double z = (results[2] as DialogFloat).value;

    // TODO: (check validity)
    app.dispatch(actions.HelixPositionSet(helix_idx: helix.idx, position: Position3D(x: x, y: y, z: z)));
  }

  Future<void> dialog_helix_set_group() async {
    // should be okay to access global variable here since it's responding to user click
    var group_names = app.state.design.groups.keys;

    List<int> selected_helix_idxs = [helix.idx];
    selected_helix_idxs.addAll(app.state.ui_state.side_selected_helix_idxs);

    var other_group_names = group_names.toList();
    var existing_group_name = helix.group;
    other_group_names.remove(existing_group_name);

    var dialog = Dialog(
      title: 'move selected helices to group',
      type: DialogType.move_selected_helices_to_group,
      items: [DialogRadio(options: other_group_names, radio: false, label: 'new group')],
    );

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    String existing_other_group_name = (results[0] as DialogRadio).value;

    var move_action = actions.MoveHelicesToGroup(
      helix_idxs: selected_helix_idxs.build(),
      group_name: existing_other_group_name,
    );
    app.dispatch(move_action);
  }

  helix_set_min_offset() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_min_offset);
  }

  helix_set_max_offset() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_max_offset);
  }

  helix_set_idx() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_idx);
  }

  helix_set_major_tick_marks() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_major_tick_marks);
  }

  helix_set_roll() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_roll);
  }

  helix_set_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_position);
  }

  helix_set_grid_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_grid_position);
  }

  helix_set_group() {
    app.disable_keyboard_shortcuts_while(dialog_helix_set_group);
  }

  ContextMenuItem context_menu_item_set_position =
      (helix.grid == Grid.none)
          ? ContextMenuItem(title: 'set position', on_click: helix_set_position)
          : ContextMenuItem(title: 'set grid position', on_click: helix_set_grid_position);

  return [
    ContextMenuItem(title: 'set min offset', on_click: helix_set_min_offset),
    ContextMenuItem(title: 'set max offset', on_click: helix_set_max_offset),
    ContextMenuItem(title: 'set index', on_click: helix_set_idx),
    ContextMenuItem(title: 'set tick marks', on_click: helix_set_major_tick_marks),
    ContextMenuItem(title: 'set roll', on_click: helix_set_roll),
    context_menu_item_set_position,
    ContextMenuItem(
      title: 'set group',
      on_click: helix_set_group,
      disabled: app.state.design.groups.length <= 1,
    ),
  ].build();
}

List<int>? parse_major_ticks_and_check_validity(String major_ticks_str, Helix helix, bool apply_to_all) {
  List<String> major_ticks_strs =
      major_ticks_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> major_ticks = [];
  for (var major_tick_str in major_ticks_strs) {
    int? major_tick = int.tryParse(major_tick_str);
    if (major_tick == null) {
      window.alert('"${major_tick_str}" is not a valid integer');
      return null;
    } else if (major_tick <= 0 && major_ticks.isNotEmpty) {
      window.alert('''\
non-positive value ${major_tick} can only be used if it is the first element 
in the list, specifying where the first tick should be; all others must be 
positive offsets from the previous tick mark''');
      return null;
    } else {
      major_ticks.add(major_tick + (major_ticks.isEmpty ? 0 : major_ticks.last));
    }
  }

  int? t;
  try {
    t = major_ticks.firstWhere((t) => t < helix.min_offset);
  } catch (_) {
    t = null;
  }
  if (t != null) {
    window.alert('major tick ${t} is less than minimum offset ${helix.min_offset}');
    return null;
  }

  // TODO: avoid global variable here if possible (move this logic to middleware)
  if (apply_to_all) {
    for (var other_helix in app.state.design.helices.values) {
      int? t;
      try {
        t = major_ticks.firstWhere((t) => t < other_helix.min_offset);
      } catch (_) {
        t = null;
      }
      if (t != null) {
        window.alert('major tick ${t} is less than minimum offset ${other_helix.min_offset}');
        return null;
      }
    }
  }
  return major_ticks;
}

List<int>? parse_major_tick_distances_and_check_validity(String major_tick_distances_str) {
  List<String> major_tick_distances_strs =
      major_tick_distances_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> major_tick_distances = [];
  for (var major_tick_distance_str in major_tick_distances_strs) {
    int? major_tick_distance = int.tryParse(major_tick_distance_str);
    if (major_tick_distance == null) {
      window.alert('"${major_tick_distance_str}" is not a valid integer');
      return null;
    } else if (major_tick_distance <= 0) {
      window.alert('${major_tick_distance} is not a valid distance because it is not positive.');
      return null;
    } else {
      major_tick_distances.add(major_tick_distance);
    }
  }

  return major_tick_distances;
}

List<int>? parse_helix_idxs_and_check_validity(String helix_idxs_str) {
  List<String> helix_idxs_strs = helix_idxs_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> helix_idxs = [];
  for (var helix_idx_str in helix_idxs_strs) {
    int? helix_idx = int.tryParse(helix_idx_str);
    if (helix_idx == null) {
      window.alert('"${helix_idx}" is not a valid integer');
      return null;
    } else if (!app.state.design.helices.keys.contains(helix_idx)) {
      // TODO: avoid global variable here if possible (move this logic to middleware)
      window.alert('${helix_idx} is not the index of any helix in this design');
      return null;
    } else {
      helix_idxs.add(helix_idx);
    }
  }

  return helix_idxs;
}
