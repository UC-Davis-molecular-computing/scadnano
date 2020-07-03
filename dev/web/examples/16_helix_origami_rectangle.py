import origami_rectangle as rect
import scadnano as sc


def main():
    design = rect.create(num_helices=16, num_cols=26)
    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
