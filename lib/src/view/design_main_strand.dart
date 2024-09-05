import 'dart:convert';
import 'dart:html';

import 'package:dialog/dialog.dart';
import 'package:meta/meta.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;

import '../util.dart';
import 'design_main_strand_and_domain_texts.dart';
import 'design_main_strand_dna_end.dart';
import 'design_main_strand_modification.dart';
import 'transform_by_helix_group.dart';
import '../state/vendor_fields.dart';
import '../state/modification_type.dart';
import '../state/substrand.dart';
import '../state/modification.dart';
import '../state/address.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/dialog.dart';
import '../state/dna_end.dart';
import '../state/helix.dart';
import '../state/selectable.dart';
import '../dna_sequence_constants.dart';
import '../state/context_menu.dart';
import '../state/crossover.dart';
import '../state/loopout.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import '../state/extension.dart';
import '../state/dna_assign_options.dart';
import 'design_main_strand_deletion.dart';
import 'design_main_strand_insertion.dart';
import 'design_main_strand_modifications.dart';
import 'design_main_strand_paths.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import 'pure_component.dart';

part 'design_main_strand.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
mixin DesignMainStrandPropsMixin on UiProps {
  Strand strand;

  BuiltSet<int> side_selected_helix_idxs; // null if only_display_selected_helices is false
  bool only_display_selected_helices;

  BuiltSet<DNAEnd> selected_ends_in_strand;
  BuiltSet<Crossover> selected_crossovers_in_strand;
  BuiltSet<Loopout> selected_loopouts_in_strand;
  BuiltSet<Extension> selected_extensions_in_strand;
  BuiltSet<Domain> selected_domains_in_strand;
  BuiltSet<SelectableDeletion> selected_deletions_in_strand;
  BuiltSet<SelectableInsertion> selected_insertions_in_strand;
  BuiltSet<SelectableModification> selected_modifications_in_strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  bool selected;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  DNAAssignOptions dna_assign_options;
  bool modification_display_connector;
  bool show_dna;
  bool show_modifications;
  bool display_reverse_DNA_right_side_up;
  bool show_strand_names;
  bool show_strand_labels;
  bool show_domain_names;
  bool show_domain_labels;
  num strand_name_font_size;
  num strand_label_font_size;
  num domain_name_font_size;
  num domain_label_font_size;
  num modification_font_size;
  bool invert_y;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
  bool retain_strand_color_on_selection;
}

class DesignMainStrandProps = UiProps with DesignMainStrandPropsMixin, TransformByHelixGroupPropsMixin;

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandProps> {
  @override
  render() {
    if (props.strand.substrands.length == 0) {
      return null;
    }

    var classname = constants.css_selector_strand;
    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    // only store enough of helix svg positions for helices this strand has
    Map<int, Point<num>> helix_idx_to_svg_position_y_map_on_strand_unbuilt = {};
    var helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map;
    for (var domain in props.strand.domains) {
      int helix_idx = domain.helix;
      if (props.side_selected_helix_idxs == null || props.side_selected_helix_idxs.contains(helix_idx)) {
        // If props.side_selected_helix_idxs == null, then we are displaying all helices and need to
        // include this helix. Otherwise we are not displaying unselected helices.
        // In that case if props.side_selected_helix_idxs.contains(helix_idx) is false,
        // then helix_idx will not even be in helix_idx_to_svg_position_map.
        // since the memoized getter for AppState.helix_idx_to_svg_position_map skips it.
        // But we won't need it anyway in that case.
        var svg_pos = helix_idx_to_svg_position_map[helix_idx];
        helix_idx_to_svg_position_y_map_on_strand_unbuilt[domain.helix] = svg_pos;
      }
    }
    BuiltMap<int, Point<num>> helix_idx_to_svg_position_y_map_on_strand =
        helix_idx_to_svg_position_y_map_on_strand_unbuilt.build();

    return (Dom.g()
      ..id = props.strand.id
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
//      ..onContextMenu = strand_context_menu // this is handled when clicking on domain
      ..className = classname)([
      (DesignMainStrandPaths()
        ..strand = props.strand
        ..key = 'strand-paths'
        ..show_domain_names = props.show_domain_names
        ..helices = props.helices
        ..groups = props.groups
        ..selected_ends_in_strand = props.selected_ends_in_strand
        ..selected_crossovers_in_strand = props.selected_crossovers_in_strand
        ..selected_loopouts_in_strand = props.selected_loopouts_in_strand
        ..selected_extensions_in_strand = props.selected_extensions_in_strand
        ..selected_domains_in_strand = props.selected_domains_in_strand
        ..context_menu_strand = context_menu_strand
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..strand_tooltip = tooltip_text(props.strand)
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..geometry = props.geometry
        ..helix_idx_to_svg_position_map = helix_idx_to_svg_position_y_map_on_strand
        ..only_display_selected_helices = props.only_display_selected_helices
        ..retain_strand_color_on_selection = props.retain_strand_color_on_selection)(),
      _insertions(),
      _deletions(),
      if (props.show_domain_names ||
          props.show_strand_names ||
          props.show_strand_labels ||
          props.show_domain_labels)
        (DesignMainStrandAndDomainTexts() // shows both domain and strand names
          ..strand = props.strand
          ..helices = props.helices
          ..groups = props.groups
          ..geometry = props.geometry
          ..show_dna = props.show_dna
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..show_strand_names = props.show_strand_names
          ..show_strand_labels = props.show_strand_labels
          ..show_domain_names = props.show_domain_names
          ..show_domain_labels = props.show_domain_labels
          ..strand_name_font_size = props.strand_name_font_size
          ..strand_label_font_size = props.strand_label_font_size
          ..domain_name_font_size = props.domain_name_font_size
          ..domain_label_font_size = props.domain_label_font_size
          ..context_menu_strand = context_menu_strand
          ..helix_idx_to_svg_position = helix_idx_to_svg_position_y_map_on_strand
          ..key = 'names-and-labels')(),
      if (props.show_modifications)
        (DesignMainStrandModifications()
          ..strand = props.strand
          ..helices = props.helices
          ..groups = props.groups
          ..geometry = props.geometry
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..selected_modifications_in_strand = props.selected_modifications_in_strand
          ..font_size = props.modification_font_size
          ..display_connector = props.modification_display_connector
          ..helix_idx_to_svg_position_y_map =
              props.helix_idx_to_svg_position_map.map((i, p) => MapEntry(i, p.y))
          ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
          ..key = 'modifications')(),
    ]);
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (strand_selectable(props.strand)) {
        // select/deselect
        props.strand.handle_selection_mouse_down(event);
        // set up drag detection for moving DNA ends
        var address = util.find_closest_address(
            event, props.helices.values, props.groups, props.geometry, props.helix_idx_to_svg_position_map);

        // helices_view_order_inverse must contain helices_view_order_inverse of all groups since strands might cover different groups
        Map<int, int> helices_view_order_inverse = {};
        for (HelixGroup hg in app.state.design.groups.values) {
          helices_view_order_inverse.addAll(hg.helices_view_order_inverse.toMap());
        }
        app.dispatch(actions.StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: helices_view_order_inverse.build()));
      }
    }
  }

  handle_click_up(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      //XXX: This is tricky. If we condition on !props.currently_moving, then this achieves something we
      // want, which is that if we are moving a group of strands, and we are in a disallowed position where
      // the pointer itself (so also some strands) are positioned directly over a visible part of a strand,
      // then it would otherwise become selected on mouse up, when really we just want to end the move.
      bool currently_moving = app.state.ui_state.strands_move != null ||
          app.state.ui_state.domains_move != null ||
          app.state.ui_state.dna_ends_are_moving;
      if (strand_selectable(props.strand) && !currently_moving) {
        props.strand.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  assign_dna() => app.disable_keyboard_shortcuts_while(
      () => ask_for_assign_dna_sequence(props.strand, props.dna_assign_options));

  assign_dna_complement_from_bound_strands() {
    List<Strand> strands_selected = app.state.ui_state.selectables_store.selected_strands.toList();

    if (!strands_selected.contains(props.strand)) {
      strands_selected.add(props.strand);
    }

    var action = actions.AssignDNAComplementFromBoundStrands(strands_selected);
    app.dispatch(action);
  }

  assign_domain_name_complement_from_bound_strands({Domain domain}) {
    if (app.state.ui_state.select_mode_state.domains_selectable) {
      List<Domain> domains_selected = app.state.ui_state.selectables_store.selected_domains.toList();

      if (!domains_selected.contains(domain)) {
        domains_selected.add(domain);
      }

      var action = actions.AssignDomainNameComplementFromBoundDomains(domains_selected);
      app.dispatch(action);
    } else {
      List<Strand> strands_selected = app.state.ui_state.selectables_store.selected_strands.toList();
      if (!strands_selected.contains(props.strand)) {
        strands_selected.add(props.strand);
      }
      var action = actions.AssignDomainNameComplementFromBoundStrands(strands_selected);
      app.dispatch(action);
    }
  }

  add_modification(Substrand substrand, Address address, ModificationType type) =>
      app.disable_keyboard_shortcuts_while(
          () => ask_for_add_modification(props.strand, substrand, address, type));

  focus_base_oxview(Strand strand, Substrand substrand, Address address, ModificationType type) {
    int strand_idx = app.state.design.strands.indexOf(strand);
    int nt_idx_in_strand = address != null ? clicked_strand_dna_idx(substrand, address, strand) : 0;
    String js_highlight_base = '''\
let base = systems[0].strands[${strand_idx}].getMonomers()[${nt_idx_in_strand}];
api.findElement(base);
api.selectElements([base]);''';
    String text_blob_type = blob_type_to_string(BlobType.text);
    Blob blob_js_highlight_base = new Blob([js_highlight_base], text_blob_type);
    Map<String, dynamic> message_js_commands = {
      'message': 'iframe_drop',
      'files': [blob_js_highlight_base],
      'ext': ['js'],
    };
    app.view.oxview_view.frame.contentWindow
        ?.postMessage(message_js_commands, 'https://sulcgroup.github.io/oxdna-viewer/');
  }

  assign_scale_purification_fields() =>
      app.disable_keyboard_shortcuts_while(ask_for_assign_scale_purification_fields);

  assign_plate_well_fields() => app.disable_keyboard_shortcuts_while(ask_for_assign_plate_well_fields);

  set_strand_name() => app.disable_keyboard_shortcuts_while(
      () => ask_for_strand_name(props.strand, app.state.ui_state.selectables_store.selected_strands));

  set_strand_label() => app.disable_keyboard_shortcuts_while(
      () => ask_for_label(props.strand, null, app.state.ui_state.selectables_store.selected_strands));

  set_domain_names(BuiltSet<Domain> domains) =>
      app.disable_keyboard_shortcuts_while(() => ask_for_domain_names(domains));

  set_domain_labels(Substrand substrand, BuiltSet<Domain> domains) {
    return app.disable_keyboard_shortcuts_while(
        () => ask_for_label(props.strand, substrand, get_selected_domains()));
  }

  ReactElement _insertions() {
    List<ReactElement> paths = [];
    for (Domain domain in props.strand.domains) {
      Helix helix = props.helices[domain.helix];
      if (should_draw_domain(domain, props.side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var selectable_insertion in domain.selectable_insertions) {
          paths.add((DesignMainStrandInsertion()
            ..selectable_insertion = selectable_insertion
            ..selected = props.selected_insertions_in_strand.contains(selectable_insertion)
            ..helix = helix
            ..color = props.strand.color
            ..transform = transform_of_helix(domain.helix)
            ..svg_position_y = props.helix_idx_to_svg_position_map[helix.idx].y
            ..display_reverse_DNA_right_side_up = props.display_reverse_DNA_right_side_up
            ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
            ..key = util.id_insertion(domain, selectable_insertion.insertion.offset))());
        }
      }
    }
    return paths.isEmpty
        ? null
        : (Dom.g()
          ..key = 'insertions'
          ..className = 'insertions')(paths);
  }

  /// Assuming props contain helices mapping idx to Helix, groups mapping group names to groups,
  /// returns CSS transform String that can be passed to SVG components that need to be transformed
  /// specific to a HelixGroup.
  String compute_helix_transform(int helix_idx) {
    Helix helix = props.helices[helix_idx];
    var group = props.groups[helix.group];
    var transform_str = group.transform_str(props.geometry);
    return transform_str;
  }

  ReactElement _deletions() {
    List<ReactElement> paths = [];
    for (Domain domain in props.strand.domains) {
      Helix helix = props.helices[domain.helix];
      if (should_draw_domain(domain, props.side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var selectable_deletion in domain.selectable_deletions) {
          String id = util.id_deletion(domain, selectable_deletion.offset);
          paths.add((DesignMainStrandDeletion()
            ..selectable_deletion = selectable_deletion
            ..helix = helix
            ..selected = props.selected_deletions_in_strand.contains(selectable_deletion)
            ..transform = transform_of_helix(domain.helix)
            ..svg_position_y = props.helix_idx_to_svg_position_map[domain.helix].y
            ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
            ..key = id)());
        }
      }
    }
    return paths.isEmpty
        ? null
        : (Dom.g()
          ..key = 'deletions'
          ..className = 'deletions')(paths);
  }

  remove_dna() {
    app.disable_keyboard_shortcuts_while(() =>
        ask_for_remove_dna_sequence(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  set_color() {
    app.disable_keyboard_shortcuts_while(
        () => ask_for_color(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  reflect(bool horizontal, bool reverse_polarity) {
    var selected_strands = app.state.ui_state.selectables_store.selected_strands;
    List<Strand> strands;
    if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == props.strand) {
      // set for single strand if nothing is selected, or exactly this strand is selected
      strands = [props.strand];
    } else {
      // if this strand is not selected, change it anyway along with all selected strands
      if (!selected_strands.contains(props.strand)) {
        strands = selected_strands.rebuild((b) => b.add(props.strand)).toList();
      } else {
        strands = selected_strands.toList();
      }
    }
    app.dispatch(actions.StrandsReflect(
        strands: strands.build(), horizontal: horizontal, reverse_polarity: reverse_polarity));
  }

  set_scaffold() {
    Strand strand = props.strand;
    var selected_strands = app.state.ui_state.selectables_store.selected_strands;
    actions.Action action = batch_if_multiple_selected(
        scaffold_set_strand_action_creator(!strand.is_scaffold), strand, selected_strands, "set scaffold");
    app.dispatch(action);
  }

  List<ContextMenuItem> context_menu_strand(Strand strand,
      {@required Substrand substrand,
      @required Address address,
      ModificationType type = ModificationType.internal}) {
    var items = [
      ContextMenuItem(
          title: 'edit DNA',
          nested: [
            ContextMenuItem(
              title: 'assign DNA',
              tooltip: '''\
Assign a specific DNA sequence to this strand (and optionally assign complementary
sequence to strands bound to it).
''',
              on_click: assign_dna,
            ),
            ContextMenuItem(
              title: 'assign DNA complement from bound strands',
              tooltip: '''\
If other strands bound to this strand (or the selected strands) have DNA already 
assigned, assign the complementary DNA sequence to this strand.
''',
              on_click: assign_dna_complement_from_bound_strands,
            ),
            if (strand.dna_sequence != null)
              ContextMenuItem(
                title: 'remove DNA',
                on_click: remove_dna,
              ),
          ].build()),
      ContextMenuItem(
        title: 'add modification',
        on_click: () => add_modification(substrand, address, type),
      ),
      if (app.state.ui_state.show_oxview)
        ContextMenuItem(
          title: 'focus in oxview',
          on_click: () => focus_base_oxview(props.strand, substrand, address, type),
        ),
      ContextMenuItem(
          title: 'edit vendor fields',
          nested: [
            ContextMenuItem(
              title: 'assign scale/purification fields',
              on_click: assign_scale_purification_fields,
            ),
            ContextMenuItem(
                title: 'assign plate/well fields',
                on_click: assign_plate_well_fields,
                disabled: app.state.ui_state.selectables_store.selected_strands
                        .toList()
                        .any((element) => element.vendor_fields == null) ||
                    props.strand.vendor_fields == null),
            if (app.state.ui_state.selectables_store.selected_strands
                    .toList()
                    .any((element) => element.vendor_fields != null) ||
                props.strand.vendor_fields != null)
              ContextMenuItem(
                title: 'remove all vendor fields',
                on_click: () => remove_vendor_fields(),
              ),
            if (app.state.ui_state.selectables_store.selected_strands.toList().any((element) =>
                    element.vendor_fields?.plate != null && element.vendor_fields?.well != null) ||
                props.strand.vendor_fields?.well != null && props.strand.vendor_fields?.purification != null)
              ContextMenuItem(
                title: 'remove plate/well vendor fields',
                on_click: () => remove_plate_well_fields(),
              ),
          ].build()),
      ContextMenuItem(
        title: strand.is_scaffold ? 'set as non-scaffold' : 'set as scaffold',
        on_click: set_scaffold,
      ),
      ContextMenuItem(
          title: 'color',
          nested: [
            ContextMenuItem(
                title: 'set strand color',
                on_click: () => app.dispatch(
                    actions.StrandOrSubstrandColorPickerShow(strand: props.strand, substrand: null))),
            ContextMenuItem(
                title: 'set domain color',
                on_click: () => app.dispatch(
                    actions.StrandOrSubstrandColorPickerShow(strand: props.strand, substrand: substrand))),
            if (substrand.color != null)
              ContextMenuItem(
                  title: 'remove domain color',
                  on_click: () => app.dispatch(actions.StrandOrSubstrandColorSet(
                      strand: props.strand, substrand: substrand, color: null))),
          ].build()),
      ContextMenuItem(
          title: 'edit name',
          nested: [
            ContextMenuItem(
              title: 'set strand name',
              on_click: set_strand_name,
            ),
            if (props.strand.name != null)
              ContextMenuItem(
                  title: 'remove strand name',
                  on_click: () => app.dispatch(batch_if_multiple_selected(
                      (strand) => actions.StrandNameSet(name: null, strand: strand),
                      props.strand,
                      app.state.ui_state.selectables_store.selected_strands,
                      'remove strand name'))),
            ContextMenuItem(
              title: 'set domain name',
              on_click: () => set_domain_names(get_selected_domains()),
            ),
            ContextMenuItem(
              title: 'assign domain name complement from bound strands',
              tooltip: '''\
If other strands bound to this strand (or the selected strands) have domain names already 
assigned, assign the complementary domain names sequence to this strand. To use this
feature for individual domains, set select mode to domain.
''',
              on_click: () => assign_domain_name_complement_from_bound_strands(domain: substrand),
            ),
            if (substrand.name != null)
              ContextMenuItem(
                  title: 'remove domain name',
                  on_click: () => app.dispatch(actions.BatchAction(
                      get_selected_domains().map((d) => actions.SubstrandNameSet(name: null, substrand: d)),
                      'remove domain names'))),
          ].build()),
      ContextMenuItem(
          title: 'edit label',
          nested: [
            ContextMenuItem(
              title: 'set strand label',
              on_click: set_strand_label,
            ),
            if (props.strand.label != null)
              ContextMenuItem(
                  title: 'remove strand label',
                  on_click: () => app.dispatch(batch_if_multiple_selected(
                      (strand) => actions.StrandLabelSet(label: null, strand: strand),
                      props.strand,
                      app.state.ui_state.selectables_store.selected_strands,
                      'remove strand label'))),
            ContextMenuItem(
              title: 'set domain label',
              on_click: () => set_domain_labels(substrand, get_selected_domains()),
            ),
            if (substrand.label != null)
              ContextMenuItem(
                  title: 'remove domain label',
                  on_click: () => app.dispatch(actions.BatchAction(
                      get_selected_domains().map((d) => actions.SubstrandLabelSet(label: null, substrand: d)),
                      'remove domain labels'))),
          ].build()),
      ContextMenuItem(
          title: 'reflect',
          nested: [
            ContextMenuItem(
              title: 'reflect horizontally',
              on_click: () => reflect(true, false),
              tooltip: '''\
replace strand(s) with horizontal mirror image, 
without reversing polarity "vertically"

For example,
before:
  strand's 5' end on helix 0
  strand's 3' end on helix 1
after:
  strand's 5' end on helix 0
  strand's 3' end on helix 1\
''',
            ),
            ContextMenuItem(
              title: 'reflect horizontally (reverse vertical polarity)',
              on_click: () => reflect(true, true),
              tooltip: '''\
replace strand(s) with horizontal mirror image, 
with polarity reversed "vertically" 

For example,
before:
  strand's 5' end on helix 0
  strand's 3' end on helix 1
after:
  strand's 5' end on helix 1
  strand's 3' end on helix 0\
''',
            ),
            ContextMenuItem(
              title: 'reflect vertically',
              on_click: () => reflect(false, false),
              tooltip: '''\
replace strand(s) with vertical mirror image, 
without reversing polarity "vertically"

For example,
before:
  strand's 5' end is on a helix below that of the strand's 3' end
after:
  strand's 5' end is still on a helix below that of the strand's 3' end\
''',
            ),
            ContextMenuItem(
              title: 'reflect vertically (reverse vertical polarity)',
              on_click: () => reflect(false, true),
              tooltip: '''\
replace strand(s) with vertical mirror image, 
with polarity reversed "vertically"

For example,
before:
  strand's 5' end is on a helix below that of the strand's 3' end
after:
  strand's 5' end is now on a helix above that of the strand's 3' end\
''',
            ),
          ].build()),
      ContextMenuItem(
          title: 'add extension',
          on_click: () => app.disable_keyboard_shortcuts_while(() => ask_for_add_extension(strand)),
          disabled: strand.has_5p_extension && strand.has_3p_extension),
    ];

    return items;
  }

  Future<void> ask_for_add_extension(Strand strand) async {
    if (strand.has_5p_extension && strand.has_3p_extension) {
      // This shouldn't be reachable since the context menu should not include the
      // add extension option in this case, but let's check just in case.
      window.alert("strand ${strand.name ?? strand.toString()} already has a 5' and 3' extension");
      return;
    }

    List<String> options = [];
    if (!strand.has_5p_extension) {
      options.add("5'");
    }
    if (!strand.has_3p_extension) {
      options.add("3'");
    }
    assert(options.isNotEmpty);

    int selected_index = 0;
    int extension_end_idx = 0;
    int num_bases_idx = 1;
    var items = List<DialogItem>.filled(2, null);
    items[extension_end_idx] =
        DialogRadio(label: 'end of strand', options: options, selected_idx: selected_index);
    items[num_bases_idx] = DialogInteger(
        label: 'number of bases', value: 5, tooltip: 'number of bases to include in this extension');

    var dialog = Dialog(
        title: 'add extension', items: items, type: DialogType.add_extension, use_saved_response: false);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String extension_end = (results[extension_end_idx] as DialogRadio).value;
    bool is_5p;
    if (extension_end == "3'") {
      is_5p = false;
    } else if (extension_end == "5'") {
      is_5p = true;
    } else {
      // should be unreachable
      window.alert("invalid selection ${extension_end}");
      return;
    }
    int num_bases = (results[num_bases_idx] as DialogInteger).value;

    actions.UndoableAction action =
        actions.ExtensionAdd(strand: props.strand, is_5p: is_5p, num_bases: num_bases);
    app.dispatch(action);
  }

  select_index_for_one_strand(String vendor_option, Set<String> options, bool default_index) {
    if (options.contains(vendor_option)) {
      return options.toList().indexOf(vendor_option);
    } else if (default_index) {
      return 1;
    } else {
      return 0;
    }
  }

  select_scale_index_for_multiple_strands(List<Strand> all_strands, Set<String> options) {
    bool all_same_scale =
        all_strands.every((element) => all_strands[0].vendor_fields?.scale == element.vendor_fields?.scale);
    bool default_scale_option = all_strands.every((element) => element.vendor_fields == null);

    if (all_same_scale)
      return select_index_for_one_strand(all_strands[0].vendor_fields?.scale, options, default_scale_option);
    else
      return 0;
  }

  custom_scale_value(List<Strand> all_strands) {
    bool all_same_scale =
        all_strands.every((element) => all_strands[0].vendor_fields?.scale == element.vendor_fields?.scale);
    if (all_same_scale)
      return all_strands[0].vendor_fields?.scale ?? "";
    else
      return "";
  }

  custom_purification_value(List<Strand> all_strands) {
    bool all_same_purification = all_strands.every(
        (element) => all_strands[0].vendor_fields?.purification == element.vendor_fields?.purification);
    if (all_same_purification)
      return all_strands[0].vendor_fields?.purification ?? "";
    else
      return "";
  }

  select_purification_index_for_multiple_strands(List<Strand> all_strands, Set<String> options) {
    bool all_same_purification = all_strands.every(
        (element) => all_strands[0].vendor_fields?.purification == element.vendor_fields?.purification);
    bool default_purification_option = all_strands.every((element) => element.vendor_fields == null);

    if (all_same_purification)
      return select_index_for_one_strand(
          all_strands[0].vendor_fields?.purification, options, default_purification_option);
    else
      return 0;
  }

  select_plate_number(List<Strand> all_strands) {
    bool all_same_plate =
        all_strands.every((element) => all_strands[0].vendor_fields?.plate == element.vendor_fields?.plate);
    if (all_same_plate) {
      return all_strands[0].vendor_fields?.plate;
    } else
      return null;
  }

  Future<void> ask_for_assign_scale_purification_fields() async {
    int scale_options_idx = 0;
    int custom_scale_check_idx = 1;
    int scale_custom_idx = 2;
    int purification_options_idx = 3;
    int custom_purification_check_idx = 4;
    int purification_custom_idx = 5;
    var all_strands = app.state.ui_state.selectables_store.selected_strands.toList();
    if (all_strands.length == 0) all_strands.add(props.strand);
    var items = List<DialogItem>.filled(6, null, growable: true);
    var options_purification = {"", "STD", "PAGE", "HPLC", "IEHPLC", "RNASE", "DUALHPLC", "PAGEHPLC"};
    var options_scale = {
      "",
      "25nm",
      "100nm",
      "250nm",
      "1um",
      "2um",
      "5um",
      "10um",
      "4nmU",
      "20nmU",
      "PU",
      "25nmS",
    };

    items[custom_scale_check_idx] = DialogCheckbox(label: "use custom scale");
    items[scale_options_idx] = DialogRadio(
        label: "scale",
        options: options_scale,
        radio: false,
        tooltip: """\
25nm : 25nmole
100nm : 100 nmole
250nm : 250 nmole
1um : 1 µmole
2um	: 2 umole
5um	: 5 µmole
10um : 10 µmole
4nmU : 4 nmole Ultramer™
20nmU : 20 nmole Ultramer™
PU : PAGE Ultramer™
25nmS : 5 nmole Sameday
""",
        selected_idx: all_strands.length > 1
            ? select_scale_index_for_multiple_strands(all_strands, options_scale)
            : select_index_for_one_strand(props.strand.vendor_fields?.scale, options_scale,
                all_strands.every((element) => element.vendor_fields == null)));

    items[scale_custom_idx] = DialogText(
        label: "custom scale",
        value: items[scale_options_idx].value != "" ? "" : custom_scale_value(all_strands));

    items[custom_purification_check_idx] = DialogCheckbox(label: "use custom purification");
    items[purification_options_idx] = DialogRadio(
        label: "purification",
        options: options_purification,
        radio: false,
        tooltip: """\
STD	: Standard Desalting
PAGE : PAGE
HPLC : HPLC 
IEHPLC : IE HPLC
RNASE : RNase Free HPLC
DUALHPLC : Dual HPLC
PAGEHPLC : Dual PAGE & HPLC
""",
        selected_idx: all_strands.length > 1
            ? select_purification_index_for_multiple_strands(all_strands, options_purification)
            : select_index_for_one_strand(props.strand.vendor_fields?.purification, options_purification,
                all_strands.every((element) => element.vendor_fields == null)));

    items[purification_custom_idx] = DialogText(
        label: "custom purification",
        value: (items[purification_options_idx].value != "" ? "" : custom_purification_value(all_strands)));

    var dialog = Dialog(
        title: "assign scale/purification vendor fields",
        type: DialogType.assign_scale_purification,
        items: items,
        disable_when_any_checkboxes_off: {
          scale_custom_idx: [custom_scale_check_idx],
          purification_custom_idx: [custom_purification_check_idx]
        },
        disable_when_any_checkboxes_on: {
          scale_options_idx: [custom_scale_check_idx],
          purification_options_idx: [custom_purification_check_idx]
        });
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;
    String scale, purification;

    if ((results[custom_scale_check_idx] as DialogCheckbox).value) {
      scale = (results[scale_custom_idx] as DialogText).value;
    } else {
      scale = (results[scale_options_idx] as DialogRadio).value;
    }

    if ((results[custom_purification_check_idx] as DialogCheckbox).value) {
      purification = (results[purification_custom_idx] as DialogText).value;
    } else {
      purification = (results[purification_options_idx] as DialogRadio).value;
    }

    if (all_strands.length > 1) {
      for (var strand in all_strands) {
        var vendor_fields = VendorFields(
            scale: (scale == "" && strand.vendor_fields?.scale != null) ? strand.vendor_fields.scale : scale,
            purification: (purification == "" && strand.vendor_fields?.purification != null)
                ? strand.vendor_fields.purification
                : purification,
            plate: strand.vendor_fields?.plate,
            well: strand.vendor_fields?.well);
        var action =
            actions.ScalePurificationVendorFieldsAssign(vendor_fields: vendor_fields, strand: strand);
        app.dispatch(action);
      }
    } else {
      var vendor_fields = VendorFields(scale: scale, purification: purification);
      var action =
          actions.ScalePurificationVendorFieldsAssign(vendor_fields: vendor_fields, strand: props.strand);
      app.dispatch(action);
    }
  }

  Future<void> ask_for_assign_plate_well_fields() async {
    int plate_idx = 0;
    int well_idx = 1;
    var all_strands = app.state.ui_state.selectables_store.selected_strands.toList();
    if (all_strands.length == 0) all_strands.add(props.strand);
    var items = List<DialogItem>.filled(2, null, growable: true);

    items[plate_idx] = DialogText(label: "plate", value: select_plate_number(all_strands) ?? "");
    items[well_idx] = DialogText(
        label: "well",
        value: props.strand.vendor_fields?.well != null ? props.strand.vendor_fields.well : "",
        tooltip: all_strands.length > 1 ? "Only individual strands can have a well assigned." : "");
    var dialog = Dialog(
        title: "assign plate/well vendor fields",
        type: DialogType.assign_plate_well,
        items: items,
        disable: {if (all_strands.length > 1) well_idx});

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;
    String well, plate;
    plate = (results[plate_idx] as DialogText).value;
    List<String> conflicting_strands = [];
    if (all_strands.length > 1) {
      for (var strand in all_strands) {
        if (strand.vendor_fields == null)
          conflicting_strands.add("${strand.address_5p}");
        else {
          var vendor_fields = VendorFields(
              scale: strand.vendor_fields.scale,
              purification: strand.vendor_fields.purification,
              plate: (plate == "") ? strand.vendor_fields.plate : plate,
              well: (strand.vendor_fields?.well != null) ? strand.vendor_fields.well : "");
          var action = actions.PlateWellVendorFieldsAssign(vendor_fields: vendor_fields, strand: strand);
          app.dispatch(action);
        }
      }
    } else {
      well = (results[well_idx] as DialogText).value;
      if (props.strand.vendor_fields == null)
        conflicting_strands.add("${props.strand.address_5p}");
      else {
        var vendor_fields = VendorFields(
            scale: props.strand.vendor_fields.scale,
            purification: props.strand.vendor_fields.purification,
            plate: plate,
            well: well);
        var action = actions.PlateWellVendorFieldsAssign(vendor_fields: vendor_fields, strand: props.strand);
        app.dispatch(action);
      }
    }
    if (conflicting_strands.length >= 1)
      window.alert("No vendor fields were assigned to strands: $conflicting_strands. \n"
          "Assign scale and purification before editing plate/well fields.");
  }

  remove_plate_well_fields() {
    var all_strands = app.state.ui_state.selectables_store.selected_strands.toList();
    if (all_strands.length == 0) all_strands.add(props.strand);
    List<actions.UndoableAction> all_actions = [];
    for (var strand in all_strands) {
      var action = actions.PlateWellVendorFieldsRemove(strand: strand);
      app.dispatch(action);
    }
    var batch_action = actions.BatchAction(all_actions, "remove plate/well fields");
    app.dispatch(batch_action);
  }

  remove_vendor_fields() {
    var all_strands = app.state.ui_state.selectables_store.selected_strands.toList();
    if (all_strands.length == 0) all_strands.add(props.strand);
    List<actions.UndoableAction> all_actions = [];
    for (var strand in all_strands) {
      var action = actions.VendorFieldsRemove(strand: strand);
      app.dispatch(action);
    }
    var batch_action = actions.BatchAction(all_actions, "remove vendor fields");
    app.dispatch(batch_action);
  }

  Future<void> ask_for_strand_name(Strand strand, BuiltSet<Strand> selected_strands) async {
    int name_idx = 0;
    var items = List<DialogItem>.filled(1, null);
    items[name_idx] = DialogText(label: 'name', value: props.strand.name ?? '');
    var dialog = Dialog(
        title: 'set strand name', type: DialogType.set_strand_name, items: items, use_saved_response: false);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    actions.UndoableAction action = batch_if_multiple_selected(
        name_set_strand_action_creator(name), strand, selected_strands, "set strand names");
    app.dispatch(action);
  }

  Future<void> ask_for_domain_names(BuiltSet<Domain> domains) async {
    int name_idx = 0;
    var items = List<DialogItem>.filled(1, null);
    items[name_idx] = DialogText(label: 'name', value: "");
    var dialog = Dialog(
        title: 'set ${domains.first.type_description()} name',
        items: items,
        type: DialogType.set_domain_name,
        use_saved_response: false);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    return app.dispatch(actions.BatchAction(
        domains.map((d) => actions.SubstrandNameSet(name: name, substrand: d)), "set domain names"));
  }
}

Future<void> ask_for_label<T extends SelectableMixin>(
    Strand strand, Substrand substrand, BuiltSet<T> selected_strands) async {
  String part_name = 'strand';
  if (substrand != null) {
    part_name = substrand.type_description();
  }

  int label_idx = 0;
  var items = List<DialogItem>.filled(1, null);

  String existing_label = '';
  if (substrand == null && strand.label != null) {
    existing_label = strand.label;
  } else if (substrand != null && substrand.label != null) {
    existing_label = substrand.label;
  }

  items[label_idx] = DialogTextArea(
      label: 'label',
      value: existing_label,
      cols: 40,
      rows: 8,
      tooltip: "Enter the ${part_name} label here.");

  var dialog = Dialog(
      title: 'set ${part_name} label',
      type: substrand == null ? DialogType.set_strand_label : DialogType.set_substrand_label,
      items: items,
      use_saved_response: false);

  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String label = (results[label_idx] as DialogTextArea).value;

  actions.UndoableAction action;
  if (substrand == null) {
    action = batch_if_multiple_selected(label_set_strand_action_creator(label), strand,
        selected_strands as BuiltSet<Strand>, "set strand label");
  } else {
    action = actions.BatchAction(
        selected_strands.map((s) => actions.SubstrandLabelSet(label: label, substrand: (s as Substrand))),
        "set substrand labels");
  }

  app.dispatch(action);
}

actions.UndoableAction batch_if_multiple_selected(StrandActionCreator action_creator, Strand strand,
    BuiltSet<Strand> selected_strands, String short_description) {
  actions.Action action;
  if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == strand) {
    // set for single strand if nothing is selected, or exactly this strand is selected
    action = action_creator(strand);
  } else {
    // if this strand is not selected, change it anyway along with all selected strands
    if (!selected_strands.contains(strand)) {
      selected_strands = selected_strands.rebuild((b) => b.add(strand));
    }
    action =
        actions.BatchAction([for (var strand in selected_strands) action_creator(strand)], short_description);
  }
  return action;
}

// this is so if user selects with the domain select tool, it still returns the selected domains
// as opposed to just using "selected_strands"
BuiltSet<Domain> get_selected_domains() {
  return BuiltSet<Domain>(app.state.ui_state.selectables_store.selected_strands
          .map((s) => s.substrands)
          .expand((l) => l)
          .toBuiltSet())
      .union(app.state.ui_state.selectables_store.selected_domains);
}

typedef StrandActionCreator = actions.UndoableAction Function(Strand strand);

StrandActionCreator scaffold_set_strand_action_creator(bool is_scaffold) =>
    ((Strand strand) => actions.ScaffoldSet(strand: strand, is_scaffold: is_scaffold));

StrandActionCreator remove_dna_strand_action_creator(bool remove_complements, bool remove_all) =>
    ((Strand strand) =>
        actions.RemoveDNA(strand: strand, remove_complements: remove_complements, remove_all: remove_all));

StrandActionCreator color_set_strand_action_creator(String color_hex) => ((Strand strand) =>
    actions.StrandOrSubstrandColorSet(strand: strand, substrand: null, color: Color.hex(color_hex)));

StrandActionCreator color_set_substrand_action_creator(Substrand substrand, String color_hex) =>
    ((Strand strand) =>
        actions.StrandOrSubstrandColorSet(strand: strand, substrand: substrand, color: Color.hex(color_hex)));

StrandActionCreator name_set_strand_action_creator(String name) =>
    ((Strand strand) => actions.StrandNameSet(strand: strand, name: name));

StrandActionCreator label_set_strand_action_creator(String label) =>
    ((Strand strand) => actions.StrandLabelSet(strand: strand, label: label));

StrandActionCreator label_set_substrand_action_creator(Substrand substrand, String label) =>
    ((Strand strand) => actions.SubstrandLabelSet(substrand: substrand, label: label));

String tooltip_text(Strand strand) =>
    "Strand:\n" +
    (strand.name == null ? "" : "    name=${strand.name}\n") +
    "    length=${strand.dna_length}\n" +
    (!strand.circular ? "" : "    circular\n") +
    "    5' end=${tooltip_end(strand.first_domain, strand.dnaend_5p)}\n" +
    "    3' end=${tooltip_end(strand.last_domain, strand.dnaend_3p)}\n" +
    (strand.label == null ? "" : "    label=${strand.label.toString()}\n") +
    (strand.vendor_fields == null ? "" : "    vendor fields=\n${strand.vendor_fields.tooltip()}");

String tooltip_end(Domain ss, DNAEnd end) => "(helix=${ss.helix}, offset=${end.offset_inclusive})";

bool should_draw_domain(
        Domain ss, BuiltSet<int> side_selected_helix_idxs, bool only_display_selected_helices) =>
    !only_display_selected_helices || side_selected_helix_idxs.contains(ss.helix);

class DNARemoveOptions {
  bool remove_complements; // remove from this strand and all strands bound to it
  bool remove_all; // remove from all strands in design

  DNARemoveOptions({this.remove_complements = false, this.remove_all = false});
}

int clicked_strand_dna_idx(Domain domain, Address address, Strand strand) {
  int strand_dna_idx = 0;
  int domain_dna_idx = domain.substrand_offset_to_substrand_dna_idx(address.offset, address.forward);
  int index_of_domain_in_strand = strand.substrands.indexOf(domain);
  for (int i = 0; i < index_of_domain_in_strand; i++) {
    strand_dna_idx += strand.substrands[i].dna_length();
  }
  strand_dna_idx += domain_dna_idx;
  return strand_dna_idx;
}

Future<void> ask_for_assign_dna_sequence(Strand strand, DNAAssignOptions options) async {
  int idx_sequence = 0;
  int idx_use_predefined_dna_sequence = 1;
  int idx_predefine_sequence_link = 2;
  int idx_predefined_sequence_name = 3;
  int idx_rotation = 4;
  int idx_assign_complements = 5;
  int idx_disable_change_sequence_bound_strand = 6;

  List<DialogItem> items = [null, null, null, null, null, null, null];

  items[idx_sequence] =
      DialogTextArea(label: 'sequence', value: strand.dna_sequence ?? '', rows: 4, cols: 80);
  items[idx_use_predefined_dna_sequence] =
      DialogCheckbox(label: 'use predefined DNA sequence', value: options.use_predefined_dna_sequence);
  items[idx_predefined_sequence_name] =
      DialogRadio(label: 'predefined DNA sequence', options: DNASequencePredefined.display_names);
  items[idx_rotation] =
      DialogInteger(label: 'rotation of predefined DNA sequence', value: options.m13_rotation);
  items[idx_assign_complements] =
      DialogCheckbox(label: 'assign complement to bound strands', value: options.assign_complements);
  items[idx_disable_change_sequence_bound_strand] = DialogCheckbox(
      label: 'disallow assigning different sequence to bound strand with existing sequence',
      value: options.disable_change_sequence_bound_strand);
  items[idx_predefine_sequence_link] = DialogLink(
      label: 'Information about sequence variants',
      link: 'https://scadnano-python-package.readthedocs.io/en/latest/#scadnano.M13Variant');

  var dialog = Dialog(
      title: 'assign DNA sequence',
      type: DialogType.assign_dna_sequence,
      items: items,
      use_saved_response: false,
      disable_when_any_checkboxes_on: {
        idx_sequence: [idx_use_predefined_dna_sequence]
      },
      disable_when_any_checkboxes_off: {
        idx_predefined_sequence_name: [idx_use_predefined_dna_sequence],
        idx_rotation: [idx_use_predefined_dna_sequence],
        idx_disable_change_sequence_bound_strand: [idx_assign_complements],
      });
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String dna_sequence;

  int m13_rotation = options.m13_rotation;
  bool use_predefined_dna_sequence = (results[idx_use_predefined_dna_sequence] as DialogCheckbox).value;
  if (use_predefined_dna_sequence) {
    String predefined_sequence_display_name = (results[idx_predefined_sequence_name] as DialogRadio).value;
    m13_rotation = (results[idx_rotation] as DialogInteger).value;
    dna_sequence =
        DNASequencePredefined.dna_sequence_by_name(predefined_sequence_display_name, true, m13_rotation);
  } else {
    dna_sequence = (results[idx_sequence] as DialogTextArea).value;
  }

  bool assign_complements = (results[idx_assign_complements] as DialogCheckbox).value;
  bool disable_change_sequence_bound_strand =
      (results[idx_disable_change_sequence_bound_strand] as DialogCheckbox).value;

  try {
    util.check_dna_sequence(dna_sequence);
  } on FormatException catch (e) {
    window.alert(e.message);
    return;
  }

  var new_options = DNAAssignOptions(
    dna_sequence: dna_sequence,
    use_predefined_dna_sequence: use_predefined_dna_sequence,
    assign_complements: assign_complements,
    disable_change_sequence_bound_strand: disable_change_sequence_bound_strand,
    m13_rotation: m13_rotation,
  );
  app.dispatch(actions.AssignDNA(strand: strand, dna_assign_options: new_options));
}

Future<void> ask_for_remove_dna_sequence(Strand strand, BuiltSet<Strand> selected_strands) async {
  var dialog = Dialog(title: 'remove DNA sequence', type: DialogType.remove_dna_sequence, items: [
    DialogCheckbox(label: 'remove from bound strands', value: true),
    DialogCheckbox(label: 'remove from all strands', value: false),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  bool remove_complements = (results[0] as DialogCheckbox).value;
  bool remove_all = (results[1] as DialogCheckbox).value;

  actions.Action action = batch_if_multiple_selected(
      remove_dna_strand_action_creator(remove_complements, remove_all),
      strand,
      selected_strands,
      "remove dna sequence");
  app.dispatch(action);
}

Future<void> ask_for_color(Strand strand, BuiltSet<Strand> selected_strands) async {
  var dialog = Dialog(title: 'set color', type: DialogType.set_color, items: [
    DialogText(
      label: 'color',
//      label: 'color (hex rgb, e.g., "#00ff00")',
      value: strand.color.toHexColor().toCssString(),
    ),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String color_hex = (results[0] as DialogText).value;

  actions.Action action = batch_if_multiple_selected(
      color_set_strand_action_creator(color_hex), strand, selected_strands, "set strand color");
  app.dispatch(action);
}

String tooltip_attached_to_base_checkbox = '''\
If checked, then this internal modification is attached to a DNA base (such as internal biotin /iBiodT/). 
In that case the list of allowed DNA bases to which it can attach must be specified in the field 
"allowed bases". If unchecked, then this internal modification goes in between bases (e.g., a carbon linker
such as /iSp9/).''';

String tooltip_allowed_bases_textfield = '''\
For internal modifications that are attached to a base, this field specifies the bases to which 
it can be attached. (Any symbols other than ACGTacgt are ignored in this field). For instance,
IDT can only attach a biotin modification /iBiodT/ to a T base, so one would enter T in this field.''';
