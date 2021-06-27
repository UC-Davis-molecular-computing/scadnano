import 'package:redux/redux.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:tuple/tuple.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/grid_position.dart';
import '../state/helix.dart';

/// Disallows setting grid_position of Helix to overlap with existing helix.
oxdna_export_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixGridPositionSet) {

  }
  next(action);

}

Tuple2<String, String> to_oxdna_format(Design design) {
  String dat, top;
  throw UnsupportedError('TODO: implement OxDNA export');
  return Tuple2<String, String>(dat, top);
}
