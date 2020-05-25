import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';

Strand insertion_deletion_reducer(Strand strand, actions.InsertionOrDeletionAction action) {
  Domain substrand = action.substrand;
  int ss_idx = strand.substrands.indexOf(substrand);
  List<Substrand> substrands = strand.substrands.toList();
  substrands[ss_idx] = insertion_deletion_substrand_reducer(substrand, action);
  return strand.rebuild((b) => b..substrands.replace(substrands));
}

Reducer<Domain> insertion_deletion_substrand_reducer = combineReducers([
  TypedReducer<Domain, actions.InsertionLengthChange>(insertion_length_change_reducer),
  TypedReducer<Domain, actions.InsertionAdd>(insertion_add_reducer),
  TypedReducer<Domain, actions.InsertionRemove>(insertion_remove_reducer),
  TypedReducer<Domain, actions.DeletionAdd>(deletion_add_reducer),
  TypedReducer<Domain, actions.DeletionRemove>(deletion_remove_reducer),
]);

Domain insertion_length_change_reducer(
    Domain substrand, actions.InsertionLengthChange action) {
  List<Insertion> insertions = substrand.insertions.toList();
  int idx = insertions.indexOf(action.insertion);
  Insertion changed_insertion = action.insertion.rebuild((i) => i..length = action.length);
  insertions[idx] = changed_insertion;
  return substrand.rebuild((b) => b..insertions.replace(insertions));
}

Domain insertion_add_reducer(Domain substrand, actions.InsertionAdd action) {
  List<Insertion> insertions = substrand.insertions.toList();
  insertions.add(Insertion(action.offset, 1));
  return substrand.rebuild((b) => b..insertions.replace(insertions));
}

Domain insertion_remove_reducer(Domain substrand, actions.InsertionRemove action) {
  List<Insertion> insertions = substrand.insertions.toList();
  insertions.remove(action.insertion);
  return substrand.rebuild((b) => b..insertions.replace(insertions));
}

Domain deletion_add_reducer(Domain substrand, actions.DeletionAdd action) {
  List<int> deletions = substrand.deletions.toList();
  deletions.add(action.offset);
  return substrand.rebuild((b) => b..deletions.replace(deletions));
}

Domain deletion_remove_reducer(Domain substrand, actions.DeletionRemove action) {
  List<int> deletions = substrand.deletions.toList();
  deletions.remove(action.offset);
  return substrand.rebuild((b) => b..deletions.replace(deletions));
}
