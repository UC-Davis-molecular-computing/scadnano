import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:js' as js;

import 'model.dart';
import 'constants.dart' as constants;

Future<Model> model_from_url(String url) async {
  Model model = Model.empty();
  var dna_design = await _dna_design_from_url(url);
  model.dna_design = dna_design;
  return model;
}

Future<DNADesign> _dna_design_from_url(String url) async {
  return await HttpRequest.getString(url).then((content) {
    Map<String, dynamic> parsed_json = jsonDecode(content);
    var dna_design = DNADesign.from_json(parsed_json);
    return dna_design;
  });
}

/// Transform point by panning and zooming.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<num> transform(Point<num> point, Point<num> pan, num zoom) {
  num ret_x = (point.x - pan.x) / zoom;
  num ret_y = (point.y - pan.y) / zoom;
  return Point<num>(ret_x, ret_y);
}

// taken from https://stackoverflow.com/questions/19691693/how-to-convert-javascript-object-to-dart-map
//class JsMap with MapMixin<dynamic, dynamic> implements Map<dynamic, dynamic> {
//  js.JsObject _jsObject;
//
//  JsMap.fromJsObject(this._jsObject);
//
//  @override
//  operator [](dynamic key) => _jsObject[key];
//
//  @override
//  void operator []=(dynamic key, value) {
//    _jsObject[key] = value;
//  }
//
//  @override
//  void clear() {
//    for (var key in this.keys) {
//      this.remove(key);
//    }
//  }
//
//  @override
//  // TODO: implement keys
//  Iterable<dynamic> get keys => js.context['Object'].callMethod('keys', [_jsObject]);
//
//  @override
//  remove(dynamic key) {
//    final value = this[key];
//    _jsObject.deleteProperty(key);
//    return value;
//  }
//}
//
//Map<dynamic, dynamic> js_object_to_dart(js.JsObject js_obj) {
//  return JsMap.fromJsObject(js_obj);
//}

///// Taken from https://stackoverflow.com/questions/19691693/how-to-convert-javascript-object-to-dart-map
//js_object_to_dart(thing) {
//  if (thing is js.JsArray) {
//    List list = new List();
//    js.JsArray array = thing as js.JsArray;
//    array.forEach((otherthing) {
//      list.add(js_object_to_dart(otherthing));
//    });
//    return list;
//
//  } else if (thing is js.JsObject) {
//    Map map = new Map();
//    js.JsObject obj = thing as js.JsObject;
//    Iterable keys = js.context['Object'].callMethod('keys', [obj]);
//    for (var key in keys) {
//      var val = obj[key];
//      map[key] = js_object_to_dart(val);
//    }
//    return map;
//
//  } else {
//    return thing;
//  }
//}

//// taken from https://github.com/dart-lang/sdk/issues/21311
//dynamic dartify(dynamic arg) {
//  if (arg is js.JsArray) {
//    return arg.toList();
//  }
//  if (arg is js.JsObject) {
//    // https://code.google.com/p/dart/issues/detail?id=12997
//
////    String json_str = js.context['JSON'].callMethod('stringify', [arg]);
//    String json_str = js.context['JSON'].callMethod('stringify', [arg]);
//    return jsonDecode(json_str);
//  }
//
//  return arg;
//}
////
//dynamic jsify(dynamic arg) {
//  if (arg is Map || arg is Iterable) {
//    return new js.JsObject.jsify(arg);
//  }
//  // Primitives are fine as-is. Other objects
//  // will end up as opaque in JavaScript.
//  return arg;
//}

/// This goes into "window", so in JS you can access window.editor_content, and in Brython you can do this:
/// from browser import window
/// print(window['editor_content'])
save_editor_content_to_js_context(String new_content) {
  js.context[constants.editor_content_js_key] = new_content;
}

//typedef ProcessFunction<O> = O Function(dynamic input);
//
//T identity<T>(T x) => x;
//
///// If map contains key, return associated value, otherwise return default_value.
//O with_default<O>(Map<String, dynamic> map, String key, O default_value,
//    {ProcessFunction<O> process: identity}) {
//  if (map.containsKey(key)) {
//    return process(map[key]);
//  } else {
//    return default_value;
//  }
//}
