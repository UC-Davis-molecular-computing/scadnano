import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

/// Invalidates the png middleware if action would modify the dna design.
invalidate_png_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.DNADesignChangingAction && store.state.ui_state.dna_sequence_png_uri != null) {
    store.dispatch(actions.LoadDnaSequenceImageUri(null));
  }
  next(action);
}
