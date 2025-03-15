import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/components.dart';
import 'package:platform_detect/platform_detect.dart';

import 'state/geometry.dart';
import 'state/grid.dart';

// WARNING: Do not modify line below, except for the version string
//          (and also add new version string to scadnano_versions_to_link).
const String CURRENT_VERSION = "0.19.5";
const String INITIAL_VERSION = "0.1.0";

// scadnano versions that we deploy so that older versions can be used.
final scadnano_older_versions_to_link = [
  "0.19.4",
  "0.18.10",
  "0.17.14",
  // "0.17.13",
  // "0.17.12",
  // "0.17.11",
  // "0.17.10",
  // "0.17.9",
  // "0.17.8",
  // "0.17.7",
  // "0.17.6",
  // "0.17.5",
  // "0.17.4",
  // // "0.17.3", // accidentally skipped this version
  // "0.17.2",
  // "0.17.1",
  // "0.17.0",
  "0.16.3",
  // "0.16.2",
  // "0.16.1",
  // "0.16.0",
  "0.15.3",
  // "0.15.2",
  // "0.15.1",
  // "0.15.0",
  "0.14.0",
  "0.13.4",
  // "0.13.3",
  // "0.13.2",
  // "0.13.1",
  // "0.13.0",
  "0.12.2",
  // "0.12.1",
];
final scadnano_versions_to_link = [CURRENT_VERSION] + scadnano_older_versions_to_link;

const BUG_REPORT_URL = 'https://github.com/UC-Davis-molecular-computing/scadnano/issues';
const NO_DESIGN_MESSAGE_HTML = r'''\
<p>scadnano is a program for designing synthetic DNA structures such as DNA origami.
scadnano is a standalone project developed and maintained by the UC Davis Molecular Computing group.
Though similar in design, it is distinct from cadnano (<a target="_blank" href="https://cadnano.org/">https://cadnano.org/</a>), 
which is developed and maintained by the <a target="_blank" href="https://bionano.ucsf.edu/">Douglas lab</a> at UCSF.

If you find scadnano useful in a scientific project, please cite its associated paper:

scadnano: A browser-based, scriptable tool for designing DNA nanostructures.
David Doty, Benjamin L Lee, and Tristan Stérin.
DNA 2020: Proceedings of the 26th International Conference on DNA Computing and Molecular Programming
[ <a target="_blank" href="https://doi.org/10.4230/LIPIcs.DNA.2020.9">paper</a> | <a target="_blank" href="https://web.cs.ucdavis.edu/~doty/papers/scadnano.bib">BibTeX</a> ]

No design is loaded.
Try loading an example by selecting <em>File&rarr;Load example</em>,
or select <em>File&rarr;Open</em> to load a .sc file from your local drive.
You can also drag and drop a .sc file from your file system to the browser.</p>''';

//FIXME:  OverReact's defaultErrorBoundaryLoggerName is 'over_react.ErrorBoundary' as of version 5.3.0,
// but if we access it directly, we get a warning
// "info: The member 'defaultErrorBoundaryLoggerName' can only be used within
// 'package:over_react/src/component/error_boundary_api.dart' or a test."
// So to avoid the warning, we hard-code the name. Honestly I don't even really know what an
// ErrorBoundary logger is, so I'm not sure if this is the right thing to do.
// const default_error_boundary_logger_name = defaultErrorBoundaryLoggerName;
const default_error_boundary_logger_name = 'over_react.ErrorBoundary';

const OXVIEW_URL = 'https://sulcgroup.github.io/oxdna-viewer/';

// https://www.w3schools.com/jsref/event_button.asp
const LEFT_CLICK_BUTTON = 0;
const MIDDLE_CLICK_BUTTON = 1;
const RIGHT_CLICK_BUTTON = 2;

const KEY_CODE_SHOW_POTENTIAL_HELIX = KeyCode.H;
const KEY_CODE_MOUSEOVER_HELIX_VIEW_INFO = KeyCode.W;
final KEY_CODE_COMMAND_MAC =
    browser.isFirefox ? 224 : 91; // Meta/Command: https://tosbourn.com/cmd-osx-key-code/
final KEY_CODE_TOGGLE_SELECT_MAC = KEY_CODE_COMMAND_MAC;
const KEY_CODE_SELECT = KeyCode.SHIFT;
const KEY_CODE_TOGGLE_SELECT = KeyCode.CTRL;
const KEY_CODE_LOOPOUT_CONVERT = KeyCode.L;

const String DNA_BASE_WILDCARD = '?';

const default_min_offset = 0;
const default_max_offset = 64;

final default_geometry = Geometry();

const scadnano_css_stylesheet_name_no_ext = r'scadnano-styles';
const scadnano_css_stylesheet_name = '${scadnano_css_stylesheet_name_no_ext}.css';

const NUM_DIGITS_PRECISION_POSITION_DISPLAYED = 1;

/// DISTANCE_BETWEEN_HELICES_SVG is set to (BASE_WIDTH_SVG * 2.5/0.332) based on the following calculation,
/// to attempt to make the DNA appear to scale in 2D drawings:
/// The width of one base pair of double-stranded DNA bp is 0.332 nm. (DNA_BASE_WIDTH_NM)
/// In a DNA origami, AFM images estimate that the average distance between adjacent double helices is 2.5 nm.
/// (HELIX_DISTANCE_NM)
/// (A DNA double-helix is only 2 nm wide, but the helices electrostatically repel each other so the spacing
/// in a DNA origami or an other DNA nanostructure with many parallel DNA helices---e.g., single-stranded tile
/// lattices---is larger than 2 nm.)
/// Thus the distance between the helices is 2.5/0.332 ~ 7.5 times the width of a single DNA base.

//const int BASE_WIDTH_SVG = 10;
//const int BASE_HEIGHT_SVG = 10;

//XXX: these are commented out to help me see which code needs to be adjusted to use DNADesign.geometry
//const double HELIX_DISTANCE_NM = 2.5;
//// https://en.wikipedia.org/wiki/Nucleic_acid_double_helix#Helix_geometries
//const double DNA_BASE_WIDTH_NM = 0.332;
//const double NM_TO_MAIN_SVG_PIXELS = (BASE_WIDTH_SVG / DNA_BASE_WIDTH_NM);
////const double DISTANCE_BETWEEN_HELICES_MAIN_SVG = (BASE_WIDTH_SVG * HELIX_DISTANCE_NM / DNA_BASE_WIDTH_NM);
//const double DISTANCE_BETWEEN_HELICES_MAIN_SVG = HELIX_DISTANCE_NM * NM_TO_MAIN_SVG_PIXELS;
//
//// unit conversion: nm * (1/0.34) base/nm * BASE_WIDTH_SVG pixels/base = pixels

const Grid default_grid = Grid.none;
//const Grid default_grid = Grid.square;

const default_modification_font_size = 12.0;
const default_strand_name_font_size = 16.0;
const default_strand_label_font_size = 16.0;
const default_domain_name_font_size = 10.0;
const default_domain_label_font_size = 10.0;
const default_major_tick_offset_font_size = 12.0;
const default_major_tick_width_font_size = 8.0;

const default_modification_connector_length = 4;

const default_scadnano_file_extension = 'sc';
const legacy_scadnano_file_extensions = ['dna', 'json'];
final all_scadnano_file_extensions = [default_scadnano_file_extension] + legacy_scadnano_file_extensions;

const default_script_file_extension = 'py';

const js_function_name_log_python_loaded = 'log_python_loaded';
const js_function_name_cache_svg = 'cache_svg';
const js_function_name_setup_svg_panzoom = 'setup_svg_panzoom';
const js_function_name_setup_splits = 'setup_splits';
const js_function_name_sdrag = 'sdrag';
const js_function_name_current_pan_main = 'current_pan_main';
const js_function_name_current_pan_side = 'current_pan_side';
const js_function_name_current_zoom_main = 'current_zoom_main';
const js_function_name_current_zoom_side = 'current_zoom_side';
const js_function_name_set_pan_side = 'set_pan_side';
const js_function_name_set_pan_main = 'set_pan_main';
const js_function_name_set_zoom_side = 'set_zoom_side';
const js_function_name_set_zoom_main = 'set_zoom_main';
const js_function_name_fit_and_center = 'fit_and_center';
const js_function_name_compile = 'compile';

const js_function_name_start_brython = 'start_brython';
const js_function_name_set_new_design_from_json = 'set_new_design_from_json';
const js_function_name_set_new_design_from_json_map = 'set_new_design_from_json_map';
const js_function_name_set_error_message_from_python_script = 'set_error_message_from_python_script';

const editor_content_js_key = 'editor_content';

const compile_button_id = 'compile';

final color_forward_rotation_arrow_no_strand = Color.rgb(0, 0, 0);
final color_reverse_rotation_arrow_no_strand = Color.rgb(0, 0, 0);

// Default color for scaffold strand(s)
final default_scaffold_color = Color.rgb(0, 102, 204);

// Default color for non-scaffold strand(s).
final default_strand_color = Color.rgb(0, 0, 0);

final default_cadnano_strand_color = Color.hex('#BFBFBF');

// NOTE: this is assuming a coordinate system where 0 degrees is straight up (negative y) in the main view,
// and rotation is clockwise
const default_roll = 0.0;
const default_pitch = 0.0;
const default_yaw = 0.0;
//const default_helix_rotation_anchor = 0;

// for extensions
const default_display_angle = 35.0;
const default_display_length = 1.5;

const default_side_pane_width_percent = 10.0;
const default_design_width_percent = 66.0;

const default_group_name = 'default_group';

/////////////////////////////////////////////////////////////
// Geometry constants

const default_rise_per_base_pair = 0.332;
const default_helix_radius = 1.0;
const default_bases_per_turn = 10.5;
const default_minor_groove_angle = 150.0;
const default_inter_helix_gap = 1.0;

/////////////////////////////////////////////////////////////
// JSON keys

// Design keys
const version_key = 'version';
const color_cycler_idx_key = 'color_cycler_idx';
const grid_key = 'grid';
const geometry_key = 'geometry';
const legacy_geometry_keys = ['parameters'];
const helices_key = 'helices';
const helices_view_order_key = 'helices_view_order';
const potential_helices_key = 'potential_helices';
const strands_key = 'strands';
const design_modifications_key =
    'modifications_in_design'; // legacy key for when we stored all mods in one map
const design_modifications_5p_key = 'modifications_5p_in_design';
const design_modifications_3p_key = 'modifications_3p_in_design';
const design_modifications_int_key = 'modifications_int_in_design';
const groups_key = 'groups';
final design_keys =
    [
      version_key,
      grid_key,
      helices_key,
      helices_view_order_key,
      potential_helices_key,
      strands_key,
      design_modifications_key,
      design_modifications_5p_key,
      design_modifications_3p_key,
      design_modifications_int_key,
      groups_key,
    ] +
    legacy_geometry_keys;

// Geometry keys
const rise_per_base_pair_key = 'rise_per_base_pair';
const legacy_rise_per_base_pair_keys = ['z_step'];
const helix_radius_key = 'helix_radius';
const bases_per_turn_key = 'bases_per_turn';
const minor_groove_angle_key = 'minor_groove_angle';
const legacy_minor_groove_angle_keys = ['groove_angle'];
const inter_helix_gap_key = 'inter_helix_gap';
final geometry_keys =
    [
      rise_per_base_pair_key,
      helix_radius_key,
      bases_per_turn_key,
      minor_groove_angle_key,
      inter_helix_gap_key,
    ] +
    legacy_minor_groove_angle_keys +
    legacy_rise_per_base_pair_keys;

// Helix keys
const idx_on_helix_key = 'idx';
const max_offset_key = 'max_offset';
const min_offset_key = 'min_offset';
const pitch_key = 'pitch';
const roll_key = 'roll';
const yaw_key = 'yaw';
const grid_position_key = 'grid_position';
const svg_position_key = 'svg_position';
const position_key = 'position';
const legacy_position_keys = ['origin']; //XXX: we aren't check for this currently
const major_ticks_key = 'major_ticks';
const major_tick_distance_key = 'major_tick_distance';
const major_tick_start_key = 'major_tick_start';
const major_tick_periodic_distances_key = 'major_tick_periodic_distances';
const group_key = 'group';
final helix_keys =
    [
      idx_on_helix_key,
      max_offset_key,
      min_offset_key,
      roll_key,
      pitch_key,
      yaw_key,
      grid_position_key,
      svg_position_key,
      position_key,
      major_ticks_key,
      major_tick_distance_key,
      major_tick_start_key,
      major_tick_periodic_distances_key,
      group_key,
    ] +
    legacy_position_keys;
// Cannot have List concatenation in const expressions.
// Seems like it won't be fixed soon (related issue):
// https://github.com/dart-lang/sdk/issues/3059
// https://github.com/dart-lang/sdk/issues/8885
// https://github.com/dart-lang/sdk/issues/18389
// https://github.com/dart-lang/sdk/issues/20574
// https://github.com/dart-lang/sdk/issues/21625

// name and label key used in Strand, Domain, and Loopout
const name_key = 'name';
const label_key = 'label';

// Strand keys
const color_key = 'color';
const dna_sequence_key = 'sequence';
const legacy_dna_sequence_keys = ['dna_sequence'];
const vendor_fields_key = 'vendor_fields';
const legacy_vendor_fields_keys = ['idt'];
const is_scaffold_key = 'is_scaffold';
const substrands_key = 'domains';
const circular_key = 'circular';
const legacy_substrands_keys = ['substrands'];
const modification_5p_key = '5prime_modification';
const modification_3p_key = '3prime_modification';
const modifications_int_key = 'internal_modifications';
final strand_keys =
    [
      color_key,
      dna_sequence_key,
      vendor_fields_key,
      is_scaffold_key,
      substrands_key,
      modification_5p_key,
      modification_3p_key,
      modifications_int_key,
      label_key,
      name_key,
    ] +
    legacy_dna_sequence_keys +
    legacy_vendor_fields_keys +
    legacy_substrands_keys;

// Modification keys
const mod_location_key = 'location';
const mod_display_text_key = 'display_text';
const mod_vendor_code_key = 'vendor_code';
const legacy_mod_vendor_code_keys = ['idt_text'];
const mod_allowed_bases_key = 'allowed_bases';
const mod_connector_length_key = 'connector_length';
final modification_keys =
    [
      mod_location_key,
      mod_display_text_key,
      mod_vendor_code_key,
      mod_allowed_bases_key,
      mod_connector_length_key,
    ] +
    legacy_mod_vendor_code_keys;

// VendorFields keys
const vendor_name_key = 'name';
const vendor_scale_key = 'scale';
const vendor_purification_key = 'purification';
const vendor_plate_key = 'plate';
const vendor_well_key = 'well';
const vendor_keys = [
  vendor_name_key,
  vendor_scale_key,
  vendor_purification_key,
  vendor_plate_key,
  vendor_well_key,
];

// Domain keys
const helix_idx_key = 'helix';
const forward_key = 'forward';
const legacy_forward_keys = ['right'];
const start_key = 'start';
const end_key = 'end';
const deletions_key = 'deletions';
const insertions_key = 'insertions';
final domain_keys =
    [
      helix_idx_key,
      forward_key,
      start_key,
      end_key,
      deletions_key,
      insertions_key,
      label_key,
      name_key,
      color_key,
    ] +
    legacy_forward_keys;

// Loopout keys
const loopout_key = 'loopout';
const loopout_keys = [loopout_key, label_key, name_key, color_key];

// Extension keys
const extension_key = 'extension_num_bases';
const is_5p_key = 'is_5p';
const display_length_key = 'display_length';
const display_angle_key = 'display_angle';
const extension_keys = [
  extension_key,
  is_5p_key,
  display_length_key,
  display_angle_key,
  label_key,
  name_key,
  color_key,
];
////////////////////////////////////////////////////
/// svg-png-caching constants

// Vertically shifts dna sequence used for caching the svg as png.
// This is needed because dna sequences on the first helix gets
// cut off at the top of the window, so they do not get rendered
// in the svg data uri.
const DNA_SEQUENCE_VERTICAL_OFFSET = 50.0;
// Horizontally shifts dna sequence used for caching the svg as png.
// This is needed because dna sequences on loopouts gets
// cut off. In the future, there may need to be a dynamic method
// for getting these offsets.
const DNA_SEQUENCE_HORIZONTAL_OFFSET = 50.0;

// Zoom threshold used for caching the svg as png.
const double ZOOM_THRESHOLD = 0.5;

/////////////////////////////////////////////////////////////
// Backend
const backend_url = 'https://scadnano-backend.onrender.com/';
const export_url = backend_url + 'scadnano_to_cadnano_v2';
const import_url = backend_url + 'cadnano_v2_to_scadnano';
const autostaple_url = backend_url + 'autostaple';
const autobreak_url = backend_url + 'autobreak';

/////////////////////////////////////////////////////////////
// CSS selector classnames

const css_selector_strand = 'strand';
const css_selector_scaffold = 'scaffold';
const css_selector_staple = 'staple';
const css_selector_domain = 'domain-line';
const css_selector_base_pair_line = 'base-pair-line';
const css_selector_base_pair_rect = 'base-pair-rect';
const css_selector_extension = 'extension-line';
const css_selector_crossover = 'crossover-curve';
const css_selector_crossover_same_helix = 'crossover-curve-same-helix';
const css_selector_loopout = 'loopout-curve';
const css_selector_end_5p_strand = 'five-prime-end-first-substrand';
const css_selector_end_3p_strand = 'three-prime-end-last-substrand';
const css_selector_end_5p_domain = 'five-prime-end';
const css_selector_end_3p_domain = 'three-prime-end';
const css_selector_end_parent_group = 'dna-ends';
const css_selector_loopout_extension_length = 'loopout-extension-length';

const css_selector_strand_name = 'strand-name';
const css_selector_strand_label = 'strand-label';
const css_selector_domain_name = 'domain-name';
const css_selector_domain_label = 'domain-label';
const css_selector_loopout_name = 'loopout-name';
const css_selector_loopout_label = 'loopout-label';
const css_selector_extension_name = 'extension-name';
const css_selector_extension_label = 'extension-label';

const css_selector_domain_moving = 'domain-line-moving';
const css_selector_disallowed = 'disallowed';

const css_selector_strand_creating = 'strand-creating';

const css_selector_helix__mouseover_invisible_rectangle = 'helix-mouseover';

// const css_selector_modification = 'modification-text';
// const css_selector_modification_group = 'modification';
const css_selector_modification = 'modification';

const css_selector_insertion = 'insertion-curve';
const css_selector_deletion = 'deletion-cross';
const css_selector_insertion_group = 'insertion-group';
const css_selector_deletion_group = 'deletion-group';
const css_selector_selected = 'selected';
const css_selector_selected_pink = 'selected-pink';

const css_selector_context_menu_item_disabled = 'context_menu_item_disabled';

const default_vendor_scale = "25nm";
const default_vendor_purification = "STD";

enum strand_bounds_status {
  helix_not_in_design,
  helix_out_of_bounds,
  min_offset_out_of_bounds,
  max_offset_out_of_bounds,
  in_bounds_with_min_offset_changes,
  in_bounds_with_max_offset_changes,
  in_bounds,
}
