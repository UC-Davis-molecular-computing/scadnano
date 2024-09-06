// @dart=2.9
import 'dart:html';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../state/group.dart';
import '../state/substrand.dart';
import '../app.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../extension_methods.dart';

check_reflect_strands_legal_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.StrandsReflect && action.strands.isNotEmpty) {
    List<Strand> strands_to_reflect = action.strands.toList();
    Design design = store.state.design;

    var group_names = design.group_names_of_strands(strands_to_reflect);
    if (group_names.length != 1) {
      var msg = 'Cannot reflect selected strands unless they are all on the same helix group.\n'
          '3 These strands occupy the following helix groups: ${group_names.join(", ")}';
      window.alert(msg);
      return;
    }
    String group_name = group_names.first;
    HelixGroup group = design.groups[group_name];

    List<Strand> reflected_strands = action.horizontal
        ? horizontal_reflection_of_strands(design, strands_to_reflect, action.reverse_polarity)
        : vertical_reflection_of_strands(group, strands_to_reflect, action.reverse_polarity);

    var altered_design = design.remove_strands(strands_to_reflect);
    altered_design = altered_design.add_strands(reflected_strands);

    try {
      altered_design.check_strands_overlap_legally();
    } on IllegalDesignError catch (e) {
      var msg = 'Cannot mirror these strands ${action.horizontal ? "horizontally" : "vertically"}\n'
          'Strands would overlap each other:\n\n${e.cause}';
      window.alert(msg);
      return;
    }

    Map<int, Strand> new_strands = {};
    int idx_mirrored_strand = 0;
    for (var strand in strands_to_reflect) {
      int idx = design.strands.indexOf(strand);
      assert(idx >= 0);
      new_strands[idx] = reflected_strands[idx_mirrored_strand];
      idx_mirrored_strand++;
    }

    var edit_action = actions.ReplaceStrands(new_strands: new_strands.build());
    store.dispatch(edit_action);
  } else {
    next(action);
  }
}

//XXX: it's critical that these functions return strands in the same order they were received because
// the ReplaceStrands action replaces them "in place" where the index of the original strand was.
List<Strand> horizontal_reflection_of_strands(
    Design design, List<Strand> strands_to_mirror, bool reverse_polarity) {
  int min_offset = [
    for (var strand in strands_to_mirror)
      for (var domain in strand.domains) domain.start
  ].min;
  int max_offset = [
    for (var strand in strands_to_mirror)
      for (var domain in strand.domains) domain.end
  ].max;

  List<Strand> mirrored_strands = [];
  for (var strand in strands_to_mirror) {
    List<Substrand> mirrored_substrands = strand.substrands.toList();
    for (int i = 0; i < mirrored_substrands.length; i++) {
      var domain = mirrored_substrands[i];
      if (domain is Domain) {
        int reflected_start = reflect_between_min_and_max(domain.start, min_offset, max_offset);
        int reflected_end = reflect_between_min_and_max(domain.end, min_offset, max_offset);
        List<int> reflected_deletions = reflect_deletions(domain, min_offset, max_offset);
        List<Insertion> reflected_insertions = reflect_insertions(domain, min_offset, max_offset);

        bool is_first =
            (i == 0 && !reverse_polarity) || (i == mirrored_substrands.length - 1 && reverse_polarity);

        bool is_last =
            (i == 0 && reverse_polarity) || (i == mirrored_substrands.length - 1 && !reverse_polarity);

        mirrored_substrands[i] = domain.rebuild((b) => b
          ..start = reflected_end
          ..end = reflected_start
          ..forward = reverse_polarity ? domain.forward : !domain.forward
          ..deletions.replace(reflected_deletions)
          ..insertions.replace(reflected_insertions)
          ..is_first = is_first
          ..is_last = is_last);
      }
    }
    if (reverse_polarity) {
      mirrored_substrands = List<Substrand>.of(mirrored_substrands.reversed);
    }
    var mirrored_strand = strand.rebuild((b) => b..substrands.replace(mirrored_substrands));
    mirrored_strand = mirrored_strand.initialize();
    mirrored_strands.add(mirrored_strand);
  }
  return mirrored_strands;
}

List<int> reflect_deletions(Domain domain, int min_offset, int max_offset) {
  List<int> reflected_deletions = [];
  for (var deletion in domain.deletions) {
    var reflected_deletion = reflect_between_min_and_max(deletion, min_offset, max_offset);
    reflected_deletions.add(reflected_deletion);
  }
  reflected_deletions.sort();
  return reflected_deletions;
}

List<Insertion> reflect_insertions(Domain domain, int min_offset, int max_offset) {
  List<Insertion> reflected_insertions = [];
  for (var insertion in domain.insertions) {
    var reflected_offset = reflect_between_min_and_max(insertion.offset, min_offset, max_offset);
    var reflected_insertion = insertion.rebuild((b) => b..offset = reflected_offset);
    reflected_insertions.add(reflected_insertion);
  }
  reflected_insertions.sort((i1, i2) => i1.offset - i2.offset);
  return reflected_insertions;
}

int reflect_between_min_and_max(int number, int min_num, int max_num) => max_num - number + min_num;

List<Strand> vertical_reflection_of_strands(
    HelixGroup group, List<Strand> strands_to_reflect, bool reverse_polarity) {
  // helix idxs occupied by strands
  var helix_idxs_involved = {
    for (var strand in strands_to_reflect)
      for (var domain in strand.domains) domain.helix
  };
  // vertical display order of those helices, sorted
  var helix_orders_involved = [for (int idx in helix_idxs_involved) group.helices_view_order_inverse[idx]];
  helix_orders_involved.sort();

  int min_order = helix_orders_involved.first;
  int max_order = helix_orders_involved.last;

  List<Strand> mirrored_strands = [];
  for (var strand in strands_to_reflect) {
    List<Substrand> mirrored_substrands = strand.substrands.toList();
    for (int i = 0; i < mirrored_substrands.length; i++) {
      var domain = mirrored_substrands[i];
      if (domain is Domain) {
        int helix_idx = domain.helix;
        int order = group.helices_view_order_inverse[helix_idx];
        int reflected_order = reflect_between_min_and_max(order, min_order, max_order);
        int reflected_helix_idx = group.helices_view_order[reflected_order];

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
      mirrored_substrands = List<Substrand>.of(mirrored_substrands.reversed);
    }
    var mirrored_strand = strand.rebuild((b) => b..substrands.replace(mirrored_substrands));
    mirrored_strand = mirrored_strand.initialize();
    mirrored_strands.add(mirrored_strand);
  }

  return mirrored_strands;
}
