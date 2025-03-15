import 'dart:html';

import 'package:over_react/over_react.dart';

part 'menu_number.over_react.g.dart';

UiFactory<MenuNumberProps> MenuNumber = _$MenuNumber;

mixin MenuNumberPropsMixin on UiProps {
  // required
  late String display; // what to display next to number input field (short description)
  late num default_value; // starting value to display
  late dynamic Function(num new_value) on_new_value; // what to do when value changes

  // optional
  String? input_elt_id; // customize id (otherwise default chosen based on display)

  // optional to specify, but non-nullable since they have default values
  // https://github.com/Workiva/over_react/blob/master/doc/null_safety_and_required_props.md#defaulting-props-class-components
  late num min_value; // minimum value down arrow can go to (user can still type negative values)
  late bool hide; // whether to show (good for hiding if dependent on another value)
  late String tooltip; // what to display on mouse hover (long description)
  late num step; // amount by which to step when pressing up or down arrows
}

class MenuNumberProps = UiProps with MenuNumberPropsMixin;

class MenuNumberComponent extends UiComponent2<MenuNumberProps> {
  @override
  get defaultProps =>
      (newProps()
        ..min_value = 1.0
        ..hide = false
        ..tooltip = ''
        ..step = 1.0);

  @override
  render() {
    if (props.hide) {
      return null;
    }

    var display_no_spaces = props.display.toLowerCase().replaceAll(' ', '-');
    var input_elt_id = props.input_elt_id ?? '${display_no_spaces}-number-input';

    //NOTE: this is an uncontrolled component (https://reactjs.org/docs/uncontrolled-components.html)
    // We use defaultValue instead of value, which lets the user have an empty string.
    // This makes it easier to type a number from scratch. Otherwise they cannot get rid of all digits,
    // e.g., so it's hard to change 12 to 60, because you cannot erase both the 1 and 2 digits, then type 60.
    return (Dom.span()
      ..title = props.display
      ..className = 'menu-item menu-item-number-input'
      ..style = {'display': 'block'})(
      (Dom.label()..title = props.tooltip)(
        (Dom.input()
          ..style = {'marginRight': '1em', 'width': '4em'}
          ..type = 'number'
          ..min = '${props.min_value}'
          ..step = '${props.step}'
          ..id = input_elt_id
          ..onChange = (_) {
            InputElement inputElement = document.getElementById(input_elt_id) as InputElement;
            num? new_value = num.tryParse(inputElement.value ?? '');
            if (new_value != null) {
              props.on_new_value(new_value);
            }
          }
          ..defaultValue = props.default_value)(),
        props.display,
      ),
    );
  }
}
