import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';

import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/bound_substrand.dart';
import '../util.dart' as util;
import '../actions/actions.dart' as actions;
import 'edit_mode_queryable.dart';
import 'pure_component.dart';
import '../state/context_menu.dart';
import 'design_main_strand.dart';

part 'design_main_strand_bound_substrand.over_react.g.dart';

//UiFactory<DesignMainBoundSubstrandProps> ConnectedDesignMainBoundSubstrand =
//    connect<AppState, DesignMainBoundSubstrandProps>(mapStateToPropsWithOwnProps: (state, props) {
//  return DesignMainBoundSubstrand()
//    ..helix = state.dna_design.helices[props.substrand.helix]
//    ..edit_modes = state.ui_state.edit_modes;
//})(DesignMainBoundSubstrand);

@Factory()
UiFactory<DesignMainBoundSubstrandProps> DesignMainBoundSubstrand = _$DesignMainBoundSubstrand;

@Props()
class _$DesignMainBoundSubstrandProps extends EditModePropsAbstract {
  BoundSubstrand substrand;
  Color color;
  String dna_sequence;

  BuiltSet<EditModeChoice> edit_modes;
  Helix helix;
  String strand_tooltip;
  Strand strand;
  List<ContextMenuItem> Function(Strand strand) context_menu_strand;
}

@Component2()
class DesignMainBoundSubstrandComponent extends UiComponent2<DesignMainBoundSubstrandProps>
    with PureComponent, EditModeQueryable<DesignMainBoundSubstrandProps> {
  @override
  render() {
    BoundSubstrand substrand = props.substrand;
    String id = substrand.id();

    Point<num> start_svg = props.helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    Point<num> end_svg = props.helix.svg_base_pos(substrand.offset_3p, substrand.forward);

    return (Dom.line()
      ..onClick = _handle_click
      ..stroke = props.color.toHexColor().toCssString()
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..key = id
      ..id = id
      ..className = 'substrand-line')(Dom.svgTitle()(tooltip_text(substrand) + '\n' + props.strand_tooltip));
  }

  _handle_click(SyntheticMouseEvent event_syn) {
    if (nick_mode || insertion_mode || deletion_mode) {
      var substrand = props.substrand;
      MouseEvent event = event_syn.nativeEvent;
      var address = util.get_address_on_helix(event, props.helix);
      int offset = address.offset;

      if (offset <= substrand.start || offset >= substrand.end) {
        return; // cannot have nick/insertion/deletion on end
      }

      if (nick_mode) {
        if (offset <= substrand.start + 1 || offset >= substrand.end - 1) {
          return; // need remaining substrands to be length at least 2
        }
        app.dispatch(actions.Nick(bound_substrand: substrand, offset: offset));
      } else if (insertion_mode) {
        app.dispatch(actions.InsertionAdd(substrand: substrand, offset: offset));
      } else if (deletion_mode) {
        app.dispatch(actions.DeletionAdd(substrand: substrand, offset: offset));
      }
    }
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.substrand.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.substrand.id()}');
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      app.dispatch(actions.ContextMenuShow(
          context_menu:
              ContextMenu(items: props.context_menu_strand(props.strand).build(), position: event.page)));
    }
  }
}

tooltip_text(BoundSubstrand substrand) => '${substrand.forward ? 'forward' : 'reverse'} substrand:\n'
    '    helix=${substrand.helix}\n'
    '    start=${substrand.start}\n'
    '    end=${substrand.end}';
