import 'dart:html';
import 'dart:math';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../state/substrand.dart';
import '../app.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

check_mirror_strands_legal_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.StrandsMirror && action.strands.isNotEmpty) {
    List<Strand> strands_to_mirror = action.strands.toList();
    Design design = store.state.design;

    List<Strand> mirrored_strands = action.horizontal
        ? horizontal_mirror_of_strands(design, strands_to_mirror, action.reverse_polarity)
        : vertical_mirror_of_strands(design, strands_to_mirror, action.reverse_polarity);

    var altered_design = design.remove_strands(strands_to_mirror);
    altered_design = altered_design.add_strands(mirrored_strands);

    try {
      altered_design.check_strands_overlap_legally();
    } on IllegalDNADesignError catch (e) {
      var msg = 'Cannot mirror these strands ${action.horizontal ? "horizontally" : "vertically"}\n'
          'Strands would overlap each other:\n\n${e.cause}';
      window.alert(msg);
      return;
    }

    Map<int, Strand> new_strands = {};
    int idx_mirrored_strand = 0;
    for (var strand in strands_to_mirror) {
      int idx = design.strands.indexOf(strand);
      assert(idx >= 0);
      new_strands[idx] = mirrored_strands[idx_mirrored_strand];
      idx_mirrored_strand++;
    }

    var edit_action = actions.ReplaceStrands(new_strands: new_strands.build());
    app.dispatch_async(edit_action);
  } else {
    next(action);
  }
}

//XXX: it's critical that these functions return strands in the same order they were received because
// the ReplaceStrands action replaces them "in place" where the index of the original strand was.
List<Strand> horizontal_mirror_of_strands(
    Design design, List<Strand> strands_to_mirror, bool reverse_polarity) {
  int min_offset =
      [for (var strand in strands_to_mirror) for (var domain in strand.domains()) domain.start].reduce(min);
  int max_offset =
      [for (var strand in strands_to_mirror) for (var domain in strand.domains()) domain.end].reduce(max);

  List<Strand> mirrored_strands = [];
  for (var strand in strands_to_mirror) {
    List<Substrand> mirrored_substrands = strand.substrands.toList();
    for (int i = 0; i < mirrored_substrands.length; i++) {
      var domain = mirrored_substrands[i];
      if (domain is Domain) {
        int reflected_start = reflect_between_min_and_max(domain.start, min_offset, max_offset);
        int reflected_end = reflect_between_min_and_max(domain.end, min_offset, max_offset);

        bool is_first =
            (i == 0 && !reverse_polarity) || (i == mirrored_substrands.length - 1 && reverse_polarity);

        bool is_last =
            (i == 0 && reverse_polarity) || (i == mirrored_substrands.length - 1 && !reverse_polarity);

        mirrored_substrands[i] = domain.rebuild((b) => b
          ..start = reflected_end
          ..end = reflected_start
          ..forward = reverse_polarity ? domain.forward : !domain.forward
          ..is_first = is_first
          ..is_last = is_last);
      }
    }
    if (reverse_polarity) {
      mirrored_substrands = List<Substrand>.from(mirrored_substrands.reversed);
    }
    var mirrored_strand = strand.rebuild((b) => b..substrands.replace(mirrored_substrands));
    mirrored_strand = mirrored_strand.initialize();
    mirrored_strands.add(mirrored_strand);
  }
  return mirrored_strands;
}

int reflect_between_min_and_max(int number, int min_num, int max_num) => max_num - number + min_num;

List<Strand> vertical_mirror_of_strands(
    Design design, List<Strand> strands_to_mirror, bool reverse_polarity) {
  // helix idxs occupied by strands
  var helix_idxs_involved = {
    for (var strand in strands_to_mirror) for (var domain in strand.domains()) domain.helix
  };
  // vertical display order of those helices, sorted
  var helix_orders_involved = [for (int idx in helix_idxs_involved) design.helices_view_order_inverse[idx]];
  helix_orders_involved.sort();

  int min_order = helix_orders_involved.first;
  int max_order = helix_orders_involved.last;

  List<Strand> mirrored_strands = [];
  for (var strand in strands_to_mirror) {
    List<Substrand> mirrored_substrands = strand.substrands.toList();
    for (int i = 0; i < mirrored_substrands.length; i++) {
      var domain = mirrored_substrands[i];
      if (domain is Domain) {
        int helix_idx = domain.helix;
        int order = design.helices_view_order_inverse[helix_idx];
        int reflected_order = reflect_between_min_and_max(order, min_order, max_order);
        int reflected_helix_idx = design.helices_view_order[reflected_order];

        bool is_first =
            (i == 0 && reverse_polarity) || (i == mirrored_substrands.length - 1 && !reverse_polarity);

        bool is_last =
            (i == 0 && !reverse_polarity) || (i == mirrored_substrands.length - 1 && reverse_polarity);

        mirrored_substrands[i] = domain.rebuild((b) => b
          ..helix = reflected_helix_idx
          ..forward = reverse_polarity ? domain.forward : !domain.forward
          ..is_first = is_first
          ..is_last = is_last);
      }
    }
    if (!reverse_polarity) {
      mirrored_substrands = List<Substrand>.from(mirrored_substrands.reversed);
    }
    var mirrored_strand = strand.rebuild((b) => b..substrands.replace(mirrored_substrands));
    mirrored_strand = mirrored_strand.initialize();
    mirrored_strands.add(mirrored_strand);
  }

  return mirrored_strands;
}
