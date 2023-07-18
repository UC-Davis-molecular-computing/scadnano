import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/modification_type.dart';
import 'package:scadnano/src/state/substrand.dart';

import 'transform_by_helix_group.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'design_main_strand_paths.dart';
import 'design_main_strand_domain_text.dart';
import 'design_main_strand_loopout_name.dart';
import 'design_main_strand_extension_name.dart';
import 'pure_component.dart';
import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_and_domain_texts.over_react.g.dart';

UiFactory<DesignMainStrandAndDomainTextsProps> DesignMainStrandAndDomainTexts =
    _$DesignMainStrandAndDomainTexts;

// shows both domain and strand names
mixin DesignMainStrandAndDomainTextsPropsMixin on UiProps {
  Strand strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool show_dna;

  bool show_strand_names;
  bool show_strand_labels;
  bool show_domain_names;
  bool show_domain_labels;
  int strand_name_font_size;
  int strand_label_font_size;
  int domain_name_font_size;
  int domain_label_font_size;

  BuiltMap<int, Point<num>> helix_idx_to_svg_position;

  List<ContextMenuItem> Function(Strand strand, {Substrand substrand, Address address, ModificationType type})
      context_menu_strand;
}

class DesignMainStrandAndDomainTextsProps = UiProps
    with DesignMainStrandAndDomainTextsPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainStrandAndDomainTextsComponent extends UiComponent2<DesignMainStrandAndDomainTextsProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandAndDomainTextsProps> {
  @override
  render() {
    if (!(props.show_domain_names ||
        props.show_strand_names ||
        props.show_strand_labels ||
        props.show_domain_labels)) {
      return null;
    }

    List<ReactElement> text_components = [];

    if (props.show_strand_names) {
      ReactElement strand_name_component = _draw_strand_name();
      if (strand_name_component != null) {
        text_components.add(strand_name_component);
      }
    }

    if (props.show_strand_labels) {
      ReactElement strand_label_component = _draw_strand_label();
      if (strand_label_component != null) {
        text_components.add(strand_label_component);
      }
    }

    if (props.show_domain_names) {
      List<ReactElement> domain_name_components = _draw_domain_names();
      if (domain_name_components.isNotEmpty) {
        text_components.add((Dom.g()
          ..className = 'domain-names'
          ..key = 'domain-names')(domain_name_components));
      }
    }

    if (props.show_domain_labels) {
      List<ReactElement> domain_label_components = _draw_domain_labels();
      if (domain_label_components.isNotEmpty) {
        text_components.add((Dom.g()
          ..className = 'domain-labels'
          ..key = 'domain-labels')(domain_label_components));
      }
    }

    if (text_components.isEmpty) {
      return null;
    }

    return (Dom.g()..className = 'domain-and-strand-names')(text_components);
  }

  ReactElement _draw_strand_name() {
    if (props.strand.name == null) {
      // nothing to draw if strand name is null
      return null;
    }

    ReactElement strand_name_component = null;
    Domain domain_5p = props.strand.first_domain;
    bool draw_domain = should_draw_domain(
        domain_5p.helix, props.side_selected_helix_idxs, props.only_display_selected_helices);

    var helix_svg_position = props.helix_idx_to_svg_position[domain_5p.helix];

    // don't bother if 5' domain is not visible; if we give more sophisticated options for where to place
    // the strand name later, this should be changed
    if (draw_domain && props.strand.name != null) {
      Helix helix = props.helices[domain_5p.helix];
      int num_stacked = 0;
      if (props.show_dna) num_stacked++;
      if (props.show_domain_names) num_stacked++;
      if (props.show_domain_labels) num_stacked++;
      strand_name_component = (DesignMainStrandDomainText()
        ..strand = props.strand
        ..domain = domain_5p
        ..text = props.strand.name
        ..num_stacked = num_stacked
        ..css_selector_text = constants.css_selector_strand_name_text
        ..font_size = props.strand_name_font_size
        ..helix = helix
        ..helix_groups = props.groups
        ..geometry = props.geometry
        ..transform = transform_of_helix(domain_5p.helix)
        ..helix_svg_position = helix_svg_position
        ..context_menu_strand = props.context_menu_strand
        ..className = constants.css_selector_strand_name
        ..key = "strand-name")();
    }
    return strand_name_component;
  }

  ReactElement _draw_strand_label() {
    if (props.strand.label == null) {
      // nothing to draw if strand name is null
      return null;
    }

    ReactElement strand_label_component = null;
    Domain domain_5p = props.strand.first_domain;
    bool draw_domain = should_draw_domain(
        domain_5p.helix, props.side_selected_helix_idxs, props.only_display_selected_helices);

    var helix_svg_position = props.helix_idx_to_svg_position[domain_5p.helix];

    // don't bother if 5' domain is not visible; if we give more sophisticated options for where to place
    // the strand label later, this should be changed
    if (draw_domain && props.strand.label != null) {
      Helix helix = props.helices[domain_5p.helix];
      int num_stacked = 0;
      if (props.show_dna) num_stacked++;
      if (props.show_strand_names) num_stacked++;
      if (props.show_domain_names) num_stacked++;
      if (props.show_domain_labels) num_stacked++;
      strand_label_component = (DesignMainStrandDomainText()
        ..strand = props.strand
        ..domain = domain_5p
        ..text = props.strand.label
        ..num_stacked = num_stacked
        ..css_selector_text = constants.css_selector_strand_label_text
        ..font_size = props.strand_label_font_size
        ..helix = helix
        ..helix_groups = props.groups
        ..geometry = props.geometry
        ..transform = transform_of_helix(domain_5p.helix)
        ..helix_svg_position = helix_svg_position
        ..context_menu_strand = props.context_menu_strand
        ..className = constants.css_selector_strand_label
        ..key = "strand-label")();
    }
    return strand_label_component;
  }

  List<ReactElement> _draw_domain_names() {
    List<ReactElement> names = [];
    int i = 0;
    for (var substrand in props.strand.substrands) {
      if (substrand is Domain) {
        Domain domain = substrand;
        bool draw_domain = should_draw_domain(
            domain.helix, props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_domain && domain.name != null) {
          Helix helix = props.helices[substrand.helix];
          var helix_svg_position = props.helix_idx_to_svg_position[substrand.helix];
          int num_stacked = 0;
          if (props.show_dna) num_stacked++;
          names.add((DesignMainStrandDomainText()
            ..strand = props.strand
            ..domain = substrand
            ..text = domain.name
            ..num_stacked = num_stacked
            ..css_selector_text = constants.css_selector_domain_name_text
            ..helix = helix
            ..helix_groups = props.groups
            ..geometry = props.geometry
            ..font_size = props.domain_name_font_size
            ..transform = transform_of_helix(domain.helix)
            ..helix_svg_position = helix_svg_position
            ..context_menu_strand = props.context_menu_strand
            ..className = constants.css_selector_domain_name
            ..key = "domain-name-$i")());
        }
      } else if (substrand is Loopout) {
        Loopout loopout = substrand;
        Domain prev_domain = (props.strand.substrands[i - 1] as Domain);
        Domain next_domain = (props.strand.substrands[i + 1] as Domain);
        int prev_helix_idx = prev_domain.helix;
        int next_helix_idx = next_domain.helix;
        bool draw_loopout = should_draw_loopout(prev_helix_idx, next_helix_idx,
            props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_loopout && loopout.name != null) {
          names.add((DesignMainStrandLoopoutName()
            ..loopout = loopout
            ..prev_domain = prev_domain
            ..next_domain = next_domain
            ..geometry = props.geometry
            ..font_size = props.domain_name_font_size
            ..show_dna = props.show_dna
            ..className = constants.css_selector_loopout_name
            ..key = "loopout-name-$i")());
        }
      } else if (substrand is Extension) {
        Extension ext = substrand;
        int adj_helix_idx = ext.adjacent_domain.helix;
        bool draw_loopout = should_draw_extension(
            adj_helix_idx, props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_loopout && ext.name != null) {
          names.add((DesignMainStrandExtensionName()
            ..ext = ext
            ..geometry = props.geometry
            ..font_size = props.domain_name_font_size
            ..show_dna = props.show_dna
            ..className = constants.css_selector_extension_name
            ..key = "extension-name-$i")());
        }
      } else {
        throw AssertionError('substrand must be Domain, Loopout, or Extension');
      }
      i++;
    }
    return names;
  }

  List<ReactElement> _draw_domain_labels() {
    List<ReactElement> names = [];
    int i = 0;
    for (var substrand in props.strand.substrands) {
      if (substrand is Domain) {
        Domain domain = substrand;
        bool draw_domain = should_draw_domain(
            domain.helix, props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_domain && domain.label != null) {
          Helix helix = props.helices[substrand.helix];
          var helix_svg_position = props.helix_idx_to_svg_position[substrand.helix];
          int num_stacked = 0;
          if (props.show_dna) num_stacked++;
          if (props.show_domain_names) num_stacked++;
          names.add((DesignMainStrandDomainText()
            ..strand = props.strand
            ..domain = substrand
            ..text = domain.label
            ..num_stacked = num_stacked
            ..css_selector_text = constants.css_selector_domain_label_text
            ..helix = helix
            ..helix_groups = props.groups
            ..geometry = props.geometry
            ..font_size = props.domain_name_font_size
            ..transform = transform_of_helix(domain.helix)
            ..helix_svg_position = helix_svg_position
            ..context_menu_strand = props.context_menu_strand
            ..className = constants.css_selector_domain_label
            ..key = "domain-label-$i")());
        }
      } else if (substrand is Loopout) {
        // Loopout loopout = substrand;
        // Domain prev_domain = (props.strand.substrands[i - 1] as Domain);
        // Domain next_domain = (props.strand.substrands[i + 1] as Domain);
        // int prev_helix_idx = prev_domain.helix;
        // int next_helix_idx = next_domain.helix;
        // bool draw_loopout = should_draw_loopout(prev_helix_idx, next_helix_idx,
        //     props.side_selected_helix_idxs, props.only_display_selected_helices);
        // if (draw_loopout && loopout.name != null) {
        //   names.add((DesignMainStrandLoopoutName()
        //     ..loopout = loopout
        //     ..prev_domain = prev_domain
        //     ..next_domain = next_domain
        //     ..geometry = props.geometry
        //     ..font_size = props.domain_name_font_size
        //     ..show_dna = props.show_dna
        //     ..className = constants.css_selector_loopout_name
        //     ..key = "loopout-label-$i")());
        // }
      } else if (substrand is Extension) {
        // Extension ext = substrand;
        // int adj_helix_idx = ext.adjacent_domain.helix;
        // bool draw_loopout = should_draw_extension(
        //     adj_helix_idx, props.side_selected_helix_idxs, props.only_display_selected_helices);
        // if (draw_loopout && ext.name != null) {
        //   names.add((DesignMainStrandExtensionName()
        //     ..ext = ext
        //     ..geometry = props.geometry
        //     ..font_size = props.domain_name_font_size
        //     ..show_dna = props.show_dna
        //     ..className = constants.css_selector_extension_name
        //     ..key = "extension-label-$i")());
        // }
      } else {
        throw AssertionError('substrand must be Domain, Loopout, or Extension');
      }
      i++;
    }
    return names;
  }
}
