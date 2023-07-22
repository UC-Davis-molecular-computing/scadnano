import 'package:over_react/over_react.dart';

part 'svg_button.over_react.g.dart';

UiFactory<SvgButtonProps> SvgButton = _$SvgButton;

mixin SvgButtonProps on UiProps {
  num x;
  num y;
  num width;
  num height;
  String text;
  dynamic Function(SyntheticMouseEvent) on_click;
  String classname;
  String id;
}

class SvgButtonComponent extends UiComponent2<SvgButtonProps> {
  @override
  render() {
    return (Dom.g()..className = '${props.classname}-group')(
      (Dom.rect()
        ..x = '${props.x}'
        ..y = '${props.y}'
        ..width = '${props.width}'
        ..height = '${props.height}'
        ..id = props.id
        ..onClick = props.on_click
        ..className = '${props.classname}-rect'
        ..key = '${props.classname}-rect')(),
      (Dom.text()
        ..x = '${props.x + props.width / 2}'
        ..y = '${props.y + props.height / 2}'
        ..className = '${props.classname}-text'
        ..key = '${props.classname}-text')(props.text),
    );
  }
}
