import 'model.dart';

const String INITIAL_VERSION = "0.0.1";

const String CURRENT_VERSION = "0.0.1";

const int BASE_WIDTH_SVG = 10;
const int BASE_HEIGHT_SVG = 10;

/// DISTANCE_BETWEEN_HELICES_SVG is set to (BASE_WIDTH_SVG * 2.5/0.34) based on the following calculation,
/// to attempt to make the DNA appear to scale in 2D drawings:
/// The width of one base pair of double-stranded DNA bp is 0.34 nm.
/// In a DNA origami, AFM images estimate that the average distance between adjacent double helices is 2.5 nm.
/// (A DNA double-helix is only 2 nm wide, but the helices electrostatically repel each other so the spacing
/// in a DNA origami or an other DNA nanostructure with many parallel DNA helices---e.g., single-stranded tile
/// lattices---is larger than 2 nm.)
/// Thus the distance between the helices is 2.5/0.34 ~ 7.5 times the width of a single DNA base.
final double DISTANCE_BETWEEN_HELICES_SVG = (BASE_WIDTH_SVG * 2.5 / 0.34);

const Grid default_grid = Grid.none;

const js_function_name_log_python_loaded = 'log_python_loaded';
const js_function_name_cache_svg = 'cache_svg';
const js_function_name_setup_svg_panzoom = 'setup_svg_panzoom';
const js_function_name_setup_splits = 'setup_splits';
const js_function_name_sdrag = 'sdrag';
const js_function_name_current_pan = 'current_pan';
const js_function_name_current_zoom = 'current_zoom';
const js_function_name_compile = 'compile';

const js_function_name_start_brython = 'start_brython';
const js_function_name_set_new_design_from_json = 'set_new_design_from_json';
const js_function_name_set_new_design_from_json_map = 'set_new_design_from_json_map';
const js_function_name_set_error_message_from_python_script = 'set_error_message_from_python_script';

const editor_content_js_key = 'editor_content';

const compile_button_id = 'compile';

/////////////////////////////////////////////////////////////
// JSON keys

// DNADesign keys
const version_key = 'version';
const grid_key = 'grid';
const major_tick_distance_key = 'major_tick_distance';
const major_ticks_key = 'major_ticks';
const helices_key = 'helices';
const potential_helices_key = 'potential_helices';
const strands_key = 'strands';

// Helix keys
const idx_key = 'idx';
const max_bases_key = 'max_bases';
const grid_position_key = 'grid_position';
const svg_position_key = 'svg_position';
//const position_key = 'position'; // support in the future

// Strand keys
const color_key = 'color';
const dna_sequence_key = 'dna_sequence';
const substrands_key = 'substrands';

// Substrand keys
const helix_idx_key = 'helix';
const forward_key = 'forward';
const start_key = 'start';
const end_key = 'end';
const deletions_key = 'deletions';
const insertions_key = 'insertions';

// Loopout keys
const loopout_key = 'loopout';

const initial_editor_content = """# import scadnano module
import scadnano as sc

# If running in scadnano, return define a function called main() and that returns design.
# It will be displayed in the browser by scadnano.
def main():
    # helices
    helices = [sc.Helix(0, 32), sc.Helix(1, 32)]
    
    # left staple
    stap_left_ss1 = sc.Substrand(1, sc.right, 0, 16)
    stap_left_ss0 = sc.Substrand(0, sc.left, 0, 16)
    stap_left = sc.Strand([stap_left_ss1, stap_left_ss0])
    
    # right staple
    stap_right_ss0 = sc.Substrand(0, sc.left, 16, 32)
    stap_right_ss1 = sc.Substrand(1, sc.right, 16, 32)
    stap_right = sc.Strand([stap_right_ss0, stap_right_ss1])
    
    # scaffold
    scaf_ss1_left = sc.Substrand(1, sc.left, 0, 16)
    scaf_ss1_right = sc.Substrand(1, sc.left, 16, 32)
    scaf_ss0 = sc.Substrand(0, sc.right, 0, 32)
    scaf = sc.Strand([scaf_ss1_left, scaf_ss0, scaf_ss1_right], color=sc.default_scaffold_color)
    
    # strands
    strands = [stap_left, stap_right, scaf]
    
    # whole design
    design = sc.DNADesign(helices=helices, strands=strands, grid=sc.square)
    
    # deletions and insertions added to design so they can be added to both strands on a helix
    design.add_deletion(helix_idx=0, offset=12)
    design.add_deletion(helix_idx=0, offset=24)
    design.add_deletion(helix_idx=1, offset=12)
    design.add_deletion(helix_idx=1, offset=24)
    design.add_insertion(helix_idx=0, offset=6, length=1)
    design.add_insertion(helix_idx=0, offset=18, length=2)
    design.add_insertion(helix_idx=1, offset=6, length=3)
    design.add_insertion(helix_idx=1, offset=18, length=4)
    
    # DNA assigned to whole design so complement can be assigned to strands other than scaf
    design.assign_dna(scaf, 'AACT' * 18)

    return design

# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_file(directory='output_designs')
""";