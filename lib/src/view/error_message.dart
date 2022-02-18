import 'dart:convert';
import 'dart:html';

import '../constants.dart' as constants;

class ErrorMessageComponent {
  DivElement root_element;

//  ErrorMessageStore error_message_store;

  ErrorMessageComponent(this.root_element) {
    this.root_element.attributes = {'class': 'error-message'};
//    this.error_message_store.listen((_) => this.render());
  }

  render(String error_message) {
    this.root_element.children.clear();
    if (error_message != null && error_message.length > 0) {
      if (error_message == constants.NO_DESIGN_MESSAGE_HTML) {
        // enable links in message if it is the standard "no design" message
        var no_design_message_elt =
            Element.html(constants.NO_DESIGN_MESSAGE_HTML, treeSanitizer: NodeTreeSanitizer.trusted);
        // var no_design_message_elt = Element.p();
        // no_design_message_elt.setInnerHtml(NO_DESIGN_MESSAGE_HTML);
        this.root_element.children.add(no_design_message_elt);
      } else {
        // otherwise escape to display plain text
        var pre = PreElement();
        var escaper = HtmlEscape();
        var escaped_error_message = escaper.convert(error_message);
        pre.setInnerHtml(escaped_error_message);
        this.root_element.children.add(pre);
      }
    }
  }
}
