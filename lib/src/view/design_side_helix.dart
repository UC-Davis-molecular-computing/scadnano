import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/model/model.dart';

import '../model/dna_design.dart';
import '../dispatcher/actions_OLD.dart';
import '../model/mouseover_data.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import '../model/helix.dart';
import '../model/grid.dart';
import '../model/grid_position.dart';
import 'design_side_rotation.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_side_helix.over_react.g.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

UiFactory<_$DesignSideHelixProps> ConnectedDesignSideHelix = connect<Model, _$DesignSideHelixProps>(
  mapStateToProps: (model) => (DesignSideHelix()),
)(DesignSideHelix);

@Factory()
UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

@Props()
class _$DesignSideHelixProps extends UiProps with ConnectPropsMixin {
  Helix helix;
  GridPosition grid_position;
  Grid grid;
  MouseoverData mouseover_data;
}

@Component2()
class DesignSideHelixComponent extends UiComponent2<DesignSideHelixProps> {

  //FIXME: this shouldn't be necessary since Redux and/or React should be doing this comparison for me
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Helix helix_next = nextProps['DesignSideHelixProps.helix'];
    MouseoverData mouseover_data_next = nextProps['DesignSideHelixProps.mouseover_data'];
    Helix helix = props.helix;
    MouseoverData mouseover_data = props.mouseover_data;
    return helix != helix_next || mouseover_data != mouseover_data_next;
  }

  @override
  render() {
//    print('rendering helix ${props.helix.idx}');
    MouseoverData mouseover_data = this.props.mouseover_data;
//    print('  mouseover_data: $mouseover_data');

    Point<num> center = util.side_view_grid_to_svg(this.props.grid_position, this.props.grid);
    Helix helix = this.props.helix;

    var children = [
      (Dom.circle()
        ..className = '$SIDE_VIEW_PREFIX-helix-circle'
        ..r = '${constants.SIDE_HELIX_RADIUS}'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'circle')(),
      (Dom.text()
        ..className = '$SIDE_VIEW_PREFIX-helix-text'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'text')(this.props.helix.idx.toString()),
    ];

//    for (MouseoverData mouseover_data in mouseover_datas) {
//      if (mouseover_data.helix.idx == this.props.helix.idx) {
    if (mouseover_data != null) {
      assert(mouseover_data.helix.idx == this.props.helix.idx);
      children.add((DesignSideRotation()
        ..radius = constants.SIDE_HELIX_RADIUS
        ..helix = mouseover_data.helix
        ..offset = mouseover_data.offset
        ..key = 'rotation'
        ..className = '$SIDE_VIEW_PREFIX-helix-rotation')());
//      }
//    }
    }

    return (Dom.g()..transform = 'translate(${center.x} ${center.y})')(children);
  }

  _handle_click(SyntheticMouseEvent event, Helix helix) {
    if (!event.ctrlKey) {
      return;
    }

    List<ReversibleActionPack> action_packs_for_batch = [];
    //FIXME: don't reach into global variable
    DNADesign dna_design = app.model.dna_design;
    if (dna_design.substrands_on_helix(helix.idx).isNotEmpty) {
      bool confirm = window.confirm('This Helix has strands on it. '
          'If you delete it, all the Strands will be deleted. Do you want to proceed?');
      if (!confirm) {
        return;
      }
      //XXX: important to keep out duplicates but preserve *reverse* order strands appear in DNADesign
      // That way when they are added back in reverse order with Undo, they will be in the same order as now.
      var dna_design = app.model.dna_design;
      var all_strands = dna_design.strands;
      var strands_to_remove = {
        for (BoundSubstrand ss in dna_design.substrands_on_helix(helix.idx))
          app.model.dna_design.substrand_to_strand[ss]
      }.toList();
      strands_to_remove.sort((s1, s2) => all_strands.indexOf(s2).compareTo(all_strands.indexOf(s1)));
//      action_packs_for_batch.add([for (var strand in strands_to_remove) StrandRemoveActionPack(strand)]);
      action_packs_for_batch.add(StrandsRemoveActionPack(strands_to_remove));
      //TODO: give option to user to remove only substrands on this helix and split the remaining substrands
    }

    int idx = this.props.helix.idx;
    int max_offset = this.props.helix.max_offset;
    int min_offset = this.props.helix.min_offset;
    var params = HelixUseActionParameters(false, this.props.grid_position, idx, max_offset,
        min_offset: min_offset, major_tick_distance: helix.major_tick_distance, major_ticks: helix.major_ticks);
    var helix_use_action_pack = HelixUseActionPack(params);

    if (action_packs_for_batch.isEmpty) {
      //FIXME: dispatch action through props.dispatch
//      app.send_action(helix_use_action_pack);
    } else {
      //FIXME: dispatch action through props.dispatch
//      action_packs_for_batch.add(helix_use_action_pack);
//      BatchActionPack batch_action_pack = BatchActionPack(action_packs_for_batch);
//      app.send_action(batch_action_pack);
    }
  }
}
