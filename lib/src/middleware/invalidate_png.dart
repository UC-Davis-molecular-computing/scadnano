import 'package:redux/redux.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

/// Invalidates the png middleware if action would modify the dna design.
invalidate_png_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.SvgPngCacheInvalidatingAction && store.state.ui_state.dna_sequence_png_uri != null) {
    store.dispatch(actions.LoadDnaSequenceImageUri(null));
  } else if (action is actions.HelixSelectSvgPngCacheInvalidatingAction &&
      store.state.ui_state.only_display_selected_helices &&
      store.state.ui_state.dna_sequence_png_uri != null) {
    store.dispatch(actions.LoadDnaSequenceImageUri(null));
  }
  next(action);
}
