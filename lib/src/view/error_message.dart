import 'dart:convert';
import 'dart:html';

import '../constants.dart' as constants;

const NO_DESIGN_MESSAGE_HTML = r'''<p>scadnano is a program for designing synthetic DNA structures such as DNA origami.
scadnano is a standalone project developed and maintained by the UC Davis Molecular Computing group.
Though similar in design, it is distinct from cadnano (<a target="_blank" href="https://cadnano.org/">https://cadnano.org/</a>), 
which is developed and maintained by the <a target="_blank" href="https://bionano.ucsf.edu/">Douglas lab</a> at UCSF.

If you find scadnano useful in a scientific project, please cite its associated paper:

scadnano: A browser-based, scriptable tool for designing DNA nanostructures.
David Doty, Benjamin L Lee, and Tristan Stérin.
DNA 2020: Proceedings of the 26th International Conference on DNA Computing and Molecular Programming
[ <a href="https://doi.org/10.4230/LIPIcs.DNA.2020.9">paper</a> | <a href="https://web.cs.ucdavis.edu/~doty/papers/scadnano.bib">BibTeX</a> ]

No design is loaded.
Try loading an example by selecting <em>File&rarr;Load example</em>,
or select <em>File&rarr;Open</em> to load a .sc file from your local drive.
You can also drag and drop a .sc file from your file system to the browser.</p>''';

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
      if (error_message == constants.NO_DESIGN_MESSAGE) {
        // enable links in message if it is the standard "no design" message
        var no_design_message_elt = Element.html(NO_DESIGN_MESSAGE_HTML, treeSanitizer: NodeTreeSanitizer.trusted);
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