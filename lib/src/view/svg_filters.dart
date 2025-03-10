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

  var filter_element =
      svg.FilterElement()
        ..children = drop_shadow
        ..attributes = {
          'id': 'shadow',
          'x': '-100%',
          'y': '-100%',
          'width': '300%',
          'height': '300%',
          // 'filterUnits': 'userSpaceOnUse',

          // The above line has been commented because use of this line caused the strands outside the width x height area to disappear on 'hover'.
          // Reverting this change and the changes mentioned below from an old PR #480 (Fixes #20, add shadow filter for domains).
          // selectable_css_style_domain has been changed in src/middleware/edit_select_mode_change.dart file
          // web/scadnano-styles.css has been changed
          // .selected  ---->  .selected:not(.domain-line)

          // However, after making the above mentioned changes, the old issue of domains being highlighted with hotpink on 'hover' instead of shadow comes back. This happens because of issues in SVG Filters that cannot apply the shadow filter to a straight line. Hence, the hotpink substitute is used.
          // Because of this, hovering of doamins is slightly different in appearance (hotpink) than the other selectable elements (shadow).
        };
  // not sure why there's no setter provided for this
  //  filter_element.setAttribute('filterUnits', 'userSpaceOnUse');
  var defns = svg.DefsElement()..children = [filter_element];
  elt.children.add(defns);
}
