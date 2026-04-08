import 'package:react/react.dart';
import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano_state/src/state/extension.dart';

import 'package:scadnano_state/src/state/domain.dart';
import 'package:scadnano_state/src/state/dna_end.dart';
import 'package:scadnano_state/src/state/dna_extensions_move.dart';
import 'package:scadnano_state/src/state/address.dart';
import 'package:scadnano_state/src/actions/actions.dart' as actions;
import 'package:scadnano_state/src/state/app_state.dart';

reselect_moved_dna_extension_ends_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.DNAExtensionsMoveCommit && action.dna_extensions_move.moves.length > 1) {
    // only reselect if there is more than 1 selected, otherwise this builds up many selected items
    // as the user repeatedly clicks on one at a time

    List<String> extension_ids = [];

    // first collect addresses while design.end_to_substrand is still valid
    for (DNAExtensionMove move in action.dna_extensions_move.moves) {
      DNAEnd old_end = move.dna_end;
      Extension old_extension = store.state.design.end_to_extension[old_end]!;
      extension_ids.add(old_extension.id);
    }

    // then apply action
    next(action);

    // now find new ends at given addresses
    List<DNAEnd> new_ends = [];
    for (var extension_id in extension_ids) {
      Extension extension = store.state.design.extensions_by_id[extension_id]!;
      new_ends.add(extension.dnaend_free);
    }
    store.dispatch(actions.SelectAll(selectables: new_ends.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
