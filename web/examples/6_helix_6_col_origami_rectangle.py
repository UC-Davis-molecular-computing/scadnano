import origami_rectangle as rect
import scadnano as sc


def create_design():
    design = rect.create(num_helices=6, num_cols=6, num_flanking_columns=0)
    return design


if not sc.in_browser() and __name__ == '__main__':
    # print(f'testing debug f-string: {3*4+5=}')
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
