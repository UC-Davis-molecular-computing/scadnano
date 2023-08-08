import 'dart:svg' as svg;

import 'package:react/react.dart';

// https://stackoverflow.com/questions/36284828/svg-adding-shadow-filter-makes-straight-line-invisible
// https://stackoverflow.com/questions/47758565/adding-fedropshadow-to-a-vertical-line-in-svg-makes-it-disappear
add_shadow_filter(svg.SvgSvgElement elt) {
  // https://stackoverflow.com/a/6094674
  var drop_shadow = [
    svg.FEGaussianBlurElement()
      ..attributes = {
//          'in': 'SourceAlpha',
        'stdDeviation': '2.5',
      },
    svg.FEMergeElement()
      ..children = [
        svg.FEMergeNodeElement(),
        svg.FEMergeNodeElement()..attributes = {'in': "SourceGraphic"},
      ],
    // debugging: visualize the filter region
//     svg.FEFloodElement()
//       ..attributes = {
//         'flood-color': '#EB0066',
//         'flood-opacity': '.2',
//       }
  ];

  var filter_element = svg.FilterElement()
    ..children = drop_shadow
    ..attributes = {
      'id': 'shadow',
      'x': '-100%',
      'y': '-100%',
      'width': '300%',
      'height': '300%',
      'filterUnits': 'userSpaceOnUse',
    };
  // not sure why there's no setter provided for this
//  filter_element.setAttribute('filterUnits', 'userSpaceOnUse');
  var defns = svg.DefsElement()..children = [filter_element];
  elt.children.add(defns);
}
