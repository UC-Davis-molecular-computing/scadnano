import 'dart:svg' as svg;

//TODO: on elements far to the right (and possibly up/down/left) this is causing them to disappear

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
  ];

  var defns = svg.DefsElement()
    ..children = [
      svg.FilterElement()
        ..children = drop_shadow
        ..attributes = {
          'id': 'shadow',
          'filterUnits': 'userSpaceOnUse',
          'x': '-300%',
          'y': '-300%',
          'width': '900%',
          'height': '900%',
        }
    ];
  elt.children.add(defns);
}
