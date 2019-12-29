import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';

Strand insertion_deletion_reducer(Strand strand, actions.InsertionOrDeletionAction action) {
  BoundSubstrand substrand = action.bound_substrand;
  int ss_idx = strand.substrands.indexOf(substrand);
  List<Substrand> substrands = strand.substrands.toList();
  substrands[ss_idx] = insertion_deletion_substrand_reducer(substrand, action);
  return strand.rebuild((b) => b..substrands.replace(substrands));
}

Reducer<BoundSubstrand> insertion_deletion_substrand_reducer = combineReducers([
  TypedReducer<BoundSubstrand, actions.InsertionAdd>(insertion_add_reducer),
  TypedReducer<BoundSubstrand, actions.InsertionRemove>(insertion_remove_reducer),
  TypedReducer<BoundSubstrand, actions.DeletionAdd>(deletion_add_reducer),
  TypedReducer<BoundSubstrand, actions.DeletionRemove>(deletion_remove_reducer),
]);

BoundSubstrand insertion_add_reducer(BoundSubstrand substrand, actions.InsertionAdd action) {
  List<Insertion> insertions = substrand.insertions.toList();
  insertions.add(Insertion(action.offset, action.length));
  return substrand.rebuild((b) => b..insertions.replace(insertions));
}

BoundSubstrand insertion_remove_reducer(BoundSubstrand substrand, actions.InsertionRemove action) {
  List<Insertion> insertions = substrand.insertions.toList();
  insertions.remove(action.insertion);
  return substrand.rebuild((b) => b..insertions.replace(insertions));
}

BoundSubstrand deletion_add_reducer(BoundSubstrand substrand, actions.DeletionAdd action) {
  List<int> deletions = substrand.deletions.toList();
  deletions.add(action.offset);
  return substrand.rebuild((b) => b..deletions.replace(deletions));
}

BoundSubstrand deletion_remove_reducer(BoundSubstrand substrand, actions.DeletionRemove action) {
  List<int> deletions = substrand.deletions.toList();
  deletions.remove(action.deletion);
  return substrand.rebuild((b) => b..deletions.replace(deletions));
}
