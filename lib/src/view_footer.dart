import 'dart:html';

import 'view.dart';
import 'app.dart';

class FooterViewComponent extends ReactiveComponent {

  final DivElement root_element;
  final SpanElement paragraph_element = SpanElement()..attributes = {'class': 'footer-mouse-over-paragraph'};

  FooterViewComponent(this.root_element) {
    this.root_element.children.clear();
    this.root_element.children.add(this.paragraph_element);
    this.listen(app.model.main_view_ui_model.mouse_over_data);
    this.paragraph_element.text = "";
  }

  render() {
    var mouse_over_data = app.model.main_view_ui_model.mouse_over_data.clone();
    if (mouse_over_data.has_data) {
      int idx = mouse_over_data.helix_idx;
      int offset = mouse_over_data.offset;
      this.paragraph_element.text = 'helix: ${idx}, '
          'offset: ${offset}';
      if (mouse_over_data.substrand != null) {
        int substrand_length = mouse_over_data.substrand.dna_length;
        int strand_length = mouse_over_data.substrand.strand.length;
        this.paragraph_element.text += ', '
            'strand length: ${strand_length}, '
            'substrand length: ${substrand_length}';
      }
    } else {
      this.paragraph_element.text = "";
    }
  }

}