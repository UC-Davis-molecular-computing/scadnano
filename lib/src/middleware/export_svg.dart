import 'dart:html';
import 'dart:svg' as svg;
import 'dart:svg';
import 'dart:math' as math;

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/view/design_main_dna_sequence.dart';

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
            List<Element> selected_elts = get_selected_svg_elements(store.state);
            if (selected_elts.length == 0) {
              window.alert("No strands are selected, so there is nothing to export.\n"
                  "Please select some strands before choosing this option.");
            } else {
              var cloned_svg_element_with_style = get_cloned_svg_element_with_style(
                  selected_elts, store.state.ui_state.export_svg_text_separately);
              _export_from_element(cloned_svg_element_with_style, 'selected');
            }
          } else {
            if (store.state.ui_state.export_svg_text_separately) {
              elt = get_cloned_svg_element_with_style([elt], store.state.ui_state.export_svg_text_separately);
            }
            _export_from_element(elt, 'main');
          }
        }
        if (action.type == actions.ExportSvgType.side || action.type == actions.ExportSvgType.both) {
          var elt = document.getElementById("side-view-svg");
          _export_from_element(elt, 'side');
        }
      } else if (action is actions.CopySelectedStandsToClipboardImage) {
        List<Element> selected_elts = get_selected_svg_elements(store.state);
        if (selected_elts.length != 0) {
          _copy_from_elements(selected_elts);
        }
      }
    }
  } else {
    next(action);
  }
}

List<Element> get_selected_svg_elements(AppState state) {
  BuiltSet<Strand> selected_strands = state.ui_state.selectables_store.selected_strands;
  List<Element> selected_elts = [];
  if (app.state.ui_state.show_base_pair_lines) {
    var base_pairs = state.ui_state.show_base_pair_lines_with_mismatches
        ? state.design.selected_base_pairs_with_mismatches(selected_strands)
        : state.design.selected_base_pairs(selected_strands);
    selected_elts.addAll(get_svg_elements_of_base_pairs(base_pairs));
  }
  selected_elts.addAll(get_svg_elements_of_strands(selected_strands));
  return selected_elts;
}

List<Element> get_svg_elements_of_strands(BuiltSet<Strand> strands) {
  List<Element> elts = [];
  if (strands.length != 0) {
    for (var strand in strands) {
      var strand_elt = document.getElementById(strand.id);
      var dna_seq_elt = document.getElementById('dna-sequence-${strand.id}');
      var mismatch_elts = document.getElementsByClassName('mismatch-${strand.id}');
      elts.addAll([strand_elt, if (dna_seq_elt != null) dna_seq_elt, ...mismatch_elts]);
    }
  }
  return elts;
}

List<Element> get_svg_elements_of_base_pairs(BuiltMap<int, BuiltList<int>> base_pairs) {
  List<Element> elts = [];
  for (int helix in base_pairs.keys) {
    elts.addAll(base_pairs[helix].map((offset) => document.getElementById('base_pair-${helix}-${offset}')));
  }
  return elts;
}

List<double> rotate_vector(List<double> vec, double ang) {
  ang = ang * (math.pi / 180);
  var cos = math.cos(ang);
  var sin = math.sin(ang);
  return [vec[0] * cos - vec[1] * sin, vec[0] * sin + vec[1] * cos];
}

// gets the height of a character in font in px
double get_text_height(String font) {
  CanvasElement element = document.createElement("canvas");
  CanvasRenderingContext2D context = element.getContext("2d");
  context.font = font;
  return double.tryParse(context.font.replaceAll(RegExp(r'[^0-9\.]'), ''));
}

// returns a matrix that represents the change made by dominant-baseline css property
DomMatrix dominant_baseline_matrix(String dominant_baseline, double rot, String font) {
  switch (dominant_baseline) {
    case "ideographic":
      return new DomMatrix([
        1,
        0,
        0,
        1,
        ...rotate_vector([0, (-3 * get_text_height(font)) / 12], rot)
      ]);
    case "hanging":
      return new DomMatrix([
        1,
        0,
        0,
        1,
        ...rotate_vector([0, (9 * get_text_height(font)) / 12], rot)
      ]);
    case "central":
      return new DomMatrix([
        1,
        0,
        0,
        1,
        ...rotate_vector([0, (4 * get_text_height(font)) / 12], rot)
      ]);
    default:
      return new DomMatrix([1, 0, 0, 1, 0, 0]);
  }
}

Map matrix_to_map<T>(Matrix matrix) {
  return {
    "a": matrix.a,
    "b": matrix.b,
    "c": matrix.c,
    "d": matrix.d,
    "e": matrix.e,
    "f": matrix.f,
  };
}

Map dom_matrix_to_map(DomMatrix matrix) {
  return {
    "a": matrix.a,
    "b": matrix.b,
    "c": matrix.c,
    "d": matrix.d,
    "e": matrix.e,
    "f": matrix.f,
  };
}

Map point_to_map(svg.Point point) {
  return {"x": point.x, "y": point.y};
}

// creates a new separate text svg for the jth character on a svg text element
TextElement create_portable_element(TextContentElement text_ele, int j) {
  TextElement char_ele = document.createElementNS("http://www.w3.org/2000/svg", "text");
  char_ele.text = text_ele.text[j];
  char_ele.setAttribute("style", text_ele.style.cssText);
  var pos = DomPoint.fromPoint(point_to_map(text_ele.getStartPositionOfChar(j)));
  var rot = text_ele.getRotationOfChar(j);

  for (int i = 0; i < text_ele.transform.baseVal.numberOfItems; ++i) {
    var item = text_ele.transform.baseVal.getItem(i);
    pos = pos.matrixTransform(matrix_to_map(item.matrix));
    rot = item.angle;
  }
  if (char_ele.style.getPropertyValue("dominant-baseline") != "") {
    pos = pos.matrixTransform(dom_matrix_to_map(dominant_baseline_matrix(
        char_ele.style.getPropertyValue("dominant-baseline"),
        rot,
        text_ele.style.fontSize + " " + text_ele.style.fontFamily)));
  }
  char_ele.style.setProperty("dominant-baseline", "");
  char_ele.style.setProperty("text-anchor", "start");
  if (text_ele.classes.any([
    "loopout-extension-length",
    "dna-seq-insertion",
    "dna-seq-loopout",
    "dna-seq-extension",
    "dna-seq"
  ].contains)) {
    char_ele.style.setProperty(
        "text-shadow", // doesn't work in PowerPoint
        "-0.7px -0.7px 0 #fff, 0.7px -0.7px 0 #fff, -0.7px 0.7px 0 #fff, 0.7px 0.7px 0 #fff");
  }
  char_ele.setAttribute("x", pos.x.toString());
  char_ele.setAttribute("y", pos.y.toString());
  char_ele.setAttribute("transform", "rotate(${rot} ${pos.x} ${pos.y})");
  return char_ele;
}

// makes a svg compatible for PowerPoint
Element make_portable(Element src) {
  var src_children = src.querySelectorAll("*");
  document.body.append(src);
  for (int i = 0; i < src_children.length; ++i) {
    if (src_children[i] is svg.TextContentElement) {
      TextContentElement text_ele = src_children[i] as TextContentElement;
      if (text_ele.children.length == 1 && text_ele.children[0].tagName == "textPath") {
        continue;
      }
      List<TextContentElement> portable_eles = [];
      for (int j = 0; j < text_ele.getNumberOfChars(); ++j) {
        var char_ele = create_portable_element(text_ele, j);
        portable_eles.add(char_ele);
      }
      if (text_ele is TextPathElement) {
        // move TextPath children up and delete the TextPath
        var parent = text_ele.parent;
        var new_parent = document.createElementNS("http://www.w3.org/2000/svg", "g");
        parent.parent.append(new_parent);
        new_parent.append(text_ele);
        parent.remove();
      }
      portable_eles.forEach((v) => text_ele.parentNode.append(v));
      text_ele.remove();
    }
  }
  src.remove();
  return src;
}

SvgSvgElement get_cloned_svg_element_with_style(List<Element> selected_elts, bool separate_text) {
  var cloned_svg_element_with_style = SvgSvgElement()
    ..children = selected_elts.map(clone_and_apply_style).toList();
  if (separate_text) {
    cloned_svg_element_with_style = make_portable(cloned_svg_element_with_style);
  }

  // we can't get bbox without it being added to the DOM first
  document.body.append(cloned_svg_element_with_style);
  var bbox = cloned_svg_element_with_style.getBBox();
  cloned_svg_element_with_style.remove();

  // have to add some padding to viewbox, for some reason bbox doesn't always fit it by a few pixels??
  cloned_svg_element_with_style.setAttribute('viewBox',
      '${bbox.x.floor() - 1} ${bbox.y.floor() - 1} ${bbox.width.ceil() + 3} ${bbox.height.ceil() + 6}');

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
  var cloned_svg_element_with_style = get_cloned_svg_element_with_style(svg_elements, false);
  util.copy_svg_as_png(cloned_svg_element_with_style);
}

_export_from_element(Element svg_element, String filename_append) {
  var cloned_svg_element_with_style;
  if (filename_append != "selected") {
    cloned_svg_element_with_style = clone_and_apply_style(svg_element);
  } else {
    cloned_svg_element_with_style = svg_element;
  }
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
  // print('elt_styled ${elt_styled.id} and elt_orig ${elt_orig.id}');
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
    // print(
    // 'id ${elt_styled.id} fill ${style_def.getPropertyValue("fill")} relevant_styles ${relevant_styles[tag_name]}');
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
          // style_strings.add('display: none');
          elt_styled.style.setProperty('display', 'none');
        }
        elt_styled.style.setProperty(style_name, style_value);
        // style_strings.add('${style_name}: ${style_value};');
      }
    }
    // var style_string = style_strings.join(' ');

    // elt_styled.setAttribute("style", style_string);
    // print(elt_styled.styleMap);

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
