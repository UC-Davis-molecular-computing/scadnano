import 'package:w_flux/w_flux.dart';

import 'strand.dart';

class StrandUIModel extends Store {
  final Strand strand;
  bool _hover = false;
  bool _selected = false;

  bool get hover => this._hover;
  bool get selected => this._selected;

  set hover(bool new_hover) {
    this._hover = new_hover;
  }

  set selected(bool new_selected) {
    this._hover = new_selected;
  }

  StrandUIModel(this.strand);
}