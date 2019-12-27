import 'dart:html';
import 'dart:svg' as svg;

import 'package:redux/redux.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

export_svg_main_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.ExportSvgMain) {
    var main = document.getElementById("main-view-svg");
    _export_from_element(main, 'design');
  } else {
    next(action);
  }
}

export_svg_side_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.ExportSvgSide) {
    var side = document.getElementById("side-view-svg");
    _export_from_element(side, 'cross-section');
  } else {
    next(action);
  }
}

_export_from_element(svg.SvgSvgElement svg_element, String filename_append) {
  //get svg source.
  var serializer = new XmlSerializer();
  var source = serializer.serializeToString(svg_element);

  //add name spaces.
//    if(!source.match(r'/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)') {
//      source = source.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
//    }
//    if(!source.match(/^<svg[^>]+"http\:\/\/www\.w3\.org\/1999\/xlink"/)){
//      source = source.replace(/^<svg/, '<svg xmlns:xlink="http://www.w3.org/1999/xlink"');
//    }

  //add xml declaration
  source = '<?xml version="1.0" standalone="no"?>\r\n' + source;

  //convert svg source to URI data scheme.
//  var url = "data:image/svg+xml;charset=utf-8," + Uri.encodeComponent(source);

//  String blob_type = "data:image/svg+xml;charset=utf-8,";
  String filename = app.state.ui_state.loaded_filename;
  filename = filename.substring(0, filename.lastIndexOf('.'));
  filename += '_${filename_append}.svg';

  util.save_file(filename, source, blob_type: util.BlobType.image);

  //set url value to a element's href attribute.
//  AnchorElement link = AnchorElement();
//  document.body.children.add(link);
//  link.href = url;
//  link.click();
//  print('SVG source: ${source}');
//  document.body.children.remove(link);
}

