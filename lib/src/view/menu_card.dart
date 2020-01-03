import 'package:over_react/over_react.dart';

part 'menu_card.over_react.g.dart';

//TODO: come back to this, or just use an existing React implementation, e.g.,
// https://react-bootstrap.github.io/components/dropdowns/

@Factory()
UiFactory<MenuCardProps> MenuCard = _$MenuCard;

@Props()
class _$MenuCardProps extends UiProps {
  List<MenuItem> items;
}

@State()
class _$MenuCardState extends UiState {
  bool show;
}

@Component2()
class MenuCardComponent extends UiStatefulComponent2<MenuCardProps, MenuCardState> {
  @override
  Map get defaultProps => (newProps()..items = []);

  @override
  Map get initialState => (newState()..show = false);

  @override
  render() {
    return null;
  }
}

typedef HandleClick = void Function();

class MenuItem {
  String text;
  HandleClick handle_click;

  MenuItem(this.text, this.handle_click);
}

class BooleanMenuItem extends MenuItem {
  String text;
  bool value;
  HandleClick handle_click;

  BooleanMenuItem(this.text, this.value, this.handle_click) : super(text, handle_click);
}
