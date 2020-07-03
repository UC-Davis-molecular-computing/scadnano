import origami_rectangle as rect
import scadnano as sc


def main():
    design = rect.create(num_helices=16, num_cols=26, assign_seq=False, twist_correction_deletion_spacing=3,
                         twist_correction_start_col=2)
    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
