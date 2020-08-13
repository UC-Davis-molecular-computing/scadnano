import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/helix.dart';
import '../util.dart';

import '../state/strand.dart';
import 'pure_component.dart';
import '../constants.dart' as constants;
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

mixin DesignMainDNASequencesProps on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  BuiltList<Strand> strands;
  BuiltSet<int> side_selected_helix_idxs;
  String dna_sequence_png_uri;
  num dna_sequence_png_horizontal_offset;
  num dna_sequence_png_vertical_offset;
  bool is_zoom_above_threshold;
  actions.Action disable_png_cache_until_action_completes;
  bool only_display_selected_helices;
}

class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> with PureComponent {
  /// This method is used to handle the `disable_png_cache_until_action_completes` prop.
  /// If this prop is not null, then it dispatches the prop action before disabling it.
  @override
  void componentDidUpdate(Map prevProps, Map prevState, [snapshot]) {
    var action_to_complete = props.disable_png_cache_until_action_completes;

    if (action_to_complete != null) {
      app.dispatch(action_to_complete);

      // After exporting svg, re-enable png caching.
      app.dispatch(actions.SetDisablePngCacheUntilActionCompletes(null));
    }
  }

  @override
  render() {
    bool should_use_png_dna_sequence = use_png(props.dna_sequence_png_uri, props.is_zoom_above_threshold,
        props.disable_png_cache_until_action_completes);

    if (should_use_png_dna_sequence) {
      // DNA sequence png.
      return (Dom.g()
            ..className = 'dna-sequences-main-view'
            ..pointerEvents = 'none'
            ..transform =
                'translate(-${props.dna_sequence_png_horizontal_offset}, -${props.dna_sequence_png_vertical_offset})'
//        ..x = -constants.DNA_SEQUENCE_HORIZONTAL_OFFSET
//        ..y = -constants.DNA_SEQUENCE_VERTICAL_OFFSET
          )(
        (Dom.image()
          ..xlinkHref = props.dna_sequence_png_uri
          ..id = 'dna-sequences-main-view-png')(),
      );
    } else {
      // DNA sequence svg.
      return (Dom.g()..className = 'dna-sequences-main-view')([
        for (Strand strand in props.strands)
          if (strand.dna_sequence != null)
            (DesignMainDNASequence()
              ..helices = props.helices
              ..groups = props.groups
              ..geometry = props.geometry
              ..strand = strand
              ..side_selected_helix_idxs = props.side_selected_helix_idxs
              ..key = strand.toString()
              ..only_display_selected_helices = props.only_display_selected_helices
              ..className = 'strand-dna-sequence-elts')()
      ]);
    }
  }
}