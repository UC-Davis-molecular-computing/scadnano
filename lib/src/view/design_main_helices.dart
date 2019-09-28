//part of '../components.dart';

import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg; // hide Point;

import 'package:js/js.dart';
import 'package:quiver/iterables.dart' as iter;

import 'package:over_react/over_react.dart';
import 'package:react/react_dom.dart' as react_dom;
import 'package:react/react_client.dart';
import 'package:scadnano/src/view/design_main_helix.dart';

import '../dispatcher/actions.dart';
import 'view.dart';
import '../model/helix.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends FluxUiProps<HelicesStore, HelicesStore> {}

@Component()
class DesignMainHelicesComponent extends FluxUiComponent<DesignMainHelicesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    int idx = 0;
    return (Dom.g()..className = 'helices-main-view')([
      for (Helix helix in this.props.store.helices)
        (DesignMainHelix()
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}
