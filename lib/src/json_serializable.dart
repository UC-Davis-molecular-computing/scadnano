import 'dart:convert';

//TODO: to_json_serializable gets called very often by overReactReduxDevToolsMiddleware
// figure out a way to memoize the call (should be straightforward since objects implementing it are immutable)

abstract class JSONSerializable {
  dynamic to_json_serializable({bool suppress_indent = false});
}

class NoIndent implements JSONSerializable {
  dynamic value;

  NoIndent(this.value);

  dynamic to_json_serializable({bool suppress_indent = false}) => this.value;

//  dynamic toJson() => this.value;

  String toString() => 'NoIndent(\n  ${value}\n)';
}

String json_encode(JSONSerializable obj, [bool suppress_indent = true]) {
  var encoder = _SuppressableIndentEncoder(_Replacer(), suppress: suppress_indent);
  var serializable = obj.to_json_serializable(suppress_indent: suppress_indent);
  var json_str = encoder.convert(serializable);
  return json_str;
}

class _SuppressableIndentEncoder extends JsonEncoder {
  final String indent;
  final bool suppress;
  final _Replacer replacer;

  final JsonEncoder encoder_indent;

  _SuppressableIndentEncoder(_Replacer replacer, {String this.indent = "  ", bool this.suppress = true})
      : this.replacer = replacer,
        this.encoder_indent = JsonEncoder.withIndent(indent),
        super(replacer.default_encode);

  String convert(Object obj) {
    String result = super.convert(obj);
    for (var key in this.replacer.replacement_map.keys) {
      String val = this.replacer.replacement_map[key];

      // Dart *really* minifies its JSON; let's make it a bit more readable
      // using a cheap hack to avoid replacing those ':' that occur within a JSON string key
      val = val.replaceAll('":', '": '); // hopefully that " is the end of the previous key
      val = val.replaceAll(',', ', ');

      result = result.replaceFirst('"@@${key}@@"', val);
    }
    return result;
  }
}

class _Replacer {
  int unique_id = 0;
  final Map replacement_map = {};
  final JsonEncoder encoder_no_indent = JsonEncoder();

  dynamic default_encode(dynamic obj) {
    if (obj is NoIndent) {
      int key = this.unique_id;
      this.unique_id++;
      this.replacement_map[key] = encoder_no_indent.convert(obj.value);
      return "@@${key}@@";
    } else {
      return obj;
    }
  }
}
