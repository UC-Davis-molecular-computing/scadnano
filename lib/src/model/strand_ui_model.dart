import '../app.dart';
import 'strand.dart';

class StrandUIModel {
  final Strand strand;
  bool hover = false;

  Set<Strand> get selected_strands => app.model.main_view_ui_model.selection.strands;

  bool get selected => selected_strands.contains(strand);

  set selected(bool s) => s ? selected_strands.add(strand) : selected_strands.remove(strand);

//  Map<Tuple2<BoundSubstrand, BoundSubstrand>, CrossoverUIModel> crossover_ui_models =
//      Map<Tuple2<BoundSubstrand, BoundSubstrand>, CrossoverUIModel>();

  StrandUIModel(this.strand);

//  assign_crossover_ui_models() {
//    this.crossover_ui_models.clear();
//    for (int i = 0; i < this.strand.substrands.length - 1; i++) {
//      var prev_ss = this.strand.substrands[i];
//      var next_ss = this.strand.substrands[i + 1];
//      if (prev_ss is BoundSubstrand && next_ss is BoundSubstrand) {
//        this.crossover_ui_models[Tuple2<BoundSubstrand, BoundSubstrand>(prev_ss, next_ss)] =
//            CrossoverUIModel(prev_ss, next_ss);
//      }
//    }
//  }
}

//class BoundSubstrandUIModel {
//  final BoundSubstrand substrand;
//
//  Set<DNAEnd> get selected_starts => app.model.main_view_ui_model.selection.starts;
//
//  Set<DNAEnd> get selected_ends => app.model.main_view_ui_model.selection.ends;
//
//  Set<DNAEnd> get selected_5ps => substrand.forward ? selected_starts : selected_ends;
//
//  Set<DNAEnd> get selected_3ps => substrand.forward ? selected_ends : selected_starts;
//
//  bool get selected_start => selected_starts.contains(substrand._start);
//
//  bool get selected_end => selected_ends.contains(substrand);
//
//  bool get selected_5p => selected_5ps.contains(substrand);
//
//  bool get selected_3p => selected_3ps.contains(substrand);
//
//  set selected_start(s) => s ? selected_starts.add(substrand) : selected_starts.remove(substrand);
//
//  set selected_end(s) => s ? selected_ends.add(substrand) : selected_ends.remove(substrand);
//
//  set selected_5p(s) => s ? selected_5ps.add(substrand) : selected_5ps.remove(substrand);
//
//  set selected_3p(s) => s ? selected_3ps.add(substrand) : selected_3ps.remove(substrand);
//
//  BoundSubstrandUIModel(this.substrand);
//}

//class CrossoverUIModel {
//  Crossover crossover;
//
//  Set<Crossover> get selected_crossovers => app.model.main_view_ui_model.selection.crossovers;
//
//  bool get selected => selected_crossovers.contains(crossover);
//
//  set selected(bool s) => s ? selected_crossovers.add(crossover) : selected_crossovers.remove(crossover);
//
//  CrossoverUIModel(BoundSubstrand prev_substrand, BoundSubstrand next_substrand)
//      : crossover = Crossover(prev_substrand, next_substrand);
//}
