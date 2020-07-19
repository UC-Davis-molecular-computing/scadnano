import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/adjust_grid_position.dart';
import 'package:scadnano/src/middleware/export_cadnano_or_codenano_file.dart';

import 'assign_dna.dart';
import 'check_mirror_strands_legal.dart';
import 'edit_select_mode_change.dart';
import 'example_design_selected.dart';
import 'export_dna_sequences.dart';
import 'dna_ends_move_start.dart';
import 'helix_grid_change.dart';
import 'helix_hide_all.dart';
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
import 'helices_positions_set_based_on_crossovers.dart';
import 'invalidate_png.dart';
import '../state/app_state.dart';

final all_middleware = List<Middleware<AppState>>.unmodifiable([
  local_storage_middleware,
  export_svg_middleware,
  save_file_middleware,
  load_file_middleware,
  export_cadnano_or_codenano_file_middleware,
  example_design_selected_middleware,
  throttle_middleware,
  assign_dna_middleware,
  strand_create_middleware,
  helix_remove_middleware,
  helix_change_offsets_middleware,
  helix_grid_offsets_middleware,
  helix_hide_all_middleware,
  helix_positions_set_based_on_crossovers_middleware,
  dna_ends_move_start_middleware,
  export_dna_sequences_middleware,
  reselect_moved_dna_ends_middleware,
  reselect_moved_strands_middleware,
  insertion_deletion_pairing_middleware,
  adjust_grid_position_middleware,
  invalidate_png_middleware,
  check_mirror_strands_legal_middleware,
  edit_select_mode_change_middleware,
]);
