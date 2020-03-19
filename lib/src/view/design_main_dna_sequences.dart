import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/util.dart';
import 'package:scadnano/src/view/pure_component.dart';

import '../state/strand.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

@Props()
class _$DesignMainDNASequencesProps extends UiProps {
  BuiltMap<int, Helix> helices;
  BuiltList<Strand> strands;
  BuiltSet<int> side_selected_helix_idxs;
  String dna_sequence_png_uri;
  bool is_zoom_above_threshold;
}

@Component2()
class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> with PureComponent {
  @override
  render() {
    if (props.dna_sequence_png_uri == null || props.is_zoom_above_threshold) {
      return (Dom.g()..className = 'dna-sequences-main-view')([
        for (Strand strand in props.strands)
          if (strand.dna_sequence != null)
            (DesignMainDNASequence()
//            (ConnectedDesignMainDNASequence()
              ..helices = props.helices
              ..strand = strand
              ..side_selected_helix_idxs = props.side_selected_helix_idxs
              ..key = strand.toString()
              ..className = 'strand-dna-sequence-elts')()
      ]);
    } else {
      return (Dom.g()
        ..className = 'dna-sequences-main-view'
        ..pointerEvents = 'none'
        ..transform = 'translate(0, -${constants.DNA_SEQUENCE_VERTICAL_OFFSET})')(
        (Dom.image()
          ..xlinkHref = props.dna_sequence_png_uri
          ..id = 'dna-sequences-main-view-png')(),
      );
    }
  }
}
