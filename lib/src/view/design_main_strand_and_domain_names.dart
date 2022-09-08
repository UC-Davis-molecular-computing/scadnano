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
import 'design_main_strand_domain_name.dart';
import 'design_main_strand_strand_name.dart';
import 'design_main_strand_loopout_name.dart';
import 'design_main_strand_extension_name.dart';
import 'pure_component.dart';
import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_and_domain_names.over_react.g.dart';

UiFactory<DesignMainStrandAndDomainNamesProps> DesignMainStrandAndDomainNames =
    _$DesignMainStrandAndDomainNames;

// shows both domain and strand names
mixin DesignMainStrandAndDomainNamesPropsMixin on UiProps {
  Strand strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool show_dna;

  bool show_domain_names;
  bool show_strand_names;
  int domain_name_font_size;
  int strand_name_font_size;

  BuiltMap<int, Point<num>> helix_idx_to_svg_position;

  List<ContextMenuItem> Function(Strand strand, {Substrand substrand, Address address, ModificationType type})
      context_menu_strand;
}

class DesignMainStrandAndDomainNamesProps = UiProps
    with DesignMainStrandAndDomainNamesPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainStrandAndDomainNamesComponent extends UiComponent2<DesignMainStrandAndDomainNamesProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandAndDomainNamesProps> {
  @override
  render() {
    if (!(props.show_domain_names || props.show_strand_names)) {
      return null;
    }

    List<ReactElement> name_components = [];

    if (props.show_strand_names) {
      ReactElement strand_component = _draw_strand_name();
      if (strand_component != null) {
        name_components.add(strand_component);
      }
    }

    if (props.show_domain_names) {
      List<ReactElement> domain_name_components = _draw_domain_names();
      if (domain_name_components.isNotEmpty) {
        name_components.add((Dom.g()
          ..className = 'domain-names'
          ..key = 'domain-names')(domain_name_components));
      }
    }

    if (name_components.isEmpty) {
      return null;
    }

    return (Dom.g()..className = 'domain-and-strand-names')(name_components);
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
      strand_name_component = (DesignMainStrandStrandName()
        ..strand = props.strand
        ..domain = domain_5p
        ..helix = helix
        ..helix_groups = props.groups
        ..geometry = props.geometry
        ..font_size = props.strand_name_font_size
        ..transform = transform_of_helix(domain_5p.helix)
        ..helix_svg_position = helix_svg_position
        ..show_dna = props.show_dna
        ..context_menu_strand = props.context_menu_strand
        ..show_domain_names = props.show_domain_names
        ..className = constants.css_selector_strand_name
        ..key = "strand-name")();
    }
    return strand_name_component;
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
          names.add((DesignMainStrandDomainName()
            ..strand = props.strand
            ..domain = substrand
            ..helix = helix
            ..helix_groups = props.groups
            ..geometry = props.geometry
            ..font_size = props.domain_name_font_size
            ..transform = transform_of_helix(domain.helix)
            ..helix_svg_position = helix_svg_position
            ..show_dna = props.show_dna
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
}
