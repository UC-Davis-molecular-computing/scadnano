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
