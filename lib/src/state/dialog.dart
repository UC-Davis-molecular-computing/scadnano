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

  factory Dialog(
      {String title,
      Iterable<DialogItem> items,
      Map<DialogItem, DialogCheckbox> disable_when_on = null,
      Map<DialogItem, DialogCheckbox> disable_when_off = null}) {
    if (disable_when_on == null) {
      disable_when_on = {};
    }
    if (disable_when_off == null) {
      disable_when_off = {};
    }
    return Dialog.from((b) => b
      ..title = title
      ..items.replace(items)
      ..disable_when_on.replace(disable_when_on)
      ..disable_when_off.replace(disable_when_off));
  }

  /************************ end BuiltValue boilerplate ************************/

  String get title;

  BuiltList<DialogItem> get items;

  BuiltMap<DialogItem, DialogCheckbox> get disable_when_on;

  BuiltMap<DialogItem, DialogCheckbox> get disable_when_off;

  @nullable
  @BuiltValueField(serialize: false, compare: false)
  OnSubmit get on_submit;
}

abstract class DialogItem {
  String get label;

  bool get disabled;

  dynamic get value;
}

abstract class DialogNumber
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogNumber, DialogNumberBuilder> {
  factory DialogNumber.from([void Function(DialogNumberBuilder) updates]) = _$DialogNumber;

  DialogNumber._();

  static Serializer<DialogNumber> get serializer => _$dialogNumberSerializer;

  factory DialogNumber({String label, num value, bool disabled = false}) {
    return DialogNumber.from((b) => b
      ..label = label
      ..value = value
      ..disabled = disabled);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get disabled;

  num get value;
}

abstract class DialogFloatingNumber
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogFloatingNumber, DialogFloatingNumberBuilder> {
  factory DialogFloatingNumber.from([void Function(DialogFloatingNumberBuilder) updates]) =
      _$DialogFloatingNumber;

  DialogFloatingNumber._();

  static Serializer<DialogFloatingNumber> get serializer => _$dialogFloatingNumberSerializer;

  factory DialogFloatingNumber({String label, num value, bool disabled = false}) {
    return DialogFloatingNumber.from((b) => b
      ..label = label
      ..value = value
      ..disabled = disabled);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get disabled;

  num get value;
}

abstract class DialogText
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogText, DialogTextBuilder> {
  factory DialogText.from([void Function(DialogTextBuilder) updates]) = _$DialogText;

  DialogText._();

  static Serializer<DialogText> get serializer => _$dialogTextSerializer;

  factory DialogText({String label, int size = null, String value = '', bool disabled = false}) {
    return DialogText.from((b) => b
      ..label = label
      ..size = size
      ..value = value
      ..disabled = disabled);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get disabled;

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

  factory DialogTextArea({String label, int cols, int rows, String value = '', bool disabled = false}) {
    return DialogTextArea.from((b) => b
      ..label = label
      ..cols = cols
      ..rows = rows
      ..value = value
      ..disabled = disabled);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get disabled;

  int get cols;

  int get rows;

  String get value;
}

abstract class DialogCheckbox
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogCheckbox, DialogCheckboxBuilder> {
  factory DialogCheckbox.from([void Function(DialogCheckboxBuilder) updates]) = _$DialogCheckbox;

  DialogCheckbox._();

  static Serializer<DialogCheckbox> get serializer => _$dialogCheckboxSerializer;

  factory DialogCheckbox({String label, bool value = false, bool disabled = false}) {
    return DialogCheckbox.from((b) => b
      ..label = label
      ..value = value
      ..disabled = disabled);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get disabled;

  bool get value;
}
