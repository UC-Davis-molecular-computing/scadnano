import 'dart:svg' as svg;

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
    // svg.FEFloodElement()
    //   ..attributes = {
    //     'flood-color': '#EB0066',
    //     'flood-opacity': '.2',
    //   }
  ];

  var defns = svg.DefsElement()
    ..children = [
      svg.FilterElement()
        ..children = drop_shadow
        ..attributes = {
          'id': 'shadow',
          'x': '-100%',
          'y': '-100%',
          'width': '300%',
          'height': '300%',
        }
    ];
  elt.children.add(defns);
}
