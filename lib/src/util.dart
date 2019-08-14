import 'dart:convert';
import 'dart:html';

import 'model.dart';

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
