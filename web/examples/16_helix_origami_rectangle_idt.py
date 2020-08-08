import origami_rectangle as rect
import scadnano as sc


def create_design():
    design = rect.create(num_helices=16, num_cols=26, use_idt_defaults=True)
    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
    design.write_idt_bulk_input_file(directory='idt')
    design.write_idt_plate_excel_file(directory='idt', filename='16_helix_origami_rectangle_96well.xls',
                                      use_default_plates=True, plate_type=sc.PlateType.wells96)
    design.write_idt_plate_excel_file(directory='idt', filename='16_helix_origami_rectangle_384well.xls',
                                      use_default_plates=True, plate_type=sc.PlateType.wells384)
