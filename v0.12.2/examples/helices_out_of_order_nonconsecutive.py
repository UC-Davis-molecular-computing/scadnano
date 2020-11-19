import origami_rectangle as rect
import scadnano as sc


def create_design():
    helices = [
        sc.Helix(idx=2, max_offset=20),
        sc.Helix(idx=3, max_offset=20),
        sc.Helix(idx=5, max_offset=20),
        sc.Helix(idx=7, max_offset=20),
        sc.Helix(idx=11, max_offset=20),
    ]
    design = sc.Design(helices=helices, strands=[])
    # design.set_helices_view_order([5, 2, 11, 3, 7])
    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
