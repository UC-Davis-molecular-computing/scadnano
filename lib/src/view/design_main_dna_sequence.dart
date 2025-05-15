import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/view/transform_by_helix_group.dart';

import '../state/helix.dart';
import 'package:scadnano/src/state/geometry.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import '../state/extension.dart';
import 'pure_component.dart';
import '../util.dart' as util;

part 'design_main_dna_sequence.over_react.g.dart';

UiFactory<DesignMainDNASequenceProps> DesignMainDNASequence = _$DesignMainDNASequence;

mixin DesignMainDNASequenceProps on UiProps implements TransformByHelixGroupPropsMixin {
  late Strand strand;
  late BuiltSet<int> side_selected_helix_idxs;
  late bool only_display_selected_helices;
  late bool display_reverse_DNA_right_side_up;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;
  late BuiltMap<int, Point<double>> helix_idx_to_svg_position_map;
}

bool should_draw_domain(
  Domain ss,
  BuiltSet<int> side_selected_helix_idxs,
  bool only_display_selected_helices,
) => !only_display_selected_helices || side_selected_helix_idxs.contains(ss.helix);

class DesignMainDNASequenceComponent extends UiComponent2<DesignMainDNASequenceProps> with PureComponent {
  @override
  render() {
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;

    List<ReactElement> dna_sequence_elts = [];
    for (int i = 0; i < this.props.strand.substrands.length; i++) {
      var substrand = this.props.strand.substrands[i];
      if (substrand is Domain) {
        if (should_draw_domain(substrand, side_selected_helix_idxs, props.only_display_selected_helices)) {
          Domain domain = substrand;
          List<ReactElement> domain_elts = [];
          domain_elts.add(this._dna_sequence_on_domain(domain));
          for (var insertion in domain.insertions) {
            int offset = insertion.offset;
            int length = insertion.length;
            domain_elts.add(this._dna_sequence_on_insertion(domain, offset, length));
          }
          dna_sequence_elts.add(
            (Dom.g()
              ..transform = transform_of_helix2(props, domain.helix)
              ..className = 'dna-seq-on-domain-group'
              ..key = util.id_domain(domain))(domain_elts),
          );
        }
      } else if (substrand is Loopout) {
        assert(0 < i);
        assert(i < this.props.strand.substrands.length - 1);
        Loopout loopout = substrand;
        Domain prev_dom = this.props.strand.substrands[i - 1] as Domain;
        Domain next_dom = this.props.strand.substrands[i + 1] as Domain;
        if (should_draw_domain(prev_dom, side_selected_helix_idxs, props.only_display_selected_helices) &&
            should_draw_domain(next_dom, side_selected_helix_idxs, props.only_display_selected_helices)) {
          dna_sequence_elts.add(this._dna_sequence_on_loopout(loopout, prev_dom, next_dom));
        }
      } else if (substrand is Extension) {
        assert(i == 0 || i == props.strand.substrands.length - 1);
        Extension ext = substrand;
        if (should_draw_domain(
          ext.adjacent_domain,
          side_selected_helix_idxs,
          props.only_display_selected_helices,
        )) {
          dna_sequence_elts.add(this._dna_sequence_on_extension(ext));
        }
      } else {
        throw AssertionError('unrecognized substrand type: ${substrand}');
      }
    }
    return (Dom.g()
      ..className = 'strand-dna-sequence'
      ..id = 'dna-sequence-${this.props.strand.id}')(dna_sequence_elts);
  }

  static const classname_dna_sequence = 'dna-seq';
  static const charWidth = 6.59375;

  ReactElement _dna_sequence_on_domain(Domain domain) {
    var helix = props.helices[domain.helix]!;
    var group = props.groups[helix.group]!;
    var geometry = group.geometry ?? props.geometry;
    var seq_to_draw = domain.dna_sequence_deletions_insertions_to_spaces(
      reverse: props.display_reverse_DNA_right_side_up && !domain.forward,
    );

    var rotate_degrees = 0;
    int offset = domain.offset_5p;
    Point<double> pos = helix.svg_base_pos(
      offset,
      domain.forward,
      props.helix_idx_to_svg_position_map[domain.helix]!.y,
      props.geometry,
    );
    var rotate_x = pos.x;
    var rotate_y = pos.y;

    // this is needed to make complementary DNA bases line up more nicely (still not perfect)
    var x_adjust = -geometry.base_width_svg * 0.32;
    var dy, x, y;
    var text_length = geometry.base_width_svg * (domain.visual_length - 0.342);

    //extension, loopout,

    if (domain.forward) {
      //rotation and displacement for forward text
      rotate_degrees = 0;
      dy = -geometry.base_height_svg * 0.25;
      x = pos.x + x_adjust;
      y = pos.y;
    } else {
      if (props.display_reverse_DNA_right_side_up) {
        rotate_degrees = 0;
        //displacement for reverse text
        dy = geometry.base_height_svg * 0.75;
        x = pos.x - x_adjust - text_length;
        y = pos.y + geometry.base_height_svg;
      } else {
        rotate_degrees = 180;
        //displacement for reverse text if option not enabled
        dy = -geometry.base_height_svg * 0.25;
        x = pos.x + x_adjust;
        y = pos.y;
      }
    }

    var id = 'dna-${util.id_domain(domain)}';

    // textLength is the more robust way to space out the letter than letterSpacing
    // (e.g., in Firefox it displays poorly with letterSpacing),
    // but it caused problems with exporting to SVG and then importing into Powerpoint.
    // So we provided an option to export SVG with each DNA base represented as its own text element
    // to avoid the problems with textLength in Powerpoint. Keeping the commented letterSpacing code
    // to remember why we don't want to use that anymore. :)
    return (Dom.text()
      ..key = id
      ..id = id
      ..className = classname_dna_sequence
      ..x = '$x'
      ..y = '$y'
      ..textLength = '$text_length'
      // ..letterSpacing = '${(text_length - charWidth * seq_to_draw.length) / (seq_to_draw.length - 1)}'
      ..transform = 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})'
      ..dy = '$dy')(seq_to_draw);
  }

  ReactElement _dna_sequence_on_insertion(Domain domain, int offset, int length) {
    var helix = props.helices[domain.helix]!;
    var group = props.groups[helix.group]!;
    var geometry = group.geometry ?? props.geometry;
    var reverse_right_side_up = props.display_reverse_DNA_right_side_up && !domain.forward;

    var subseq = domain.dna_sequence_in(offset, offset, reverse: reverse_right_side_up);
    //XXX: path_length appears to return different results depending on the computer (probably resolution??)
    // don't rely on it. This caused Firefox for example to render different on the same version.
    //    num path_length = insertion_path_elt.getTotalLength();

    var start_offset = '50%';
    var dy = '${0.1 * geometry.base_width_svg}';

    var (letter_spacing, font_size) = _calculate_letter_spacing_and_font_size_insertion(
      length,
    ); // (double?, int)

    Map<String, dynamic> style_map;
    if (letter_spacing != null) {
      style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};
    } else {
      style_map = {'fontSize': '${font_size}px'};
    }

    if (reverse_right_side_up) {
      style_map['dominantBaseline'] = 'hanging';
    }

    SvgProps text_path_props =
        (Dom.textPath()
          ..className = classname_dna_sequence + '-insertion'
          //XXX: xlink:href is deprecated, but this is needed for exporting SVG, due to a bug in Inkscape
          // https://gitlab.com/inkscape/inbox/issues/1763
          ..xlinkHref = '#${util.id_insertion(domain, offset)}'
          ..startOffset = start_offset
          ..style = style_map);

    return (Dom.text()
      ..key = 'textelt-${util.id_insertion(domain, offset)}'
      ..dy = dy)(text_path_props(subseq));
  }

  ReactElement _dna_sequence_on_loopout(Loopout loopout, Domain prev_domain, Domain next_domain) {
    var helix = props.helices[prev_domain.helix]!;
    var group = props.groups[helix.group]!;
    var geometry = group.geometry ?? props.geometry;
    String subseq = loopout.dna_sequence!;
    var length = subseq.length;

    var start_offset = '50%';
    var dy = '${0.1 * geometry.base_height_svg}';

    (double?, int) ls_fs;
    if (util.is_hairpin(prev_domain, next_domain)) {
      ls_fs = _calculate_letter_spacing_and_font_size_hairpin(length);
    } else {
      ls_fs = _calculate_letter_spacing_and_font_size_loopout(length);
    }

    var (letter_spacing, font_size) = ls_fs; // (double?, int)

    Map<String, dynamic> style_map;
    if (letter_spacing != null) {
      style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};
    } else {
      style_map = {'fontSize': '${font_size}px'};
    }

    SvgProps text_path_props =
        (Dom.textPath()
          ..className = classname_dna_sequence + '-loopout'
          ..xlinkHref = '#${loopout.id}'
          ..startOffset = start_offset
          ..style = style_map);
    return (Dom.text()
      ..key =
          'loopout-dna'
          'H${prev_domain.helix},${prev_domain.offset_3p}-'
          'H${next_domain.helix},${next_domain.offset_5p}'
      ..dy = dy)(text_path_props(subseq));
  }

  ReactElement _dna_sequence_on_extension(Extension ext) {
    var helix = props.helices[ext.adjacent_domain.helix]!;
    var group = props.groups[helix.group]!;
    var geometry = group.geometry ?? props.geometry;
    var subseq = ext.dna_sequence;

    var start_offset = '50%';
    var dy = '${0.1 * geometry.base_height_svg}';

    var (letter_spacing, font_size) = _calculate_letter_spacing_and_font_size_extension(ext); // (double, int)

    Map<String, dynamic> style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};

    SvgProps text_path_props =
        (Dom.textPath()
          ..className = classname_dna_sequence + '-extension'
          ..xlinkHref = '#${ext.id}'
          ..startOffset = start_offset
          ..style = style_map);
    return (Dom.text()
      ..key =
          'extension-dna-${ext.is_5p ? "5'" : "3'"}'
          'H${ext.adjacent_domain.helix},${ext.adjacent_domain.start}-${ext.adjacent_domain.end}'
      ..dy = dy)(text_path_props(subseq));
  }
}

(double, int) _calculate_letter_spacing_and_font_size_loopout(int len) {
  double letter_spacing = 0;
  int font_size = 12;
  return (letter_spacing, font_size);
}

(double, int) _calculate_letter_spacing_and_font_size_extension(Extension ext) {
  double letter_spacing = 0;
  int font_size = 12;
  return (letter_spacing, font_size);
}

(double?, int) _calculate_letter_spacing_and_font_size_hairpin(int len) {
  double? letter_spacing;
  int font_size = max(6, 12 - max(0, len - 6));
  if (browser.isChrome) {
    if (len == 1) {
      letter_spacing = 0;
    } else if (len == 2) {
      letter_spacing = -0.1;
    } else if (len == 3) {
      letter_spacing = -0.1;
    } else if (len == 4) {
      letter_spacing = -0.1;
    } else if (len == 5) {
      letter_spacing = -0.15;
    } else if (len == 6) {
      letter_spacing = -0.18;
    } else {
      letter_spacing = null;
    }
  }
  if (browser.isFirefox) {
    // Firefox ignores the "letter-spacing" property so we only have font-size to play with
    font_size = max(6, 12 - (len - 1));
    if (len > 3 && font_size > 6) {
      font_size -= 1;
    }
    letter_spacing = null;
  }
  return (letter_spacing, font_size);
}

(double?, int) _calculate_letter_spacing_and_font_size_insertion(int num_insertions) {
  // UGGG
  double? letter_spacing;
  int font_size = max(6, 12 - (num_insertions - 1));
  if (browser.isChrome) {
    if (num_insertions == 1) {
      letter_spacing = 0;
    } else if (num_insertions == 2) {
      letter_spacing = -0.1;
    } else if (num_insertions == 3) {
      letter_spacing = -0.1;
    } else if (num_insertions == 4) {
      letter_spacing = -0.1;
    } else if (num_insertions == 5) {
      letter_spacing = -0.15;
    } else if (num_insertions == 6) {
      letter_spacing = -0.18;
    } else {
      letter_spacing = null;
    }
  }
  if (browser.isFirefox) {
    // Firefox ignores the "letter-spacing" property so we only have font-size to play with
    font_size = max(6, 12 - (num_insertions - 1));
    if (num_insertions > 3 && font_size > 6) {
      font_size -= 1;
    }
    letter_spacing = null;
  }
  return (letter_spacing, font_size);
}

// keep this around in case this is how we want to export to an SVG file and it doesn't do textLength well
//  draw_dna_sequence_old(Substrand substrand) {
//    var seq_group = svg.GElement();
//    seq_group.attributes = {'class': 'dna-subsequence'};
//    element.children.add(seq_group);
//    String dna_sequence = substrand.dna_sequence();
//    for (int i = 0; i < substrand.dna_length && i < dna_sequence.length; i++) {
//      String base = dna_sequence[i];
//      var base_elt = svg.TextElement();
//      base_elt.innerHtml = base;
//      var offset_from_start = i;
//      var rotate_degrees = 0;
//      if (substrand.direction == Direction.left) {
//        offset_from_start = -i;
//      }
//      int offset = substrand.offset_5p + offset_from_start;
//      Point<double> pos = Helix.svg_base_pos(substrand.helix_idx, offset, substrand.direction);
//      var rotate_x = pos.x;
//      var rotate_y = pos.y;
//      if (substrand.direction == Direction.left) {
//        rotate_degrees = 180;
//      }
//      var dy = '0.75px';
//      if (browser.isFirefox) {
//        dy = '0px';
//      }
//      base_elt.attributes = {
//        'class': 'dna-base',
//        'x': '${pos.x}',
//        'y': '${pos.y}',
//        'transform': 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})',
//        'dy': dy,
//      };
//      seq_group.children.add(base_elt);
//    }
//  }
