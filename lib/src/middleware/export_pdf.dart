import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/state/app_state.dart';

export_pdf_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is ExportPdf) {
    // TODO
    print("Running the export PDF action!");
    print(action.type);
  } else {
    next(action);
  }
}
