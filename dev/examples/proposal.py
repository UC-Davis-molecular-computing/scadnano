import math
import dataclasses
import origami_rectangle as rect
import scadnano as sc
import modifications as mod


def main() -> sc.DNADesign:
    design = rect.create(num_helices=16, num_cols=28, seam_left_column=12, assign_seq=False,
                         num_flanking_columns=2, edge_staples=False,
                         scaffold_nick_offset=102)
    design.set_major_tick_distance(8)
    adjust_helix_grid_and_positions(design)
    move_top_and_bottom_staples_within_column_boundaries(design)
    add_domains_for_barrel_seam(design)
    add_twist_correct_deletions(design)
    add_angle_inducing_insertions_deletions(design)
    design.set_helices_view_order(list(reversed(range(16))))
    design.set_default_idt()

    design.assign_m13_to_scaffold()

    return design


def adjust_helix_grid_and_positions(design: sc.DNADesign):
    design.grid = sc.Grid.none
    for helix in design.helices.values():
        helix.grid_position = None
        position3d = idx_to_position(helix.idx)
        helix.position = position3d


def idx_to_position(idx: int):
    x = 0
    y = 0
    angle = 0
    for _ in range(idx):
        x += math.cos(angle) * 2.5
        y += math.sin(angle) * 2.5
        angle += 2 * math.pi / 16
    return sc.Position3D(x=x, y=y)


def add_twist_correct_deletions(design: sc.DNADesign):
    # I choose between 3 and 4 offset arbitrarily for twist-correction deletions for some reason,
    # so they have to be hard-coded.
    for col, offset in zip(range(4, 29, 3), [4, 3, 3, 4, 3, 3, 3, 3, 3]):
        for helix in range(0, 16):
            design.add_deletion(helix, 16 * col + offset)


def move_top_and_bottom_staples_within_column_boundaries(design: sc.DNADesign):
    top_staples = design.strands_starting_on_helix(0)
    bot_staples = design.strands_starting_on_helix(15)
    bot_staples.remove(design.scaffold)

    for top_staple in top_staples:
        current_end = top_staple.domains[0].end
        design.set_end(top_staple.domains[0], current_end - 8)

    for bot_staple in bot_staples:
        current_start = bot_staple.domains[0].start
        design.set_start(bot_staple.domains[0], current_start + 8)


def add_domains_for_barrel_seam(design: sc.DNADesign):
    top_staples_5p = design.strands_starting_on_helix(0)
    top_staples_3p = design.strands_ending_on_helix(0)
    bot_staples_5p = design.strands_starting_on_helix(15)
    bot_staples_3p = design.strands_ending_on_helix(15)

    # remove scaffold
    top_staples_5p = [st for st in top_staples_5p if len(st.domains) <= 3]
    top_staples_3p = [st for st in top_staples_3p if len(st.domains) <= 3]
    bot_staples_5p = [st for st in bot_staples_5p if len(st.domains) <= 3]
    bot_staples_3p = [st for st in bot_staples_3p if len(st.domains) <= 3]

    top_staples_5p.sort(key=lambda stap: stap.offset_5p())
    top_staples_3p.sort(key=lambda stap: stap.offset_3p())
    bot_staples_5p.sort(key=lambda stap: stap.offset_5p())
    bot_staples_3p.sort(key=lambda stap: stap.offset_3p())

    for top_5p, top_3p, bot_5p, bot_3p in zip(top_staples_5p, top_staples_3p, bot_staples_5p, bot_staples_3p):
        ss_top = sc.Domain(helix=0, forward=False,
                           start=top_5p.first_domain().end, end=top_3p.last_domain().start)
        ss_bot = sc.Domain(helix=15, forward=True,
                           start=bot_3p.last_domain().end, end=bot_5p.first_domain().start)
        design.insert_domain(bot_5p, 0, ss_top)
        design.insert_domain(top_5p, 0, ss_bot)


def add_angle_inducing_insertions_deletions(design: sc.DNADesign):
    # insertion followed by deletion
    start = 59
    end = start + (32 * 12)
    for helix in [1, 5, 7, 11, 13]:
        for offset in range(start, end, 32):
            design.add_insertion(helix, offset, 1)
            design.add_deletion(helix, offset + 16)

    # deletion followed by insertion
    for helix in [2, 4, 8, 10, 14]:
        for offset in range(start, end, 32):
            design.add_deletion(helix, offset)
            design.add_insertion(helix, offset + 16, 1)


beth_coords = [(47, 6), (47, 8), (47, 10), (47, 12),
               (64, 5), (64, 7),
               (79, 4), (79, 8),
               (96, 5), (96, 7),
               (175, 6), (175, 8), (175, 10), (175, 12),
               (192, 5), (192, 9), (192, 13),
               (224, 5), (224, 13),
               (256, 11),
               (271, 6), (271, 8), (271, 10), (271, 12),
               (303, 10),
               (352, 3), (352, 5), (352, 7), (352, 9), (352, 11), (352, 13), (352, 15),
               (367, 10),
               (384, 11),
               (399, 4), (399, 6), (399, 8), (399, 10)]

yim_coords = [(96, 11),
              (111, 10), (111, 4),
              (128, 9), (128, 5),
              (143, 6), (143, 8), (143, 10), (143, 12),
              (207, 14),
              (224, 3), (224, 5), (224, 7), (224, 9), (224, 13), (224, 15),
              (239, 14),
              (303, 6), (303, 8), (303, 10), (303, 12),
              (320, 13),
              (335, 14),
              (352, 7), (352, 9), (352, 11), (352, 13),
              (367, 14),
              (384, 13),
              (399, 6), (399, 8), (399, 10), (399, 12)]

will_coords = [(47, 6), (47, 8), (47, 10), (47, 12),
               (64, 5),
               (79, 4),
               (96, 5), (96, 7), (96, 9),
               (111, 4),
               (128, 5),
               (143, 6), (143, 8), (143, 10), (143, 12),
               (207, 14),
               (224, 3), (224, 5), (224, 7), (224, 9), (224, 13), (224, 15),
               (239, 14),
               (303, 6), (303, 8), (303, 10), (303, 12),
               (352, 5), (352, 7), (352, 9), (352, 11)]

you_coords = [(96, 11),
              (111, 10), (111, 4),
              (128, 9), (128, 5),
              (143, 6), (143, 8), (143, 10), (143, 12),
              (192, 5), (192, 13),
              (175, 6), (175, 8), (175, 10), (175, 12),
              (207, 4), (207, 14),
              (239, 4), (239, 14),
              (224, 3), (224, 15),
              (256, 5), (256, 13),
              (271, 12), (271, 10), (271, 8), (271, 6),
              (303, 6), (303, 8), (303, 10), (303, 12),
              (320, 5),
              (335, 4),
              (352, 3),
              (367, 4),
              (384, 5),
              (399, 4), (399, 6), (399, 8), (399, 10), (399, 12)]

marry_coords = [(47, 6), (47, 8), (47, 10), (47, 12),
                (64, 13),
                (79, 14),
                (96, 7), (96, 9), (96, 11), (96, 13),
                (111, 14),
                (128, 13),
                (143, 6), (143, 8), (143, 10), (143, 12),
                (175, 6), (175, 8), (175, 10), (175, 12),
                (192, 9), (192, 13),
                (207, 8), (207, 14),
                (224, 5), (224, 7), (224, 9), (224, 11), (224, 13),
                (256, 9), (256, 11),
                (271, 12),
                (303, 8), (303, 10), (303, 12),
                (320, 13),
                (335, 14),
                (352, 11),
                (367, 10),
                (384, 9),
                (399, 4), (399, 6), (399, 8), (399, 10), (399, 12), (399, 14)]

me_coords = [(47, 6), (47, 8), (47, 10), (47, 12),
             (64, 13),
             (79, 14),
             (96, 7), (96, 9), (96, 11), (96, 13),
             (111, 14),
             (128, 13),
             (143, 6), (143, 8), (143, 10), (143, 12),
             (175, 6), (175, 8), (175, 10), (175, 12),
             (192, 5), (192, 9), (192, 13),
             (224, 5), (224, 13),
             (320, 13),
             (335, 14),
             (352, 3), (352, 7), (352, 9), (352, 15),
             (367, 10), (367, 14),
             (384, 11), (384, 13)]

yes_coords = [(96, 11),
              (111, 10), (111, 4),
              (128, 9), (128, 5),
              (143, 6), (143, 8), (143, 10), (143, 12),
              (224, 5), (224, 7), (224, 9), (224, 11), (224, 13),
              (239, 4), (239, 10), (239, 14),
              (256, 5), (256, 13),
              (352, 5), (352, 11), (352, 13),
              (367, 4), (367, 10), (367, 14),
              (384, 5), (384, 9), (384, 13),
              (399, 6), (399, 8), (399, 12)]

coords_all = {'beth': beth_coords, 'yim': yim_coords, 'will': will_coords, 'you': you_coords,
              'marry': marry_coords, 'me': me_coords, 'yes': yes_coords}


def add_biotins(design: sc.DNADesign, word: str):
    coords_orig = coords_all[word]
    # we removed two helices from original design, so subtract 2 from helix indices
    # also the offsets are off by 24
    coords = [(offset + 24, helix - 2) for (offset, helix) in coords_orig]
    print(f'{word}:\n{coords}')
    biotin_mod_5p = dataclasses.replace(mod.biotin_5p, display_text="O")
    for staple in design.strands:
        if staple.is_scaffold: continue
        first_ss = staple.first_bound_domain()
        end_5p = first_ss.offset_5p()
        helix = first_ss.helix
        if (end_5p, helix) in coords:
            staple.set_modification_5p(biotin_mod_5p)


if not sc.in_browser() and __name__ == '__main__':
    for word in ['beth', 'yim', 'will', 'you', 'marry', 'me', 'yes']:
        the_design = main()
        add_biotins(the_design, word)

        the_design.write_scadnano_file(directory='proposal', filename=f"{word}.dna")
        the_design.write_idt_bulk_input_file(directory='proposal', filename=f"{word}.idt")
        the_design.write_idt_plate_excel_file(directory='proposal', filename=f"{word}.xls",
                                              # export_non_modified_strand_version=True,
                                              use_default_plates=True)
