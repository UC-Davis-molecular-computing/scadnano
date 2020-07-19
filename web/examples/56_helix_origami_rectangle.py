import origami_rectangle as rect
import scadnano as sc


def create_design():
    design = rect.create(num_helices=56, num_cols=8, seam_left_column=4)
    return design


if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
