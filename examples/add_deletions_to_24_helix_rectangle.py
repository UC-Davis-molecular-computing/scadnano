import scadnano as sc


def create_design():
    design = sc.Design.from_scadnano_file(f'24_helix_rectangle.{sc.default_scadnano_file_extension}')
    for helix in range(24):
        for offset in range(27, 294, 48):
            design.add_deletion(helix, offset)
    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(
        filename=f'24_helix_rectangle_twist_corrected.{sc.default_scadnano_file_extension}')
