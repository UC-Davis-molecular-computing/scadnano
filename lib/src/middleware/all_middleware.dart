import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/adjust_grid_position.dart';

//import 'thunk.dart';
import 'assign_dna.dart';
import 'example_dna_design_selected.dart';
import 'export_dna_sequences.dart';
import 'dna_ends_move_start.dart';
import 'grid_change.dart';
import 'helix_offsets_change.dart';
import 'insertion_deletion_pairing.dart';
import 'load_file.dart';
import 'reselect_moved_dna_ends.dart';
import 'reselect_moved_strands.dart';
import 'save_file.dart';
import 'export_svg.dart';
import 'local_storage.dart';
import 'strand_create.dart';
import 'throttle.dart';
import 'helix_remove.dart';
import '../state/app_state.dart';

final all_middleware = List<Middleware<AppState>>.unmodifiable([
//  thunk_middleware,
  local_storage_middleware,
  export_svg_main_middleware,
  export_svg_side_middleware,
  save_file_middleware,
  load_file_middleware,
  example_dna_design_selected_middleware,
  throttle_middleware,
  assign_dna_middleware,
  strand_create_middleware,
  helix_remove_middleware,
  helix_change_offsets_middleware,
  grid_change_middleware,
  dna_ends_move_start_middleware,
  export_dna_sequences_middleware,
  reselect_moved_dna_ends_middleware,
  reselect_moved_strands_middleware,
  insertion_deletion_pairing_middleware,
  adjust_grid_position_middleware,
]);
