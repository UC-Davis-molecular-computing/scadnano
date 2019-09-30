import 'dart:html';
import 'dart:math';

import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/mouseover_data.dart';
import 'package:scadnano/src/model/strand.dart';

import '../app.dart';
import '../model/helix.dart';

import 'package:over_react/over_react.dart';

import 'design_side_rotation.dart';

part 'design_side_helix.over_react.g.dart';

const String HELIX_EMPTY_COLOR = 'lightgoldenrodyellow';
const String HELIX_NONEMPTY_COLOR = 'goldenrod';

const String SIDE_VIEW_PREFIX = 'side-view';

@Factory()
UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

/// Used to represent both Helices and PotentialHelices.
/// Exactly one of helix and potential_helix should be null.
@Props()
class _$DesignSideHelixProps extends FluxUiProps<MouseoverDataStore, MouseoverDataStore> {
  Helix helix;
  GridPosition grid_position;
  bool used;
}

@Component()
class DesignSideHelixComponent extends FluxUiComponent<DesignSideHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Point<num> center = _g2c(this.props.grid_position);
    MouseoverDataStore mouseover_data_store = this.props.store;



    return (Dom.g()..transform = 'translate(${center.x} ${center.y})')([
      (Dom.circle()
        ..className = '$SIDE_VIEW_PREFIX-helix-circle' + (this.props.used ? ' used' : ' potential')
        ..r = '$RADIUS'
        ..key = 'circle'
        ..onClick = (e) => this._handle_click(e))(),
      if (this.props.used)
        (Dom.text()
          ..className = '$SIDE_VIEW_PREFIX-helix-text'
          ..key = 'text'
          ..onClick = (e) => this._handle_click(e))(this.props.helix.idx().toString()),
      if (this.props.used &&
          mouseover_data_store.data != null &&
          mouseover_data_store.data.helix_idx == this.props.helix.idx())
        (DesignSideRotation()
          ..helix = this.props.helix
          ..radius = RADIUS
          ..mouseover_data = mouseover_data_store.data
          ..key='rotation'
          ..className = '$SIDE_VIEW_PREFIX-helix-rotation')(),
    ]);
  }

  _handle_click(SyntheticMouseEvent e) {
    if (!e.ctrlKey) {
      return;
    }

    List<ReversibleActionPack> action_packs_for_batch = [];
    if (this.props.used) {
      if (this.props.helix.has_substrands()) {
        bool confirm = window.confirm('This Helix has strands on it. '
            'If you delete it, all the Strands will be deleted. Do you want to proceed?');
        if (!confirm) {
          return;
        }
        Set<Strand> strands_to_remove = {for (BoundSubstrand ss in this.props.helix.bound_substrands()) ss.strand};
        action_packs_for_batch.addAll([for (var strand in strands_to_remove) StrandRemoveActionPack(strand)]);
        //TODO: give option to user to remove only substrands on this helix and split the remaining substrands
      }
    }

    int idx = this.props.used ? this.props.helix.idx() : app.model.dna_design.helices.length;
    int max_bases = this.props.used ? this.props.helix.max_bases : -1;
    var params = HelixUseActionParameters(!this.props.used, this.props.grid_position, idx, max_bases);
    var helix_use_action_pack = HelixUseActionPack(params);

    if (action_packs_for_batch.isEmpty) {
      app.send_action(helix_use_action_pack);
    } else {
      action_packs_for_batch.add(helix_use_action_pack);
      BatchActionPack batch_action_pack = BatchActionPack(action_packs_for_batch);
      app.send_action(batch_action_pack);
    }
  }
}

const RADIUS = 25.0;

Point<num> _g2c(GridPosition gp) => Point<num>(2 * RADIUS * (gp.h + 1), 2 * RADIUS * (gp.v + 1));
