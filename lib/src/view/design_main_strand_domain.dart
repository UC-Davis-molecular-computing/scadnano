import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';

import '../state/edit_mode.dart';
import '../state/strand.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../util.dart' as util;
import '../actions/actions.dart' as actions;
import 'edit_mode_queryable.dart';
import 'pure_component.dart';
import '../state/context_menu.dart';
import 'design_main_strand.dart';

part 'design_main_strand_domain.over_react.g.dart';

//UiFactory<DesignMainDomainProps> ConnectedDesignMainDomain =
//    connect<AppState, DesignMainDomainProps>(mapStateToPropsWithOwnProps: (state, props) {
//  return DesignMainDomain()
//    ..helix = state.dna_design.helices[props.substrand.helix]
//    ..edit_modes = state.ui_state.edit_modes;
//})(DesignMainDomain);

@Factory()
UiFactory<DesignMainDomainProps> DesignMainDomain = _$DesignMainDomain;

@Props()
mixin DesignMainDomainPropsMixin on UiProps {
  Domain domain;
  Color color;
  String dna_sequence;

  BuiltSet<EditModeChoice> edit_modes;
  Helix helix;
  String strand_tooltip;
  Strand strand;
  List<ContextMenuItem> Function(Strand strand) context_menu_strand;
}

class DesignMainDomainProps = UiProps with EditModePropsMixin, DesignMainDomainPropsMixin;

@Component2()
class DesignMainDomainComponent extends UiComponent2<DesignMainDomainProps>
    with PureComponent, EditModeQueryable<DesignMainDomainProps> {
  @override
  render() {
    Domain domain = props.domain;
    String id = domain.id();

    Point<num> start_svg = props.helix.svg_base_pos(domain.offset_5p, domain.forward);
    Point<num> end_svg = props.helix.svg_base_pos(domain.offset_3p, domain.forward);

    return (Dom.line()
      ..onClick = _handle_click
      ..stroke = props.color.toHexColor().toCssString()
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..key = id
      ..id = id
      ..className = 'domain-line')(Dom.svgTitle()(tooltip_text(domain) + '\n' + props.strand_tooltip));
  }

  _handle_click(SyntheticMouseEvent event_syn) {
    if (nick_mode || insertion_mode || deletion_mode) {
      var domain = props.domain;
      MouseEvent event = event_syn.nativeEvent;
      var address = util.get_address_on_helix(event, props.helix);
      int offset = address.offset;

      if (offset <= domain.start || offset >= domain.end) {
        return; // cannot have nick/insertion/deletion on end
      }

      if (nick_mode) {
        if (offset <= domain.start + 1 || offset >= domain.end - 1) {
          return; // need remaining substrands to be length at least 2
        }
        app.dispatch(actions.Nick(domain: domain, offset: offset));
      } else if (insertion_mode) {
        app.dispatch(actions.InsertionAdd(domain: domain, offset: offset));
      } else if (deletion_mode) {
        app.dispatch(actions.DeletionAdd(domain: domain, offset: offset));
      }
    }
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.domain.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.domain.id()}');
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
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

tooltip_text(Domain domain) => ''
    '${domain.forward ? 'forward' : 'reverse'} domain:\n'
    '    length=${domain.dna_length()}\n'
    '    helix=${domain.helix}\n'
    '    start=${domain.start}\n'
    '    end=${domain.end}' +
    (domain.label == null? "": "\n    label=${domain.label.toString()}");
