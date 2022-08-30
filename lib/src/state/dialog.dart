import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'dialog.g.dart';

typedef OnSubmit = void Function(List<DialogItem> items);

class DialogType extends EnumClass {
  const DialogType._(String name) : super(name);

  @memoized
  int get hashCode;

  static Serializer<DialogType> get serializer => _$dialogTypeSerializer;

  /******************** end BuiltValue boilerplate *********************/

  static const DialogType choose_autobreak_parameters = _$choose_autobreak_parameters;
  static const DialogType adjust_geometric_parameters = _$adjust_geometric_parameters;
  static const DialogType create_new_helix_group = _$create_new_helix_group;
  static const DialogType adjust_current_helix_group =
      _$adjust_current_helix_group;
  static const DialogType adjust_helix_indices = _$adjust_helix_indices;
  static const DialogType assign_scale_purification = _$assign_scale_purification;
  static const DialogType assign_plate_well = _$assign_plate_well;
  static const DialogType add_modification = _$add_modification;
  static const DialogType set_strand_name = _$set_strand_name;
  static const DialogType set_domain_name = _$set_domain_name;


  static BuiltSet<DialogType> get values => _$values;

  static DialogType valueOf(String name) => _$valueOf(name);

  String to_json() => name;

  static DialogType from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Dialog Type with name "${the_name}"');
  }
}

typedef ProcessCallback = Function(BuiltList<DialogItem> items);

/// Describes form for pop-up dialog interacting with user.
abstract class Dialog
    with BuiltJsonSerializable
    implements Built<Dialog, DialogBuilder> {
  factory Dialog.from([void Function(DialogBuilder) updates]) = _$Dialog;

  Dialog._();

  static Serializer<Dialog> get serializer => _$dialogSerializer;

  static BuiltList<DialogItem> identity_function(BuiltList<DialogItem> items) {
    return items;
  }

  @memoized
  int get hashCode;

  /// See comments on fields below for explanation of their meaning.
  factory Dialog(
      {String title,
      DialogType type = DialogType.create_new_helix_group,
      ProcessCallback process_saved_response = identity_function,
      Iterable<DialogItem> items,
      Iterable<Iterable<int>> mutually_exclusive_checkbox_groups = const [],
      Iterable<int> disable = const {},
      Map<int, Iterable<int>> disable_when_any_checkboxes_on = const {},
      Map<int, Map<int, Iterable<String>>>
          disable_when_any_radio_button_selected = const {},
      Map<int, Iterable<int>> disable_when_any_checkboxes_off = const {}}) {
    List<BuiltList<int>> mutually_exclusive_checkbox_groups_half_built = [
      for (var group in mutually_exclusive_checkbox_groups)
        BuiltList<int>(group)
    ];
    Map<int, BuiltList<int>> disable_when_any_checkboxes_on_half_built = {
      for (var idx in disable_when_any_checkboxes_on.keys)
        idx: BuiltList<int>(disable_when_any_checkboxes_on[idx])
    };
    Map<int, BuiltList<int>> disable_when_any_checkboxes_off_half_built = {
      for (var idx in disable_when_any_checkboxes_off.keys)
        idx: BuiltList<int>(disable_when_any_checkboxes_off[idx])
    };

    Map<int, Map<int, BuiltList<String>>>
        disable_when_any_radio_button_selected_quarter_built = {};
    for (int idx in disable_when_any_radio_button_selected.keys) {
      disable_when_any_radio_button_selected_quarter_built[idx] = {};
      for (int radio_idx in disable_when_any_radio_button_selected[idx].keys) {
        disable_when_any_radio_button_selected_quarter_built[idx][radio_idx] =
            disable_when_any_radio_button_selected[idx][radio_idx]
                .toBuiltList();
      }
    }
    ;

    Map<int, BuiltMap<int, BuiltList<String>>>
        disable_when_any_radio_button_selected_half_built = {
      for (int idx in disable_when_any_radio_button_selected_quarter_built.keys)
        idx: disable_when_any_radio_button_selected_quarter_built[idx].build()
    };

    return Dialog.from((b) => b
      ..title = title
      ..type = type
      ..process_saved_response = process_saved_response
      ..items.replace(items)
      ..disable.replace(disable)
      ..mutually_exclusive_checkbox_groups
          .replace(mutually_exclusive_checkbox_groups_half_built)
      ..disable_when_any_radio_button_selected
          .replace(disable_when_any_radio_button_selected_half_built)
      ..disable_when_any_checkboxes_on
          .replace(disable_when_any_checkboxes_on_half_built)
      ..disable_when_any_checkboxes_off
          .replace(disable_when_any_checkboxes_off_half_built));
  }

  /************************ end BuiltValue boilerplate ************************/

  String get title;

  DialogType get type;

  @nullable
  @BuiltValueField(serialize: false, compare: false)
  ProcessCallback get process_saved_response;

  BuiltList<DialogItem> get items;

  // if i,j are both in a sublist within this list, then they must be indices of DialogCheckboxes,
  // and whenever one is switched on, the others will turn off.
  BuiltList<BuiltList<int>> get mutually_exclusive_checkbox_groups;

  // if disable_when_any_radio_button_selected[i][j] == ['abc', 'def'], then
  // when DialogRadio at index j (starting at 0 in items) have either 'abc' or 'def' selected,
  // the DialogItem at index i should be disabled
  BuiltMap<int, BuiltMap<int, BuiltList<String>>>
      get disable_when_any_radio_button_selected;

  // if disable_when_any_checkboxes_on[i] == [j_1,j_2,...j_k], then
  // when DialogCheckbox at any of indices j_1,j_2,...,j_k (starting at 0 in items) are CHECKED,
  // the DialogItem at index i should be disabled
  BuiltMap<int, BuiltList<int>> get disable_when_any_checkboxes_on;

  // if disable_when_any_checkboxes_off[i] == [j_1,j_2,...j_k], then
  // when DialogCheckbox at any of indices j_1,j_2,...,j_k (starting at 0 in items) are UNCHECKED,
  // the DialogItem at index i should be disabled
  BuiltMap<int, BuiltList<int>> get disable_when_any_checkboxes_off;

  BuiltList<int> get disable;

  @nullable
  @BuiltValueField(serialize: false, compare: false)
  OnSubmit get on_submit;
}

abstract class DialogItem {
  String get label;

  dynamic get value;

  @nullable
  String get tooltip;
}

abstract class DialogInteger
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogInteger, DialogIntegerBuilder> {
  factory DialogInteger.from([void Function(DialogIntegerBuilder) updates]) =
      _$DialogInteger;

  DialogInteger._();

  static Serializer<DialogInteger> get serializer => _$dialogIntegerSerializer;

  factory DialogInteger({String label, num value, String tooltip}) {
    return DialogInteger.from((b) => b
      ..label = label
      ..value = value
      ..tooltip = tooltip);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  num get value;
}

abstract class DialogFloat
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogFloat, DialogFloatBuilder> {
  factory DialogFloat.from([void Function(DialogFloatBuilder) updates]) =
      _$DialogFloat;

  DialogFloat._();

  static Serializer<DialogFloat> get serializer => _$dialogFloatSerializer;

  factory DialogFloat({String label, num value, String tooltip}) {
    return DialogFloat.from((b) => b
      ..label = label
      ..value = value
      ..tooltip = tooltip);
  }

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  num get value;
}

abstract class DialogText
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogText, DialogTextBuilder> {
  factory DialogText.from([void Function(DialogTextBuilder) updates]) =
      _$DialogText;

  DialogText._();

  static Serializer<DialogText> get serializer => _$dialogTextSerializer;

  factory DialogText(
      {String label, int size = null, String value = '', String tooltip}) {
    if (size == null) {
      size = size_from_text(value);
    }
    return DialogText.from((b) => b
      ..label = label
      ..size = size
      ..value = value
      ..tooltip = tooltip);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  String get value;

  int get size;
}

// calculate size of text field from its length
int size_from_text(String value, {int minimum = 20}) =>
    max(minimum, value.length);

abstract class DialogTextArea
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogTextArea, DialogTextAreaBuilder> {
  factory DialogTextArea.from([void Function(DialogTextAreaBuilder) updates]) =
      _$DialogTextArea;

  DialogTextArea._();

  static Serializer<DialogTextArea> get serializer =>
      _$dialogTextAreaSerializer;

  factory DialogTextArea(
      {String label, int cols, int rows, String value = '', String tooltip}) {
    return DialogTextArea.from((b) => b
      ..label = label
      ..cols = cols
      ..rows = rows
      ..value = value
      ..tooltip = tooltip);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  int get cols;

  int get rows;

  String get value;
}

abstract class DialogCheckbox
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogCheckbox, DialogCheckboxBuilder> {
  factory DialogCheckbox.from([void Function(DialogCheckboxBuilder) updates]) =
      _$DialogCheckbox;

  DialogCheckbox._();

  static Serializer<DialogCheckbox> get serializer =>
      _$dialogCheckboxSerializer;

  factory DialogCheckbox({String label, bool value = false, String tooltip}) {
    return DialogCheckbox.from((b) => b
      ..label = label
      ..value = value
      ..tooltip = tooltip);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get label;

  bool get value;
}

abstract class DialogRadio
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogRadio, DialogRadioBuilder> {
  factory DialogRadio.from([void Function(DialogRadioBuilder) updates]) =
      _$DialogRadio;

  DialogRadio._();

  static Serializer<DialogRadio> get serializer => _$dialogRadioSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  factory DialogRadio(
      {String label,
      Iterable<String> options,
      int selected_idx = 0,
      bool radio = true,
      String tooltip}) {
    return DialogRadio.from((b) => b
      ..options.replace(options)
      ..selected_idx = selected_idx
      ..radio = radio
      ..label = label
      ..tooltip = tooltip);
  }

  BuiltList<String> get options;

  int get selected_idx;

  String get label;

  // if true, display as radio buttons, otherwise display as dropdown
  bool get radio;

  String get value => options[selected_idx];
}

abstract class DialogLink
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogLink, DialogLinkBuilder> {
  DialogLink._();

  factory DialogLink.from([void Function(DialogLinkBuilder) updates]) =
      _$DialogLink;

  static Serializer<DialogLink> get serializer => _$dialogLinkSerializer;

  @memoized
  int get hashCode;

  factory DialogLink({String label, String link, String tooltip}) {
    return DialogLink.from((b) => b
      ..label = label
      ..link = link
      ..value = ""
      ..tooltip = tooltip);
  }



  /************************ end BuiltValue boilerplate ************************/

  String get label;

  String get link;

  String get value;
}

abstract class DialogLabel
    with BuiltJsonSerializable
    implements DialogItem, Built<DialogLabel, DialogLabelBuilder> {
  DialogLabel._();

  factory DialogLabel.from([void Function(DialogLabelBuilder) updates]) = _$DialogLabel;

  static Serializer<DialogLabel> get serializer => _$dialogLabelSerializer;

  @memoized
  int get hashCode;

  factory DialogLabel({String label, String tooltip}) {
    return DialogLabel.from((b) => b
      ..label = label
      ..value = ""
      ..tooltip = tooltip);
  }


  /************************ end BuiltValue boilerplate ************************/

  String get label;

  String get value;
}

// abstract class DialogLink
//     with BuiltJsonSerializable
//     implements DialogItem, Built<DialogLink, DialogLinkBuilder> {
//   factory DialogLink.from([void Function(DialogLinkBuilder) updates]) = _$DialogLink;
//
//   DialogLink._();
//
//   static Serializer<DialogLink> get serializer => _$dialogLinkSerializer;
//
//   @memoized
//   int get hashCode;
//
//   /************************ end BuiltValue boilerplate ************************/
//
//   factory DialogLink({String label, String link}) = _$DialogLink._;
//   // {
//   //   return DialogLink.from((b) => b
//   //     ..label = label
//   //     ..link = link);
//   // }
//
//   String get label;
//
//   String get link;
//
//   String get value;
// }
