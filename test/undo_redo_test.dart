import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

import 'utils.dart';

main() {
  group('multiple_undos', () {
    test('multiple_undos_should_pop_undo_stack', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design4).rebuild((b) => b
        ..undo_redo.undo_stack.replace(
          [
            UndoRedoItem("action from 1 to 2", design1),
            UndoRedoItem("action from 2 to 3", design2),
            UndoRedoItem("action from 3 to 4", design3)
          ],
        ));

      AppState new_state = app_state_reducer(state, Undo(2));

      expect(new_state.undo_redo.undo_stack, [UndoRedoItem("action from 1 to 2", design1)].build());
    });

    test('multiple_undos_should_set_current_design', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design4).rebuild((b) => b
        ..undo_redo.undo_stack.replace(
          [
            UndoRedoItem("action from 1 to 2", design1),
            UndoRedoItem("action from 2 to 3", design2),
            UndoRedoItem("action from 3 to 4", design3)
          ],
        ));

      AppState new_state = app_state_reducer(state, Undo(2));

      expect_design_equal(new_state.design, design2);
    });

    test('multiple_undos_should_push_to_redo_stack', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design4).rebuild((b) => b
        ..undo_redo.undo_stack.replace(
          [
            UndoRedoItem("action from 1 to 2", design1),
            UndoRedoItem("action from 2 to 3", design2),
            UndoRedoItem("action from 3 to 4", design3)
          ],
        ));

      AppState new_state = app_state_reducer(state, Undo(2));

      expect(
          new_state.undo_redo.redo_stack,
          [
            UndoRedoItem("action from 3 to 4", design4),
            UndoRedoItem("action from 2 to 3", design3),
          ].build());
    });
  });

  group('multiple_redos', () {
    test('multiple_redos_should_pop_redo_stack', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design2).rebuild(
        (b) => b
          ..undo_redo.undo_stack.replace(
            [
              UndoRedoItem("action from 1 to 2", design1),
            ],
          )
          ..undo_redo.redo_stack.replace(
            [
              UndoRedoItem("action from 3 to 4", design4),
              UndoRedoItem("action from 2 to 3", design3),
            ],
          ),
      );

      AppState new_state = app_state_reducer(state, Redo(2));

      expect(new_state.undo_redo.redo_stack.isEmpty, true);
    });

    test('multiple_redos_should_set_current_state', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design2).rebuild(
        (b) => b
          ..undo_redo.undo_stack.replace(
            [
              UndoRedoItem("action from 1 to 2", design1),
            ],
          )
          ..undo_redo.redo_stack.replace(
            [
              UndoRedoItem("action from 3 to 4", design4),
              UndoRedoItem("action from 2 to 3", design3),
            ],
          ),
      );

      AppState new_state = app_state_reducer(state, Redo(2));

      expect(new_state.design, design4);
    });

    test('multiple_redos_should_push_to_undo_stack', () {
      Design design1 = Design(grid: Grid.square);
      Design design2 = Design(grid: Grid.hex);
      Design design3 = Design(grid: Grid.honeycomb);
      Design design4 = Design(grid: Grid.none);
      AppState state = app_state_from_design(design2).rebuild(
        (b) => b
          ..undo_redo.undo_stack.replace(
            [
              UndoRedoItem("action from 1 to 2", design1),
            ],
          )
          ..undo_redo.redo_stack.replace(
            [
              UndoRedoItem("action from 3 to 4", design4),
              UndoRedoItem("action from 2 to 3", design3),
            ],
          ),
      );

      AppState new_state = app_state_reducer(state, Redo(2));

      expect(new_state.undo_redo.undo_stack, [
        UndoRedoItem("action from 1 to 2", design1),
        UndoRedoItem("action from 2 to 3", design2),
        UndoRedoItem("action from 3 to 4", design3)
      ]);
    });
  });
}
