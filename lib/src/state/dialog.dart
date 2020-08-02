import 'dart:math';

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
      Iterable<Iterable<int>> mutually_exclusive_checkbox_groups = null,
      Map<int, Iterable<int>> disable_when_on = null,
      Map<int, Iterable<int>> disable_when_off = null}) {
    if (disable_when_on == null) {
      disable_when_on = {};
    }
    if (disable_when_off == null) {
      disable_when_off = {};
    }
    if (mutually_exclusive_checkbox_groups == null) {
      mutually_exclusive_checkbox_groups = [];
    }
    List<BuiltList<int>> mutually_exclusive_checkbox_groups_half_built = [
      for (var group in mutually_exclusive_checkbox_groups) BuiltList<int>(group)
    ];
    Map<int, BuiltList<int>> disable_when_on_half_built = {
      for (var idx in disable_when_on.keys) idx: BuiltList<int>(disable_when_on[idx])
    };
    Map<int, BuiltList<int>> disable_when_off_half_built = {
      for (var idx in disable_when_off.keys) idx: BuiltList<int>(disable_when_off[idx])
    };
    return Dialog.from((b) => b
      ..title = title
      ..items.replace(items)
      ..mutually_exclusive_checkbox_groups.replace(mutually_exclusive_checkbox_groups_half_built)
      ..disable_when_on.replace(disable_when_on_half_built)
      ..disable_when_off.replace(disable_when_off_half_built));
  }

  /************************ end BuiltValue boilerplate ************************/

  String get title;

  BuiltList<DialogItem> get items;

  // if i,j are both in a sublist within this list, then they must be indices of DialogCheckboxes,
  // and whenever one is switched on, the others will turn off.
  BuiltList<BuiltList<int>> get mutually_exclusive_checkbox_groups;

  // if disable_when_on[i] contains j, then
  // when DialogCheckbox at index j (starting at 0 in items) is checked,
  // the DialogItem at index i should be disabled
  BuiltMap<int, BuiltList<int>> get disable_when_on;

  // if disable_when_on[i] contains j, then
  // when DialogCheckbox at index j (starting at 0 in items) is unchecked,
  // the DialogItem at index i should be disabled
  BuiltMap<int, BuiltList<int>> get disable_when_off;

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
  factory DialogNumber.from([void Function(DialogNumberBuilder) updates]) = _$DialogNumber;

  DialogNumber._();

  static Serializer<DialogNumber> get serializer => _$dialogNumberSerializer;

  factory DialogNumber({String label, num value}) {
    return DialogNumber.from((b) => b
      ..label = label
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  num get value;
}

abstract class DialogFloatingNumber
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogFloatingNumber, DialogFloatingNumberBuilder> {
  factory DialogFloatingNumber.from([void Function(DialogFloatingNumberBuilder) updates]) =
      _$DialogFloatingNumber;

  DialogFloatingNumber._();

  static Serializer<DialogFloatingNumber> get serializer => _$dialogFloatingNumberSerializer;

  factory DialogFloatingNumber({String label, num value}) {
    return DialogFloatingNumber.from((b) => b
      ..label = label
      ..value = value);
  }

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
    if (size == null) {
      size = size_from_text(value);
    }
    return DialogText.from((b) => b
      ..label = label
      ..size = size
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  String get value;

  int get size;
}

// calculate size of text field from its length
int size_from_text(String value, {int minimum = 20}) => max(minimum, value.length);

abstract class DialogTextArea
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogTextArea, DialogTextAreaBuilder> {
  factory DialogTextArea.from([void Function(DialogTextAreaBuilder) updates]) = _$DialogTextArea;

  DialogTextArea._();

  static Serializer<DialogTextArea> get serializer => _$dialogTextAreaSerializer;

  factory DialogTextArea({String label, int cols, int rows, String value = ''}) {
    return DialogTextArea.from((b) => b
      ..label = label
      ..cols = cols
      ..rows = rows
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

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

  factory DialogCheckbox({String label, bool value = false}) {
    return DialogCheckbox.from((b) => b
      ..label = label
      ..value = value);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get value;
}

abstract class DialogSelect
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogSelect, DialogSelectBuilder> {
  factory DialogSelect.from([void Function(DialogSelectBuilder) updates]) = _$DialogSelect;

  DialogSelect._();

  static Serializer<DialogSelect> get serializer => _$dialogSelectSerializer;

  /************************ end BuiltValue boilerplate ************************/

  factory DialogSelect({String label, BuiltList<String> options, int selected_idx = 0, String value = null}) {
    return DialogSelect.from((b) => b
      ..options.replace(options)
      ..selected_idx = selected_idx
      ..label = label
      ..value = value);
  }

  BuiltList<String> get options;

  int get selected_idx;

  String get label;

  String get value;
}

abstract class DialogRadio
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogRadio, DialogRadioBuilder> {
  factory DialogRadio.from([void Function(DialogRadioBuilder) updates]) = _$DialogRadio;

  DialogRadio._();

  static Serializer<DialogRadio> get serializer => _$dialogRadioSerializer;

  /************************ end BuiltValue boilerplate ************************/

  factory DialogRadio({String label, Iterable<String> options, int selected_idx = 0}) {
    return DialogRadio.from((b) => b
      ..options.replace(options)
      ..selected_idx = selected_idx
      ..label = label);
  }

  BuiltList<String> get options;

  int get selected_idx;

  String get label;

  String get value => options[selected_idx];
}
