import 'package:redux/redux.dart';

import '../app.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

export_dna_sequences_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);

  AppState state = store.state;
  if (action is actions.ExportDNA) {
    List<Strand> strands = state.design.strands.toList();
    if (!action.include_scaffold) {
      strands.removeWhere((strand) => strand.is_scaffold);
    }

    String filename = 'sequences.' + action.export_dna_format.extension();
    util.BlobType blob_type = action.export_dna_format.blob_type();

    action.export_dna_format
        .export(strands)
        .then((content) => util.save_file(filename, content, blob_type: blob_type))
        .catchError((e, stackTrace) {
      var msg = e.cause + '\n\n' + stackTrace.toString();
      store.dispatch(actions.ErrorMessageSet(msg));
      app.view.design_view.render(store.state);
    });
  }
}
