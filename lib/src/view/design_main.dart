library view_main;

import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg; // hide Point;

import 'package:platform_detect/platform_detect.dart';
import 'package:tuple/tuple.dart';
import 'package:over_react/react_dom.dart' as react_dom;

import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';

import '../model/composite_stores.dart';
import '../model/model.dart';
import '../model/model_ui.dart';
import '../model/strand.dart';
import '../model/dna_design.dart';
import '../model/helix.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

import 'package:over_react/over_react.dart';

part 'design_main.over_react.g.dart';

//TODO: display width of each portion of helix between major ticks lightly above helix 0;
//  alternately, display as mouseover information

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
class _$DesignMainProps extends FluxUiProps<Model, Model> {}

@Component()
class DesignMainComponent extends FluxUiComponent<DesignMainProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    DNADesign dna_design = this.props.store.dna_design;
    DNASequencesStore dna_sequences_store = this.props.store.dna_sequences_store;
    MismatchesStore mismatches_store = this.props.store.mismatches_store;

    return Dom.g()(
        (DesignMainHelices()..store = dna_design.helices_store)(),
        (DesignMainMismatches()..store = mismatches_store)(),
        (DesignMainStrands()..store = dna_design.strands_store)(),
        (DesignMainDNASequences()..store = dna_sequences_store)(),
        (DesignMainMouseoverRectHelices()..store = dna_design.helices_store)());
  }
}
