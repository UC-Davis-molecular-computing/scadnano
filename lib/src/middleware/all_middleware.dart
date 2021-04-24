import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart';

import 'forbid_create_circular_strand_no_crossovers_middleware.dart';
import 'helix_group_move_start.dart';
import 'adjust_grid_position.dart';
import 'export_cadnano_or_codenano_file.dart';
import 'assign_dna.dart';
import 'check_mirror_strands_legal.dart';
import 'edit_select_mode_change.dart';
import 'example_design_selected.dart';
import 'export_dna_sequences.dart';
import 'dna_ends_move_start.dart';
import 'group_remove.dart';
import 'helix_grid_change.dart';
import 'helix_hide_all.dart';
import 'helix_idxs_change.dart';
import 'helix_offsets_change.dart';
import 'insertion_deletion_batching.dart';
import 'load_file.dart';
import 'periodic_save_design_local_storage.dart';
import 'reselect_moved_dna_ends.dart';
import 'reselect_moved_copied_strands.dart';
import 'save_file.dart';
import 'export_svg.dart';
import 'local_storage.dart';
import 'selections_intersect_box_compute.dart';
import 'strand_create.dart';
import 'move_ensure_same_group.dart';
import 'throttle.dart';
import 'helix_remove.dart';
import 'helices_positions_set_based_on_crossovers.dart';
import 'invalidate_png.dart';
import 'autostaple_and_autobreak.dart';
import '../state/app_state.dart';

final all_middleware = List<Middleware<AppState>>.unmodifiable([
  local_storage_middleware,
  move_ensure_all_in_same_helix_group_middleware,
  forbid_create_circular_strand_no_crossovers_middleware,
  export_svg_middleware,
  save_file_middleware,
  load_file_middleware,
  export_cadnano_or_codenano_file_middleware,
  example_design_selected_middleware,
  throttle_middleware,
  assign_dna_middleware,
  strand_create_middleware,
  helix_remove_middleware,
  group_remove_middleware,
  helix_group_move_start_middleware,
  helix_change_offsets_middleware,
  helix_idxs_change_middleware,
  helix_grid_offsets_middleware,
  helix_hide_all_middleware,
  helix_positions_set_based_on_crossovers_middleware,
  dna_ends_move_start_middleware,
  export_dna_sequences_middleware,
  reselect_moved_dna_ends_middleware,
  reselect_moved_copied_strands_middleware,
  selections_intersect_box_compute_middleware,
  insertion_deletion_batching_middleware,
  adjust_grid_position_middleware,
  invalidate_png_middleware,
  check_reflect_strands_legal_middleware,
  edit_select_mode_change_middleware,
  periodic_design_save_local_storage_middleware,
  autostaple_and_autobreak_middleware,
  system_clipboard_middleware,
]);
