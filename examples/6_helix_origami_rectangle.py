import origami_rectangle as rect
import scadnano as sc


def main():
    design = rect.create(num_helices=6, num_cols=10, nick_pattern=rect.staggered, twist_correction_deletion_spacing=3)
    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
