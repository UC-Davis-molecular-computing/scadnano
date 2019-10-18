import 'package:w_flux/src/action.dart';

import '../app.dart';
import '../dispatcher/actions.dart';

import 'bound_substrand.dart';
import 'crossover.dart';
import 'dna_design.dart';
import 'helix.dart';
import 'loopout.dart';
import 'selectable.dart';
import 'strand.dart';

/// Represents action to delete all given items, assuming they have already been trimmed of redundancies
/// (e.g., no crossover to delete is on a strand that is to be deleted also)
class DeleteAllParameters {
  DNADesign dna_design;
  Set<Strand> strands = {};
  Set<Crossover> crossovers = {};
  Set<Loopout> loopouts = {};
  Set<BoundSubstrand> substrands = {};
  bool reverse_deletion;

  DeleteAllParameters(this.dna_design, this.strands, this.crossovers, this.loopouts, this.substrands,
      {this.reverse_deletion = false});
}

class DeleteAllActionPack extends ReversibleActionPack<Action<DeleteAllParameters>, DeleteAllParameters> {
  DeleteAllParameters params;

  DNADesign get dna_design => params.dna_design;

  Set<Strand> get strands_to_delete => params.strands;

  Set<Crossover> get crossovers_to_delete => params.crossovers;

  Set<Loopout> get loopouts_to_delete => params.loopouts;

  Set<BoundSubstrand> get substrands_to_delete => params.substrands;

  bool get reverse_deletion => params.reverse_deletion;

  DeleteAllActionPack(this.params) : super(Actions.delete_all, params);

  @override
  DeleteAllActionPack reverse() {
    DeleteAllParameters reverse_params = DeleteAllParameters(
        params.dna_design, params.strands, params.crossovers, params.loopouts, params.substrands,
        reverse_deletion: true);
    return DeleteAllActionPack(reverse_params);
  }

  delete_strand(Strand strand) {
    for (var substrand in strand.bound_substrands()) {
      Helix helix = dna_design.helices[substrand.helix];
      helix.bound_substrands().remove(substrand);
    }
    dna_design.strands.remove(strand);
  }

  delete_crossover(Crossover crossover) {
    BoundSubstrand prev_substrand = crossover.prev_substrand;
    BoundSubstrand next_substrand = crossover.next_substrand;
    Strand strand = prev_substrand.strand;
//    Strand strand_next = Strand(sub);
    //TODO: finish this
  }

  delete_loopout(Loopout loopout) {
    //TODO: finish this
  }

  delete_substrand(BoundSubstrand substrand) {
    //TODO: finish this
  }
}

delete_all(DNADesign dna_design, List<Selectable> selected_items) {
  Set<Strand> strands = {};
  Set<Crossover> crossovers = {};
  Set<Loopout> loopouts = {};
  Set<BoundSubstrand> substrands = {};

  split_selectables_by_type(selected_items, strands, crossovers, loopouts, substrands);
  trim_selectables_to_delete(strands, crossovers, loopouts, substrands);

  var delete_all_params =
      DeleteAllParameters(dna_design, strands, crossovers, loopouts, substrands);
  app.send_action(DeleteAllActionPack(delete_all_params));
//    Actions.delete_all(delete_all_params);
}

split_selectables_by_type(List<Selectable> selected_items, Set<Strand> strands, Set<Crossover> crossovers,
    Set<Loopout> loopouts, Set<BoundSubstrand> substrands) {
  for (var selectable in selected_items) {
    if (selectable is Strand) {
      strands.add(selectable);
    } else if (selectable is Crossover) {
      crossovers.add(selectable);
    } else if (selectable is Loopout) {
      loopouts.add(selectable);
    } else if (selectable is DNAEnd) {
      // deleting end means deleting whole substrand it's on
      DNAEnd end = selectable;
      substrands.add(end.substrand);
    }
  }
}

/// Remove from lists any [Selectable]s that will not exist after another is deleted.
/// For example, if a [Strand] is deleted, then none of its parts need to be deleted.
trim_selectables_to_delete(
    Set<Strand> strands, Set<Crossover> crossovers, Set<Loopout> loopouts, Set<BoundSubstrand> substrands) {
  //XXX: this could be more algorithmically efficient if we first build up set of all items to remove,
  // then remove it with a single set difference call. But probably it won't be the bottleneck, and this
  // is easier to read.

  // remove parts of Strands that will be removed
  crossovers.removeWhere((crossover) => strands.contains(crossover.prev_substrand.strand));
  loopouts.removeWhere((loopout) => strands.contains(loopout.strand));
  substrands.removeWhere((substrand) => strands.contains(substrand.strand));

  // remove crossovers and loopouts whose adjacent substrands will be removed
  crossovers.removeWhere((crossover) =>
      substrands.contains(crossover.prev_substrand) || substrands.contains(crossover.next_substrand));
  loopouts.removeWhere((loopout) =>
      substrands.contains(loopout.prev_substrand()) || substrands.contains(loopout.next_substrand()));
}
