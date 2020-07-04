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

List<ContextMenuItem> context_menu_helix(Helix helix, bool helix_change_apply_to_all) {
  Future<void> dialog_helix_adjust_length() async {
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix length', items: [
      DialogNumber(label: 'minimum', value: helix.min_offset),
      DialogNumber(label: 'maximum', value: helix.max_offset),
      DialogCheckbox(label: 'apply to all helices', value: helix_change_apply_to_all),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    int min_offset = (results[0] as DialogNumber).value;
    int max_offset = (results[1] as DialogNumber).value;
    bool apply_to_all = (results[2] as DialogCheckbox).value;

    if (min_offset >= max_offset) {
      window.alert('minimum offset ${min_offset} must be strictly less than maximum offset, '
          'but maximum offset is ${max_offset}');
      return;
    }

    if (apply_to_all) {
      app.dispatch(actions.HelixOffsetChangeAll(min_offset: min_offset, max_offset: max_offset));
    } else {
      app.dispatch(
          actions.HelixOffsetChange(helix_idx: helix_idx, min_offset: min_offset, max_offset: max_offset));
    }
  }

  Future<void> dialog_helix_adjust_roll() async {
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix roll (degrees)', items: [
      DialogFloatingNumber(label: 'roll', value: helix.roll),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    double roll = (results[0] as DialogFloatingNumber).value;
    roll = roll % 360;

    app.dispatch(actions.HelixRollSet(helix_idx: helix_idx, roll: roll));
  }

  Future<void> dialog_helix_adjust_major_tick_marks() async {
    int helix_idx = helix.idx;
    Grid grid = helix.grid;

    var dialog = Dialog(title: 'adjust helix tick marks', items: [
      DialogCheckbox(label: 'regular spacing', value: helix.major_tick_distance != null),
      DialogNumber(
          label: 'regular distance', value: helix.major_tick_distance ?? grid.default_major_tick_distance()),
      DialogText(
          label: 'varying major tick distances (space-separated)',
          value: helix.major_ticks == null ? '' : util.deltas(helix.major_ticks).join(' ')),
      DialogCheckbox(label: 'apply to all', value: helix_change_apply_to_all),
    ], disable_when_on: {
      2: 0
    }, disable_when_off: {
      1: 0
    });

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    bool use_major_tick_distance = (results[0] as DialogCheckbox).value;
    int major_tick_distance = (results[1] as DialogNumber).value;
    List<String> major_ticks_str =
        (results[2] as DialogText).value.trim().split(' ').where((token) => token.isNotEmpty).toList();
    bool apply_to_all = (results[3] as DialogCheckbox).value;

    List<int> major_ticks = [];
    if (!use_major_tick_distance && major_ticks_str.isNotEmpty) {
      for (var major_tick_str in major_ticks_str) {
        int major_tick = int.tryParse(major_tick_str);
        if (major_tick == null) {
          window.alert('"${major_tick_str}" is not a valid integer');
          return;
        } else if (major_tick <= 0 && major_ticks.isNotEmpty) {
          window.alert('non-positive value ${major_tick} can only be used if it is the first element '
              'in the list, specifying where the first tick should be; all others must be positive offsets '
              'from the previous tick mark');
          return;
        } else {
          major_ticks.add(major_tick + (major_ticks.isEmpty ? 0 : major_ticks.last));
        }
      }

      int t = major_ticks.firstWhere((t) => t < helix.min_offset, orElse: () => null);
      if (t != null) {
        window.alert('major tick ${t} is less than minimum offset ${helix.min_offset}');
        return;
      }

      // TODO: avoid global variable here if possible (move this logic to middleware)
      if (apply_to_all) {
        for (var other_helix in app.state.dna_design.helices.values) {
          t = major_ticks.firstWhere((t) => t < other_helix.min_offset, orElse: () => null);
          if (t != null) {
            window.alert('major tick ${t} is less than minimum offset ${other_helix.min_offset}');
            return;
          }
        }
//        for (var other_helix in app.state.dna_design.helices.values) {
//          t = major_ticks.firstWhere((t) => t > other_helix.max_offset, orElse: () => null);
//          if (t != null) {
//            window.alert("major tick ${t} is greater than maximum offset ${other_helix.max_offset}, "
//                "so I'm only going up to the major tick just before that");
//          }
//        }
      }
    }

    actions.Action action;
    if (apply_to_all) {
      if (use_major_tick_distance) {
        action = actions.HelixMajorTickDistanceChangeAll(major_tick_distance: major_tick_distance);
      } else {
        action = actions.HelixMajorTicksChangeAll(major_ticks: major_ticks.toBuiltList());
      }
    } else {
      if (use_major_tick_distance) {
        action = actions.HelixMajorTickDistanceChange(
            helix_idx: helix_idx, major_tick_distance: major_tick_distance);
      } else {
        action = actions.HelixMajorTicksChange(helix_idx: helix_idx, major_ticks: major_ticks.toBuiltList());
      }
    }
    app.dispatch(action);
  }

  Future<void> dialog_helix_adjust_grid_position() async {
    var grid_position = helix.grid_position ?? GridPosition(0, 0);

    var dialog = Dialog(title: 'adjust helix grid position', items: [
      DialogNumber(label: 'h', value: grid_position.h),
      DialogNumber(label: 'v', value: grid_position.v),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num h = (results[0] as DialogNumber).value;
    num v = (results[1] as DialogNumber).value;

    app.dispatch(actions.HelixGridPositionSet(helix: helix, grid_position: GridPosition(h, v)));
  }

  Future<void> dialog_helix_adjust_position() async {
    var position = helix.position ?? Position3D();

    var dialog = Dialog(title: 'adjust helix position', items: [
      DialogFloatingNumber(label: 'x', value: position.x),
      DialogFloatingNumber(label: 'y', value: position.y),
      DialogFloatingNumber(label: 'z', value: position.z),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num x = (results[0] as DialogFloatingNumber).value;
    num y = (results[1] as DialogFloatingNumber).value;
    num z = (results[2] as DialogFloatingNumber).value;

    // TODO: (check validity)
    app.dispatch(actions.HelixPositionSet(
        helix_idx: helix.idx,
        position: Position3D(
          x: x,
          y: y,
          z: z,
        )));
  }

  helix_adjust_length() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_length);
  }

  helix_adjust_major_tick_marks() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_major_tick_marks);
  }

  helix_adjust_roll() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_roll);
  }

  helix_adjust_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_position);
  }

  helix_adjust_grid_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_grid_position);
  }

  ContextMenuItem context_menu_item_adjust_position = (helix.grid == Grid.none)
      ? ContextMenuItem(
          title: 'adjust position',
          on_click: helix_adjust_position,
        )
      : ContextMenuItem(
          title: 'adjust grid position',
          on_click: helix_adjust_grid_position,
        );

  return [
    ContextMenuItem(
      title: 'adjust length',
      on_click: helix_adjust_length,
    ),
    ContextMenuItem(
      title: 'adjust tick marks',
      on_click: helix_adjust_major_tick_marks,
    ),
    ContextMenuItem(
      title: 'adjust roll',
      on_click: helix_adjust_roll,
    ),
    context_menu_item_adjust_position,
  ];
}
