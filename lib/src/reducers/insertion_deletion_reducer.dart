import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:tuple/tuple.dart';
import '../actions/actions.dart' as actions;
import '../state/domain.dart';
import '../state/strand.dart';
import '../state/substrand.dart';

Strand insertion_deletion_reducer(Strand strand, actions.InsertionOrDeletionAction action) {
  Domain domain = action.domain;

  //XXX: we can't simply look for the domain using indexOf, which uses == to test for equality.
  // The reason is that if we are processing multiple deletions (or insertions),
  // and if there is a DNA sequence assigned, then processing the first deletion will shift
  // the DNA sequence forward or backward, making the Domains unequal. Instead we check for stuff that
  // could not have changed as a result of this batch processing: helix, direction, start, end.
  int dom_idx = 0;
  bool found = false;
  for (var ss in strand.substrands) {
    if (ss is Domain &&
        ss.helix == domain.helix &&
        ss.forward == domain.forward &&
        ss.start == domain.start &&
        ss.end == domain.end) {
      found = true;
      break;
    }
    dom_idx++;
  }
  if (!found) {
    print('WARNING: could not find domain ${domain} on strand substrands: ${strand.substrands} '
        'when implementing action ${action}');
    return strand;
  }

  List<Substrand> substrands = strand.substrands.toList();
  substrands[dom_idx] = insertion_deletion_domain_reducer(domain, action);
  return strand.rebuild((b) => b..substrands.replace(substrands));
}

Reducer<Domain> insertion_deletion_domain_reducer = combineReducers([
  TypedReducer<Domain, actions.InsertionAdd>(insertion_add_reducer),
  TypedReducer<Domain, actions.InsertionRemove>(insertion_remove_reducer),
  TypedReducer<Domain, actions.DeletionAdd>(deletion_add_reducer),
  TypedReducer<Domain, actions.DeletionRemove>(deletion_remove_reducer),
  TypedReducer<Domain, actions.InsertionLengthChange>(insertion_length_change_reducer),
]);

Domain insertion_add_reducer(Domain domain, actions.InsertionAdd action) {
  List<Insertion> insertions = domain.insertions.toList();
  List<int> insertion_offsets = [for (var insertion in insertions) insertion.offset];
  if (!insertion_offsets.contains(action.offset)) {
    insertions.add(Insertion(action.offset, 1));
    insertions.sort((i1, i2) => i1.offset - i2.offset);
  }
  return domain.rebuild((b) => b..insertions.replace(insertions));
}

Domain insertion_remove_reducer(Domain domain, actions.InsertionRemove action) {
  List<Insertion> insertions = domain.insertions.toList();
  insertions.remove(action.insertion);
  return domain.rebuild((b) => b..insertions.replace(insertions));
}

Domain deletion_add_reducer(Domain domain, actions.DeletionAdd action) {
  List<int> deletions = domain.deletions.toList();
  if (!deletions.contains(action.offset)) {
    deletions.add(action.offset);
    deletions.sort();
  }
  return domain.rebuild((b) => b..deletions.replace(deletions));
}

Domain deletion_remove_reducer(Domain domain, actions.DeletionRemove action) {
  List<int> deletions = domain.deletions.toList();
  deletions.remove(action.offset);
  return domain.rebuild((b) => b..deletions.replace(deletions));
}

Domain insertion_length_change_reducer(Domain domain, actions.InsertionLengthChange action) {
  List<Insertion> insertions = domain.insertions.toList();
  int idx = insertions.indexOf(action.insertion);
  Insertion changed_insertion = action.insertion.rebuild((i) => i..length = action.length);
  insertions[idx] = changed_insertion;
  return domain.rebuild((b) => b..insertions.replace(insertions));
}

BuiltList<Strand> insertions_length_change_reducer(
    BuiltList<Strand> strands, AppState state, actions.InsertionsLengthChange action) {
  assert(action.insertions.length == action.domains.length);

  Map<String, Map<Domain, List<Insertion>>> insertions_on_strand_id_domain = {};
  for (int i=0; i<action.insertions.length; i++) {
    Insertion insertion = action.insertions[i];
    Domain domain = action.domains[i];

    String strand_id = domain.strand_id;
    if (!insertions_on_strand_id_domain.containsKey(strand_id)) {
      insertions_on_strand_id_domain[strand_id] = {};
    }

    Map<Domain, List<Insertion>> insertions_on_domain = insertions_on_strand_id_domain[strand_id];
    if (!insertions_on_domain.containsKey(domain)) {
      insertions_on_domain[domain] = [];
    }
    insertions_on_domain[domain].add(insertion);
  }

  var strands_builder = strands.toBuilder();
  for (String strand_id in insertions_on_strand_id_domain.keys) {
    Strand strand = state.design.strands_by_id[strand_id];
    int strand_idx = strands.indexOf(strand);

    var substrands = strand.substrands.toList();

    Map<Domain, List<Insertion>> insertions_on_domains = insertions_on_strand_id_domain[strand_id];
    for (Domain domain in insertions_on_domains.keys) {
      List<Insertion> insertions_to_change = insertions_on_domains[domain];
      List<Insertion> existing_insertions = domain.insertions.toList();
      for (Insertion insertion in insertions_to_change) {
        int idx = existing_insertions.indexOf(insertion);
        Insertion new_insertion = insertion.rebuild((b) => b..length=action.length);
        existing_insertions[idx] = new_insertion;
      }
      Domain new_domain = domain.rebuild((b) => b..insertions.replace(existing_insertions));
      int domain_idx = substrands.indexOf(domain);
      substrands[domain_idx] = new_domain;
    }

    var new_strand = strand.rebuild((s) => s..substrands.replace(substrands));
    new_strand = new_strand.initialize();
    strands_builder[strand_idx] = new_strand;
  }

  return strands_builder.build();
}
