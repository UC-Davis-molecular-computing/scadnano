import 'dart:convert';
import 'dart:html';

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
      var pre = PreElement();
      var escaper = HtmlEscape();
      var escaped_error_message = escaper.convert(error_message);
      pre.setInnerHtml(escaped_error_message);
      this.root_element.children.add(pre);
    }
  }
}