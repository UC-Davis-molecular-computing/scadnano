import 'dart:collection';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:color/color.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:redux/redux.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../state/design.dart';
import '../state/extension.dart';
import '../state/grid.dart';

import '../json_serializable.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

export_cadnano_file_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);

  AppState state = store.state;
  if (action is actions.ExportCadnanoFile) {
    _save_file_cadnano(state, action.whitespace);
  }
}

_save_file_cadnano(AppState state, bool whitespace) async {
  try {
    String default_filename = state.ui_state.loaded_filename;
    default_filename = path.setExtension(default_filename, '.json');
    var content = to_cadnano_v2_json(state.design, default_filename);
    if (!whitespace) {
      var whitespace_regex = RegExp(r'\s+');
      content = content.replaceAll(whitespace_regex, '');
    }
    util.save_file(default_filename, content);
  } on IllegalCadnanoDesignError catch (e) {
    window.alert('Error exporting file: ${e.cause}');
  }
}

/// Converts the design to the cadnano v2 format.
/// Please see the spec [`misc/cadnano-format-specs/v2.txt`](https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/main/misc/cadnano-format-specs/v2.txt)
/// for more info on that format.
String to_cadnano_v2_json(Design design, [String name = ""]) {
  var encoder = SuppressableIndentEncoder(Replacer());
  var content_serializable = to_cadnano_v2_serializable(design, name);
  return encoder.convert(content_serializable);
}

/// Converts the design to the cadnano v2 format.
/// Please see the spec [`misc/cadnano-format-specs/v2.txt`](https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/main/misc/cadnano-format-specs/v2.txt)
/// for more info on that format.
Map<String, dynamic> to_cadnano_v2_serializable(Design design, [String name = ""]) {
  Map<String, dynamic> dct = new LinkedHashMap();
  if (name != "") {
    dct['name'] = name;
  }

  dct['vstrands'] = [];

  Grid design_grid;
  // Check if helix group are used or if only one grid is used'''
  if (design.has_default_groups()) {
    design_grid = design.grid;
  } else {
    Map<Grid, dynamic> grid_used = new HashMap();
    assert(design.groups.length > 0);
    Grid grid_type = Grid.none;
    for (String group_name in design.groups.keys) {
      grid_used[design.groups[group_name]!.grid] = true;
      grid_type = design.groups[group_name]!.grid;
    }
    if (grid_used.length > 1) {
      throw new IllegalCadnanoDesignError(
          'Designs using helix groups can be exported to cadnano v2 only if all groups share the same grid type.');
    } else {
      design_grid = grid_type;
    }
  }

  // Figuring out the type of grid.
  // In cadnano v2, all helices have the same max offset
  // called `num_bases` and the type of grid is determined as follows:
  //     if num_bases % 32 == 0: then we are on grid square
  //     if num_bases % 21 == 0: then we are on grid honey
  int num_bases = 0;
  for (Helix helix in design.helices.values) {
    num_bases = max(num_bases, helix.max_offset);
  }

  if (design_grid == Grid.square) {
    num_bases = _get_multiple_of_x_sup_closest_to_y(32, num_bases);
  } else if (design_grid == Grid.honeycomb) {
    num_bases = _get_multiple_of_x_sup_closest_to_y(21, num_bases);
  } else {
    throw new IllegalCadnanoDesignError('We can export to cadnano v2 `square` and `honeycomb` grids only.');
  }

  // Figuring out if helices numbers have good parity.
  // In cadnano v2, only even helices have the scaffold go forward, only odd helices
  // have the scaffold go backward.
  for (Strand strand in design.strands) {
    for (Substrand substrand in strand.substrands) {
      if (substrand is Loopout || substrand is Extension) {
        throw new IllegalCadnanoDesignError('We cannot handle designs with Loopouts or Extensions, '
            'since they are not cadnano v2 concepts.');
      }

      bool cadnano_expected_direction;

      Domain domain = substrand as Domain;
      if (strand.is_scaffold) {
        if (domain.helix % 2 == 0) {
          cadnano_expected_direction = domain.forward;
        } else {
          cadnano_expected_direction = !domain.forward;
        }
      } else {
        if (domain.helix % 2 == 0) {
          cadnano_expected_direction = !domain.forward;
        } else {
          cadnano_expected_direction = domain.forward;
        }
      }

      if (!cadnano_expected_direction) {
        throw new IllegalCadnanoDesignError(
            'We can only convert designs where even helices have the scaffold going forward and odd helices have the scaffold going backward see the spec v2.txt Note 4. ${domain}');
      }
    }
  }

  // Filling the helices with blank.
  Map<int, int> helices_ids_reverse = _cadnano_v2_fill_blank(design, dct, num_bases, design_grid);
  // Putting the scaffold in place.
  for (Strand strand in design.strands) {
    _cadnano_v2_place_strand(strand, dct, helices_ids_reverse);
  }

  return dct;
}

int _get_multiple_of_x_sup_closest_to_y(int x, int y) {
  return y % x == 0 ? y : y + (x - y % x);
}

/// Creates blank cadnanov2 helices in and initialized all their fields.
Map<int, int> _cadnano_v2_fill_blank(
    Design design, Map<String, dynamic> dct, int num_bases, Grid design_grid) {
  Map<int, int> helices_ids_reverse = new HashMap();
  int i = 0;
  for (Helix helix in design.helices.values) {
    Map<String, dynamic> helix_dct = new LinkedHashMap();
    helix_dct['num'] = helix.idx;

    if (design_grid == Grid.square || design_grid == Grid.honeycomb) {
      assert(helix.grid_position != null);
      helix_dct['row'] = helix.grid_position!.v;
      helix_dct['col'] = helix.grid_position!.h;
    }

    helix_dct['scaf'] = [];
    helix_dct['loop'] = [];
    helix_dct['skip'] = [];
    helix_dct['stap'] = [];

    for (int _i = 0; _i < num_bases; _i++) {
      helix_dct['scaf'].add([-1, -1, -1, -1]);
      helix_dct['stap'].add([-1, -1, -1, -1]);
      helix_dct['loop'].add(0);
      helix_dct['skip'].add(0);
    }

    helix_dct['stap_colors'] = [];
    helix_dct['scafLoop'] = [];
    helix_dct['stapLoop'] = [];

    helices_ids_reverse[helix_dct['num']] = i;
    dct['vstrands'].add(helix_dct);
    i += 1;
  }
  return helices_ids_reverse;
}

/// Place a scadnano strand in cadnano v2.
void _cadnano_v2_place_strand(Strand strand, Map<String, dynamic> dct, Map<int, int> helices_ids_reverse) {
  String strand_type = 'stap';
  if (strand.is_scaffold) strand_type = 'scaf';

  for (int i = 0; i < strand.domains.length; i++) {
    Domain domain = strand.domains[i];
    if (domain is Loopout) {
      throw new IllegalCadnanoDesignError(
          'cannot convert Strand ${strand} to cadnanov2 format, since it has Loopouts');
    }

    int which_helix_id = helices_ids_reverse[domain.helix]!;
    Map<String, dynamic> which_helix = dct['vstrands'][which_helix_id];

    if (strand_type == 'stap') {
      which_helix['stap_colors'].add(_cadnano_v2_color_of_stap(strand.color, domain));
    }

    _cadnano_v2_place_strand_segment(which_helix, domain, strand_type);

    if (i != strand.domains.length - 1) {
      Domain next_domain = strand.domains[i + 1];
      if (next_domain is Loopout) {
        throw new IllegalCadnanoDesignError(
            'cannot convert Strand ${strand} to cadnanov2 format, since it has Loopouts');
      }

      int next_helix_id = helices_ids_reverse[next_domain.helix]!;
      Map<String, dynamic> next_helix = dct['vstrands'][next_helix_id];
      _cadnano_v2_place_crossover(which_helix, next_helix, domain, next_domain, strand_type);
    }
  }

  // if the strand is circular, we need to close the loop
  if (strand.circular) {
    Domain first_domain = strand.first_domain;
    Map<String, dynamic> first_helix = dct['vstrands'][first_domain.helix];
    int first_start = first_domain.start, first_end = first_domain.end;
    bool first_forward = first_domain.forward;

    Domain last_domain = strand.last_domain;
    Map<String, dynamic> last_helix = dct['vstrands'][last_domain.helix];
    int last_start = last_domain.start, last_end = last_domain.end;
    bool last_forward = last_domain.forward;

    int the_base_from = last_end - 1;
    int the_base_to = first_start;

    if (!last_forward) the_base_from = last_start;

    if (!first_forward) the_base_to = first_end - 1;

    Iterable<int> temp1 = [last_helix['num'], the_base_from];
    List temp3 = first_helix[strand_type][the_base_to] as List;
    if (temp3[0] == -1 && temp3[1] == -1) {
      temp3.setRange(0, 2, temp1);
    } else {
      temp3.setRange(2, 4, temp1);
    }

    Iterable<int> temp2 = [first_helix['num'], the_base_to];
    List temp4 = last_helix[strand_type][the_base_from];
    if (temp4[0] == -1 && temp4[1] == -1)
      temp4.setRange(0, 2, temp2);
    else
      temp4.setRange(2, 4, temp2);
  }
}

List<int> _cadnano_v2_color_of_stap(Color color, Domain domain) {
  int base_id = domain.forward ? domain.start : domain.end - 1;
  int cadnano_color = to_cadnano_v2_int_hex(color);
  return [base_id, cadnano_color];
}

int to_cadnano_v2_int_hex(Color color) {
  RgbColor rgb = color.toRgbColor();
  return 256 * 256 * rgb.r.toInt() + 256 * rgb.g.toInt() + rgb.b.toInt();
}

/// Converts a strand region with no crossover to cadnano v2.
void _cadnano_v2_place_strand_segment(Map<String, dynamic> helix_dct, Domain domain, String strand_type) {
  // Insertions and deletions
  for (int deletion in domain.deletions) {
    helix_dct['skip'][deletion] = -1;
  }
  for (Insertion insertion in domain.insertions) {
    helix_dct['loop'][insertion.offset] = insertion.length;
  }

  int start = domain.start, end = domain.end;
  bool forward = domain.forward;
  int strand_helix = helix_dct['num'];

  for (int i_base = start; i_base < end; i_base++) {
    int from_helix, from_base, to_helix, to_base;
    if (forward) {
      from_helix = strand_helix;
      from_base = i_base - 1;
      to_helix = strand_helix;
      to_base = i_base + 1;
    } else {
      from_helix = strand_helix;
      from_base = i_base + 1;
      to_helix = strand_helix;
      to_base = i_base - 1;
    }

    if (i_base == start) {
      if (forward)
        (helix_dct[strand_type][i_base] as List<int>)
            .setRange(2, (helix_dct[strand_type][i_base] as List<int>).length, [to_helix, to_base]);
      else
        (helix_dct[strand_type][i_base] as List<int>).setRange(0, 2, [from_helix, from_base]);
    } else if (i_base < end - 1) {
      helix_dct[strand_type][i_base] = [from_helix, from_base, to_helix, to_base];
    } else {
      if (forward)
        helix_dct[strand_type][i_base].setRange(0, 2, [from_helix, from_base]);
      else
        helix_dct[strand_type][i_base]
            .setRange(2, (helix_dct[strand_type][i_base] as List<int>).length, [to_helix, to_base]);
    }
  }
}

/// Converts a crossover to cadnano v2 format.
/// Returns a conversion table from ids in the structure self.helices to helices ids
/// as given by helix.idx.
void _cadnano_v2_place_crossover(Map<String, dynamic> helix_from_dct, Map<String, dynamic> helix_to_dct,
    Domain domain_from, Domain domain_to, String strand_type) {
  int helix_from = helix_from_dct['num'];
  int start_from = domain_from.start;
  int end_from = domain_from.end;
  bool forward_from = domain_from.forward;

  int helix_to = helix_to_dct['num'];
  int start_to = domain_to.start;
  int end_to = domain_to.end;
  bool forward_to = domain_to.forward;

  // Because of paranemic crossovers it is possible
  // to crossover to a strand that goes in the same direction
  // In total there are four cases corresponding to
  // [forward_from, not forward_from] x [forward_to, not forward_to]
  if (forward_from && !forward_to) {
    (helix_from_dct[strand_type][end_from - 1] as List<int>)
        .setRange(2, (helix_from_dct[strand_type][end_from - 1] as List<int>).length, [helix_to, end_to - 1]);
    (helix_to_dct[strand_type][end_to - 1] as List<int>).setRange(0, 2, [helix_from, end_from - 1]);
  } else if (!forward_from && forward_to) {
    (helix_from_dct[strand_type][start_from] as List<int>)
        .setRange(2, (helix_from_dct[strand_type][start_from] as List<int>).length, [helix_to, start_to]);
    (helix_to_dct[strand_type][start_to] as List<int>).setRange(0, 2, [helix_from, start_from]);
  } else if (forward_from && forward_to) {
    helix_from_dct[strand_type][end_from - 1]
        .setRange(2, helix_from_dct[strand_type][end_from - 1].length, [helix_to, start_to]);
    helix_to_dct[strand_type][end_to - 1].setRange(0, 2, [helix_from, start_from]);
    if (helix_from_dct['row'] % 2 != helix_to_dct['row'] % 2) {
      throw new IllegalCadnanoDesignError('''\
Paranemic crossovers are only allowed between helices that have the same parity of 
row number, here helix num ${helix_from_dct['num']} and helix num ${helix_to_dct['num']} 
have different parity of row number: respectively ${helix_from_dct['row']} and ${helix_to_dct['row']}''');
    }
  } else if (!forward_from && !forward_to) {
    helix_from_dct[strand_type][start_from]
        .setRange(2, helix_from_dct[strand_type][start_from].length, [helix_to, end_to - 1]);
    helix_to_dct[strand_type][start_to].setRange(0, 2, [helix_from, end_from - 1]);
    if (helix_from_dct['row'] % 2 != helix_to_dct['row'] % 2) {
      throw new IllegalCadnanoDesignError('''\
Paranemic crossovers are only allowed between helices that have the same parity of 
row number, here helix num ${helix_from_dct['num']} and helix num ${helix_to_dct['num']} 
have different parity of row number: respectively ${helix_from_dct['row']} and ${helix_to_dct['row']}''');
    }
  }
}
