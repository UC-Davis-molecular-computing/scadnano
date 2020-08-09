import origami_rectangle as rect
import scadnano as sc


def create_design():
    design = rect.create(num_helices=16, num_cols=26, assign_seq=False)
    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
