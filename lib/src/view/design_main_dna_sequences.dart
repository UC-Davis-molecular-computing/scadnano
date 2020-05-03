import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/util.dart';
import 'package:scadnano/src/view/pure_component.dart';

import '../state/strand.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

mixin DesignMainDNASequencesProps on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltList<Strand> strands;
  BuiltSet<int> side_selected_helix_idxs;
  String dna_sequence_png_uri;
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
            'translate(-${constants.DNA_SEQUENCE_HORIZONTAL_OFFSET}, -${constants.DNA_SEQUENCE_VERTICAL_OFFSET})')(
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
//            (ConnectedDesignMainDNASequence()
              ..helices = props.helices
              ..strand = strand
              ..side_selected_helix_idxs = props.side_selected_helix_idxs
              ..key = strand.toString()
              ..only_display_selected_helices = props.only_display_selected_helices
              ..className = 'strand-dna-sequence-elts')()
      ]);
    }
  }
}
