import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/view/react_bootstrap.dart';

part 'menu_form_file.over_react.g.dart';

UiFactory<MenuFormFileProps> MenuFormFile = _$MenuFormFile;

mixin MenuFormFileProps on UiProps {
  String id;
  String accept;
  dynamic Function(SyntheticFormEvent) onChange;
  String display;
  String keyboard_shortcut;
}

class MenuFormFileComponent extends UiComponent2<MenuFormFileProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return FormFile(
      {
        'id': props.id,
        'className': 'form-file-dropdown',
        'accept': props.accept,
        // If the user selects the same filename as last time they used the fileLoader,
        // we still want to reload the file (it may have changed).
        // But if we don't set (e.target).value to null, if the user selects the same filename,
        // then the onChange event won't fire and we won't reload the file.
        'onClick': (e) {
          document.getElementById('file-nav-dropdown').click();
          (e.target).value = null;
        },
        'onChange': props.onChange,
        'label': Dom.div()(
          props.display,
          props.keyboard_shortcut != null
              ? (Dom.span()..className = 'dropdown-item-keyboard-shortcut-span')(props.keyboard_shortcut)
              : null,
        ),
        'custom': 'false',
      },
    );
  }
}
