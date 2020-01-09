import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'dialog.g.dart';

typedef OnSubmit = void Function(List<DialogItem> items);

/// Describes form for pop-up dialog interacting with user.
abstract class Dialog with BuiltJsonSerializable implements Built<Dialog, DialogBuilder> {
  factory Dialog.from([void Function(DialogBuilder) updates]) = _$Dialog;

  Dialog._();

  static Serializer<Dialog> get serializer => _$dialogSerializer;

  factory Dialog({String title, Iterable<DialogItem> items}) {
    return Dialog.from((b) => b
      ..title = title
      ..items.replace(items));
  }

  /************************ end BuiltValue boilerplate ************************/

  String get title;

  BuiltList<DialogItem> get items;

  @nullable
  @BuiltValueField(serialize: false, compare: false)
  OnSubmit get on_submit;
}

abstract class DialogItem {
  String get label;

  dynamic get value;
}

abstract class DialogNumber
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogNumber, DialogNumberBuilder> {
  factory DialogNumber({String label, num value}) = _$DialogNumber._;

  factory DialogNumber.from([void Function(DialogNumberBuilder) updates]) = _$DialogNumber;

  DialogNumber._();

  static Serializer<DialogNumber> get serializer => _$dialogNumberSerializer;

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  num get value;
}

abstract class DialogText
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogText, DialogTextBuilder> {
  factory DialogText.from([void Function(DialogTextBuilder) updates]) = _$DialogText;

  DialogText._();

  static Serializer<DialogText> get serializer => _$dialogTextSerializer;

  factory DialogText({String label, int size = null, String value = ''}) {
    return DialogText.from((b) => b
      ..label = label
      ..size = size
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  String get value;

  @nullable
  int get size;
}

abstract class DialogTextArea
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogTextArea, DialogTextAreaBuilder> {
  factory DialogTextArea.from([void Function(DialogTextAreaBuilder) updates]) = _$DialogTextArea;

  DialogTextArea._();

  static Serializer<DialogTextArea> get serializer => _$dialogTextAreaSerializer;

  factory DialogTextArea({String label, int height, int width, String value = ''}) {
    return DialogTextArea.from((b) => b
      ..label = label
      ..height = height
      ..width = width
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  int get height;

  int get width;

  String get value;
}

abstract class DialogCheckbox
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogCheckbox, DialogCheckboxBuilder> {
  factory DialogCheckbox.from([void Function(DialogCheckboxBuilder) updates]) = _$DialogCheckbox;

  DialogCheckbox._();

  static Serializer<DialogCheckbox> get serializer => _$dialogCheckboxSerializer;

  factory DialogCheckbox({String label, bool value = false}) {
    return DialogCheckbox.from((b) => b
      ..label = label
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get value;
}
