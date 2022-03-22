import 'package:redux/redux.dart';
import 'package:scadnano/src/state/group.dart';
import '../state/domain.dart';
import '../state/design.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Ensures that actions on insertions and deletions happen in pairs on adjacent domains.
/// Alternately, if Ctrl is pressed when the deletion/insertion is added, then it is added to every
/// domain in that HelixGroup at that offset.
insertion_deletion_batching_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.InsertionOrDeletionAction) {
    if (action.all_helices) {
      // add deletion/insertion to all domains at this offset on all helices in same helix group
      List<Domain> other_domains = find_other_domains(store.state.design, action.domain, action.offset);
      if (other_domains.isEmpty) {
        next(action);
      } else {
        var other_actions = [
          for (var other_domain in other_domains) action.clone_for_other_domain(other_domain)
        ];
        var batch_action = actions.BatchAction([action] + other_actions, action.short_description());
        store.dispatch(batch_action);
      }
    } else {
      // add deletion/insertion to other domain at this offset on this helix, if it exists
      Domain paired_domain = find_paired_domain(store.state.design, action.domain, action.offset);
      if (paired_domain == null) {
        next(action);
      } else {
        var other_action = action.clone_for_other_domain(paired_domain);
        var batch_action = actions.BatchAction([action, other_action], action.short_description());
        store.dispatch(batch_action);
      }
    }
  } else {
    next(action);
  }
}

/// find all domains on other helices (including other direction on this helix)
/// in same HelixGroup as [domain].
List<Domain> find_other_domains(Design design, Domain domain, int offset) {
  String group_name = design.group_name_of_domain(domain);
  var helix_idxs_in_group = design.helix_idxs_in_group[group_name];
  List<Domain> other_domains = [];
  for (var helix_idx in helix_idxs_in_group) {
    if (helix_idx == domain.helix) {
      var paired_domain = find_paired_domain(design, domain, offset);
      if (paired_domain != null) {
        other_domains.add(paired_domain);
      }
    } else {
      // only add to domains that don't have this offset as start or end
      var other_domains_on_helix = design.domains_on_helix_at_offset_internal(helix_idx, offset);
      other_domains.addAll(other_domains_on_helix);
    }
  }
  return other_domains;
}

Domain find_paired_domain(Design design, Domain domain, int offset) {
  var other_domains = design.domains_on_helix_at_offset_internal(domain.helix, offset);
  for (var other_domain in other_domains) {
    if (other_domain != domain) {
      assert(other_domain.forward != domain.forward);
      return other_domain;
    }
  }
  return null;
}
