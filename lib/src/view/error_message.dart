import 'dart:convert';
import 'package:web/web.dart';

import '../constants.dart' as constants;

class ErrorMessageComponent {
  HTMLDivElement root_element;

  ErrorMessageComponent(this.root_element) {
    this.root_element..setAttribute('class', 'error-message');
  }

  render(String? error_message) {
    this.root_element.children.clear();
    if (error_message != null && error_message.length > 0) {
      if (error_message == constants.NO_DESIGN_MESSAGE_HTML) {
        // enable links in message if it is the standard "no design" message
        var no_design_message_elt =
            Element.html(constants.NO_DESIGN_MESSAGE_HTML, treeSanitizer: NodeTreeSanitizer.trusted);
        // var no_design_message_elt = Element.p();
        // no_design_message_elt.setInnerHtml(NO_DESIGN_MESSAGE_HTML);
        this.root_element.append(no_design_message_elt);
      } else {
        // otherwise escape to display plain text
        var pre = HTMLPreElement();
        var escaper = HtmlEscape();
        var escaped_error_message = escaper.convert(error_message);
        pre.setInnerHtml(escaped_error_message);
        this.root_element.append(pre);
      }
    }
  }
}
