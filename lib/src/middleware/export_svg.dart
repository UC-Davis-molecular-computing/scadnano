import 'dart:html';
import 'dart:svg' as svg;
import 'dart:svg';

import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

export_svg_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.ExportSvg || action is actions.CopySelectedStandsToClipboardImage) {
    var ui_state = store.state.ui_state;
    var dna_sequence_png_uri = ui_state.dna_sequence_png_uri;
    var is_zoom_above_threshold = ui_state.is_zoom_above_threshold;
    var export_svg_action_delayed_for_png_cache = ui_state.export_svg_action_delayed_for_png_cache;
    var disable_png_caching_dna_sequences = ui_state.disable_png_caching_dna_sequences;

    bool using_png_dna_sequence = util.use_png(dna_sequence_png_uri, is_zoom_above_threshold,
        export_svg_action_delayed_for_png_cache, disable_png_caching_dna_sequences);

    // If main needs to be exported, then the png needs to be disabled if currently being used.
    bool need_to_disable_png =
        (action is actions.CopySelectedStandsToClipboardImage || action.type == actions.ExportSvgType.main) &&
            using_png_dna_sequence;

    if (need_to_disable_png) {
      // Disables the png
      store.dispatch(actions.SetExportSvgActionDelayedForPngCache(action));

      // Note that the ExportSvgType action cannot be dispatched in this if branch because we need to
      // let this middleware resolve so that React can render the DNA sequences as an SVG.
    } else {
      if (action is actions.ExportSvg) {
        // Exports the appropriate svgs.
        if (action.type == actions.ExportSvgType.main ||
            action.type == actions.ExportSvgType.both ||
            action.type == actions.ExportSvgType.selected) {
          var elt = document.getElementById("main-view-svg");
          if (action.type == actions.ExportSvgType.selected) {
            List<Element> selected_elts = get_selected_strands(store);
            if (selected_elts.length == 0) {
              window.alert("No strands are selected, so there is nothing to export.\n"
                  "Please select some strands before choosing this option.");
            } else {
              var cloned_svg_element_with_style = get_cloned_svg_element_with_style(selected_elts);
              _export_from_element(cloned_svg_element_with_style, 'selected');
            }
          } else
            _export_from_element(elt, 'main');
        }
        if (action.type == actions.ExportSvgType.side || action.type == actions.ExportSvgType.both) {
          var elt = document.getElementById("side-view-svg");
          _export_from_element(elt, 'side');
        }
      } else if (action is actions.CopySelectedStandsToClipboardImage) {
        List<Element> selected_elts = get_selected_strands(store);
        if (selected_elts.length != 0) {
          _copy_from_elements(selected_elts);
        }
      }
    }
  } else {
    next(action);
  }
}

List<Element> get_selected_strands(Store<AppState> store) {
  var selected_strands = store.state.ui_state.selectables_store.selected_strands;
  List<Element> selected_elts = [];
  if (selected_strands.length != 0) {
    for (var strand in selected_strands) {
      var strand_elt = document.getElementById(strand.id);
      var dna_seq_elt = document.getElementById('dna-sequence-${strand.id}');
      var mismatch_elts = document.getElementsByClassName('mismatch-${strand.id}');
      selected_elts.addAll([strand_elt, if (dna_seq_elt != null) dna_seq_elt, ...mismatch_elts]);
    }
  }
  return selected_elts;
}

SvgSvgElement get_cloned_svg_element_with_style(List<Element> selected_elts) {
  var cloned_svg_element_with_style = SvgSvgElement()
    ..children = selected_elts.map(clone_and_apply_style).toList();

  // we can't get bbox without it being added to the DOM first
  document.body.append(cloned_svg_element_with_style);
  var bbox = cloned_svg_element_with_style.getBBox();
  cloned_svg_element_with_style.remove();

  // have to add some padding to viewbox, for some reason bbox doesn't always fit it by a few pixels??
  cloned_svg_element_with_style.setAttribute('viewBox',
      '${bbox.x.floor() - 1} ${bbox.y.floor() - 1} ${bbox.width.ceil() + 3} ${bbox.height.ceil() + 3}');

  return cloned_svg_element_with_style;
}

_export_svg(svg.SvgSvgElement svg_element, String filename_append) {
  var serializer = new XmlSerializer();
  var source = serializer.serializeToString(svg_element);
  //clipboard.write(source);
  //add name spaces.
  //    if(!source.match(r'/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)') {
  //      source = source.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
  //    }
  //    if(!source.match(/^<svg[^>]+"http\:\/\/www\.w3\.org\/1999\/xlink"/)){
  //      source = source.replace(/^<svg/, '<svg xmlns:xlink="http://www.w3.org/1999/xlink"');
  //    }

  //add xml declaration
  //  source = '<?xml version="1.1" standalone="no"?>\r\n' + source;

  //convert svg source to URI data scheme.
  //  var url = "data:image/svg+xml;charset=utf-8," + Uri.encodeComponent(source);

  //  String blob_type = "data:image/svg+xml;charset=utf-8,";

  String filename = app.state.ui_state.loaded_filename;
  filename = filename.substring(0, filename.lastIndexOf('.'));
  filename += '_${filename_append}.svg';

  util.save_file(filename, source, blob_type: util.BlobType.image);
}

_copy_from_elements(List<Element> svg_elements) {
  var cloned_svg_element_with_style = get_cloned_svg_element_with_style(svg_elements);
  util.copy_svg_as_png(cloned_svg_element_with_style);
}

_export_from_element(Element svg_element, String filename_append) {
  var cloned_svg_element_with_style;
  if (filename_append != "selected")
    cloned_svg_element_with_style = clone_and_apply_style(svg_element);
  else
    cloned_svg_element_with_style = svg_element;
  // if element is not an svg element (it can be a child element of svg e.g. groups, lines, text, etc), wrap in svg tag
  if (!(svg_element is svg.SvgSvgElement))
    cloned_svg_element_with_style = SvgSvgElement()..children = [cloned_svg_element_with_style];

  _export_svg(cloned_svg_element_with_style, filename_append);
}

const List<String> text_styles = [
  'font-size',
  'font-family',
  'font-weight',
  'text-anchor',
  'dominant-baseline',
  'fill',
  'letter-spacing',
];
const List<String> text_path_only_styles = [];

const List<String> path_styles = [
  'fill',
  'stroke',
  'stroke-width',
  'stroke-linecap',
  'stroke-opacity',
  'visibility',
];

final relevant_styles = {
  "rect": path_styles,
  "polygon": path_styles,
  "path": path_styles,
  "circle": path_styles,
  "line": path_styles,
  "text": text_styles,
  "textPath": text_styles + text_path_only_styles,
};

Element clone_and_apply_style(Element elt_orig) {
  Element elt_styled = elt_orig.clone(true);

  bool selected = elt_orig.classes.contains('selected');

  elt_orig.classes.remove('selected');
  clone_and_apply_style_rec(elt_styled, elt_orig);

  if (selected) elt_orig.classes.add('selected');

  // need to get from original since it has been rendered (styled hasn't been rendered so has 0 bounding box
  // also need to get from g element, not svg element, since svg element dimensions based on original
  // transformation, but g element gives untransformed bounding box.
  /*
  var bbox_orig_g = (svg_elt_orig.children.firstWhere((e) => e is svg.GElement) as svg.GElement).getBBox();

  // Adds boundary for elements located at negative svg
  svg_elt_styled.setAttribute('width', '${bbox_orig_g.width + 100}');
  svg_elt_styled.setAttribute('height', '${bbox_orig_g.height + 50}');
  */
  return elt_styled;
}

clone_and_apply_style_rec(Element elt_styled, Element elt_orig, {int depth = 0}) {
//  Set<Element> children_styled_to_remove = {};
  var tag_name = elt_styled.tagName;

  if (elt_styled.classes.contains('svg-pan-zoom_viewport')) {
    elt_styled.removeAttribute('style');
    bool side = elt_styled.id.contains('side');
    var transform = side ? 'matrix(1,0,0,1,50,50)' : 'matrix(1,0,0,1,100,50)';
    elt_styled.setAttribute('transform', transform);
  }

  if (relevant_styles.keys.contains(tag_name)) {
    var style_def = elt_orig.getComputedStyle();

    //TODO: figure out how to remove nodes that aren't visible;
    // getting error "Unsupported operation: Cannot setRange on filtered list" when removing children
//      if (style_def.visibility == 'hidden') {
//        children_styled_to_remove.add(child_styled);
//      }

    var style_strings = [];
    for (var style_name in relevant_styles[tag_name]) {
      var style_value = style_def.getPropertyValue(style_name);
      if (style_value != '') {
        // correcting for this bug in InkScape that causes it to render hidden SVG objects:
        // https://bugs.launchpad.net/inkscape/+bug/1577763
        if (style_name == 'visibility' && style_value == 'hidden') {
          style_strings.add('display: none');
        }
        style_strings.add('${style_name}: ${style_value}');
      }
    }
    var style_string = style_strings.join('; ') + ';';

    elt_styled.setAttribute("style", style_string);

//    print('${' ' * depth * 2} ${tag_name} ${elt_orig.classes.toList()} style: $style_string');
  }

//  svg_elt_styled.children.removeWhere((node) => children_styled_to_remove.contains(node));

  // recurse
  var children_styled = elt_styled.childNodes;
  var children_orig = elt_orig.childNodes;
  for (var cd = 0; cd < children_styled.length; cd++) {
    if (!(children_orig[cd] is Element)) {
      continue;
    }
    Element child_orig = children_orig[cd];
    Element child_styled = children_styled[cd];
    clone_and_apply_style_rec(child_styled, child_orig, depth: depth + 1);
  }

  return elt_styled;
}

/*
// https://stackoverflow.com/questions/15181452/how-to-save-export-inline-svg-styled-with-css-from-browser-to-image-file
var ContainerElements = ["svg","g"];
var RelevantStyles = {"rect":["fill","stroke","stroke-width"],"path":["fill","stroke","stroke-width"],"circle":["fill","stroke","stroke-width"],"line":["stroke","stroke-width"],"text":["fill","font-size","text-anchor"],"polygon":["stroke","fill"]};


function read_Element(ParentNode, OrigData){
    var Children = ParentNode.childNodes;
    var OrigChildDat = OrigData.childNodes;

    for (var cd = 0; cd < Children.length; cd++){
        var Child = Children[cd];

        var TagName = Child.tagName;
        if (ContainerElements.indexOf(TagName) != -1){
            read_Element(Child, OrigChildDat[cd])
        } else if (TagName in RelevantStyles){
            var StyleDef = window.getComputedStyle(OrigChildDat[cd]);

            var StyleString = "";
            for (var st = 0; st < RelevantStyles[TagName].length; st++){
                StyleString += RelevantStyles[TagName][st] + ":" + StyleDef.getPropertyValue(RelevantStyles[TagName][st]) + "; ";
            }

            Child.setAttribute("style",StyleString);
        }
    }

}

function export_StyledSVG(SVGElem){ /


    var oDOM = SVGElem.cloneNode(true)
    read_Element(oDOM, SVGElem)

    var data = new XMLSerializer().serializeToString(oDOM);
    var svg = new Blob([data], { type: "image/svg+xml;charset=utf-8" });
    var url = URL.createObjectURL(svg);

    var link = document.createElement("a");
    link.setAttribute("target","_blank");
    var Text = document.createTextNode("Export");
    link.appendChild(Text);
    link.href=url;

    document.body.appendChild(link);
}
 */
