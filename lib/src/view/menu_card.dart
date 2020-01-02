import 'package:over_react/over_react.dart';

part 'menu_card.over_react.g.dart';

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
  Map get defaultProps => (newProps());

  @override
  Map get initialState => (newState()..show = false);

  @override
  render() {

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
