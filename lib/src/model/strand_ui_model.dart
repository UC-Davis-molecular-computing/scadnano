import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import 'strand.dart';

class StrandUIModel {
  final Strand strand;
  bool hover = false;
  bool selected = false;

  Map<Tuple2<BoundSubstrand, BoundSubstrand>, CrossoverUIModel> crossover_ui_models =
      Map<Tuple2<BoundSubstrand, BoundSubstrand>, CrossoverUIModel>();

  StrandUIModel(this.strand);

  assign_crossover_ui_models() {
    this.crossover_ui_models.clear();
    for (int i = 0; i < this.strand.substrands.length - 1; i++) {
      var prev_ss = this.strand.substrands[i];
      var next_ss = this.strand.substrands[i + 1];
      if (prev_ss is BoundSubstrand && next_ss is BoundSubstrand) {
        this.crossover_ui_models[Tuple2<BoundSubstrand, BoundSubstrand>(prev_ss, next_ss)] =
            CrossoverUIModel(prev_ss, next_ss);
      }
    }
  }
}

class BoundSubstrandUIModel {
  final BoundSubstrand substrand;
  bool selected_5p = false;
  bool selected_3p = false;

  BoundSubstrandUIModel(this.substrand);
}

class CrossoverUIModel extends Store {
  final BoundSubstrand prev_substrand;
  final BoundSubstrand next_substrand;
  bool selected = false;

  CrossoverUIModel(this.prev_substrand, this.next_substrand);
}

class LoopoutUIModel {
  final Loopout loopout;
  bool selected = false;

  LoopoutUIModel(this.loopout);
}
