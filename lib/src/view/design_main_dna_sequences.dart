import 'dart:html';

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
import '../util.dart' as util;
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

mixin DesignMainDNASequencesProps on UiProps {
  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;

  late BuiltList<Strand> strands;
  late BuiltSet<int> side_selected_helix_idxs;
  String? dna_sequence_png_uri;
  late num dna_sequence_png_horizontal_offset;
  late num dna_sequence_png_vertical_offset;
  late bool is_zoom_above_threshold;
  actions.ExportSvg? export_svg_action_delayed_for_png_cache;
  late bool only_display_selected_helices;
  late BuiltMap<int, Point<double>> helix_idx_to_svg_position_map;
  late bool disable_png_caching_dna_sequences;
  late bool retain_strand_color_on_selection;
  late bool display_reverse_DNA_right_side_up;
}

class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> with PureComponent {
  /// This method is used to handle the `disable_png_cache_until_action_completes` prop.
  /// If this prop is not null, then it dispatches the prop action before disabling it.
  @override
  void componentDidUpdate(Map prevProps, Map prevState, [snapshot]) {
    actions.ExportSvg? action_to_complete = props.export_svg_action_delayed_for_png_cache;

    if (action_to_complete != null) {
      app.dispatch(action_to_complete);

      // After exporting svg, re-enable png caching.
      app.dispatch(actions.SetExportSvgActionDelayedForPngCache(null));
    }
  }

  @override
  render() {
    bool should_use_png_dna_sequence = use_png(props.dna_sequence_png_uri, props.is_zoom_above_threshold,
        props.export_svg_action_delayed_for_png_cache, props.disable_png_caching_dna_sequences);

    if (should_use_png_dna_sequence) {
      // DNA sequence png.
      return (Dom.g()
        ..className = 'dna-sequences-main-view'
        ..pointerEvents = 'none'
        ..transform =
            'translate(${props.dna_sequence_png_horizontal_offset}, ${props.dna_sequence_png_vertical_offset})')(
        (Dom.image()
          ..xlinkHref = props.dna_sequence_png_uri
          ..id = 'dna-sequences-main-view-png')(),
      );
    } else {
      int idx = 0;
      return (Dom.g()..className = 'dna-sequences-main-view')([
        for (var strand in props.strands)
          if (strand.dna_sequence != null)
            (DesignMainDNASequence()
              ..helices = props.helices
              ..groups = props.groups
              ..geometry = props.geometry
              ..strand = strand
              ..side_selected_helix_idxs = props.side_selected_helix_idxs
              ..only_display_selected_helices = props.only_display_selected_helices
              ..display_reverse_DNA_right_side_up = props.display_reverse_DNA_right_side_up
              ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
              ..key = idx++
              ..className = 'strand-dna-sequence-elts')(),
      ]);
    }
  }
}
