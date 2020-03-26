@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';

/// JS interop classes for [React Bootstrap](https://react-bootstrap.github.io/).
@JS()
class ReactBootstrap {
  external static ReactClass get Button;
  external static ReactClass get DropdownButton;
  external static ReactClass get DropdownDivider;
  external static ReactClass get DropdownItem;
  external static ReactClass get DropdownToggle;
  external static ReactClass get Navbar;
  external static ReactClass get NavbarBrand;
  external static ReactClass get NavDropdown;
  external static ReactClass get NavLink;
  external static ReactClass get Form;
  external static ReactClass get FormControl;
  external static ReactClass get FormFile;
  external static ReactClass get FormGroup;
  external static ReactClass get FormLabel;
}

final Button = ReactJsComponentFactoryProxy(ReactBootstrap.Button);
final DropdownButton = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownButton);
final DropdownDivider = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownDivider);
final DropdownItem = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownItem);
final DropdownToggle = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownToggle);
final Navbar = ReactJsComponentFactoryProxy(ReactBootstrap.Navbar);
final NavbarBrand = ReactJsComponentFactoryProxy(ReactBootstrap.NavbarBrand);
final NavDropdown = ReactJsComponentFactoryProxy(ReactBootstrap.NavDropdown);
final NavLink = ReactJsComponentFactoryProxy(ReactBootstrap.NavLink);
final Form = ReactJsComponentFactoryProxy(ReactBootstrap.Form);
final FormControl = ReactJsComponentFactoryProxy(ReactBootstrap.FormControl);
final FormFile = ReactJsComponentFactoryProxy(ReactBootstrap.FormFile);
final FormGroup = ReactJsComponentFactoryProxy(ReactBootstrap.FormGroup);
final FormLabel = ReactJsComponentFactoryProxy(ReactBootstrap.FormLabel);
