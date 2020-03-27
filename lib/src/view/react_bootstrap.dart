@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';

/// JS interop classes for [React Bootstrap](https://react-bootstrap.github.io/).
@JS()
class ReactBootstrap {
  external static ReactClass get Button;
  external static ReactClass get DropdownDivider;
  external static ReactClass get DropdownItem;
  external static ReactClass get Navbar;
  external static ReactClass get NavbarBrand;
  external static ReactClass get NavDropdown;
  external static ReactClass get FormFile;
}

final Button = ReactJsComponentFactoryProxy(ReactBootstrap.Button);
final DropdownDivider = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownDivider);
final DropdownItem = ReactJsComponentFactoryProxy(ReactBootstrap.DropdownItem);
final Navbar = ReactJsComponentFactoryProxy(ReactBootstrap.Navbar);
final NavbarBrand = ReactJsComponentFactoryProxy(ReactBootstrap.NavbarBrand);
final NavDropdown = ReactJsComponentFactoryProxy(ReactBootstrap.NavDropdown);
final FormFile = ReactJsComponentFactoryProxy(ReactBootstrap.FormFile);
