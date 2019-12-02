import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/model/app_state.dart';
import 'package:scadnano/src/model/position3d.dart';

import '../actions/actions_OLD.dart';
import '../model/dna_design.dart';
import '../model/mouseover_data.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import '../model/helix.dart';
import '../model/grid.dart';
import '../model/grid_position.dart';
import 'design_side_rotation.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_side_helix.over_react.g.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

UiFactory<_$DesignSideHelixProps> ConnectedDesignSideHelix = connect<AppState, _$DesignSideHelixProps>(
  mapStateToProps: (state) => (DesignSideHelix()),
)(DesignSideHelix);

@Factory()
UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

@Props()
class _$DesignSideHelixProps extends UiProps with ConnectPropsMixin {
  Helix helix;
  GridPosition grid_position;
  Grid grid;
  bool selected;
  MouseoverData mouseover_data;
}

@Component2()
class DesignSideHelixComponent extends UiComponent2<DesignSideHelixProps> {

  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Helix helix_next = nextProps['DesignSideHelixProps.helix'];
    MouseoverData mouseover_data_next = nextProps['DesignSideHelixProps.mouseover_data'];
    bool selected_next = nextProps['DesignSideHelixProps.selected'];
    Helix helix = props.helix;
    MouseoverData mouseover_data = props.mouseover_data;
    bool selected = props.selected;
    bool should = !(helix == helix_next && mouseover_data == mouseover_data_next && selected == selected_next);
//    print('should DesignSideHelix update for helix=${helix.idx}?          ${should}');
//    if (should) {
//      print('  helix == helix_next:                   ${helix == helix_next}');
//      print('  mouseover_data == mouseover_data_next: ${mouseover_data == mouseover_data_next}');
//      print('  helix = ${helix}');
//      print('  helix_next = ${helix_next}');
//      print('  mouseover_data = ${mouseover_data}');
//      print('  mouseover_data_next = ${mouseover_data_next}');
//    }
    return should;
  }

  @override
  render() {
//    print('rendering side helix ${props.helix.idx}');
    MouseoverData mouseover_data = this.props.mouseover_data;
//    print('  mouseover_data: $mouseover_data');

    Helix helix = this.props.helix;

    Position3D pos3d = helix.position3d();
    Point<num> center = Point<num>(pos3d.x, pos3d.y);
    bool selected = props.selected;

//    center = util.side_view_grid_to_svg(this.props.grid_position, this.props.grid);

    String classname_circle = '$SIDE_VIEW_PREFIX-helix-circle';
    if (selected) {
      classname_circle += ' selected';
    }

    var children = [
      (Dom.circle()
        ..className = classname_circle
        ..r = '${constants.SIDE_HELIX_RADIUS}'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'circle')(),
      (Dom.text()
        ..className = '$SIDE_VIEW_PREFIX-helix-text'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'text')(this.props.helix.idx.toString()),
    ];

//    print('checking mouseover data');
    if (mouseover_data != null) {
//      print('mouseover data not null; creating DesignSideRotation now');
      assert(mouseover_data.helix.idx == this.props.helix.idx);
      var rot_component = (DesignSideRotation()
        ..radius = constants.SIDE_HELIX_RADIUS
        ..helix = mouseover_data.helix
        ..offset = mouseover_data.offset
        ..key = 'rotation'
        ..className = '$SIDE_VIEW_PREFIX-helix-rotation')();
      children.add(rot_component);
    }

    return (Dom.g()..transform = 'translate(${center.x} ${center.y})')(children);
  }

  _handle_click(SyntheticMouseEvent event, Helix helix) {
    if (event.altKey) {
      _remove_helix(event, helix);
    } else if (event.shiftKey) {
      app.store.dispatch(actions.HelixSelect(helix.idx, false));
    } else if (event.ctrlKey || event.metaKey) {
      app.store.dispatch(actions.HelixSelect(helix.idx, true));
    }
  }

  _remove_helix(SyntheticMouseEvent event, Helix helix) {
    List<ReversibleActionPack> action_packs_for_batch = [];
    //FIXME: don't reach into global variable
    DNADesign dna_design = app.state.dna_design;
    if (dna_design.substrands_on_helix(helix.idx).isNotEmpty) {
      bool confirm = window.confirm('This Helix has strands on it. '
          'If you delete it, all the Strands will be deleted. Do you want to proceed?');
      if (!confirm) {
        return;
      }
      //XXX: important to keep out duplicates but preserve *reverse* order strands appear in DNADesign
      // That way when they are added back in reverse order with Undo, they will be in the same order as now.
      var dna_design = app.state.dna_design;
      var all_strands = dna_design.strands;
      var strands_to_remove = {
        for (BoundSubstrand ss in dna_design.substrands_on_helix(helix.idx))
          app.state.dna_design.substrand_to_strand[ss]
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
