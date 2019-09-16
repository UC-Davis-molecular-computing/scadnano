import origami_rectangle as rect
import scadnano as sc


def main():
    design = rect.create(num_helices=16, num_cols=26, idt=True)
    return design


# M13 in on helix 1 is (going left-to-right, which is 3'-to-5')
# GATTTTGTGAGTAGAA

# M13 in on helix 0 is (going right-to-left, which is 3'-to-5')
# CTCCGTTTTCTTATGT

# so top-left corner edge staple (going 5'-to-3', start left on helix 1, going right until crossover,
# then going right on helix 0) should be:
# CTAAAACACTCATCTT GAGGCAAAAGAATACA (staple   5'-3')
#
# GATTTTGTGAGTAGAA CTCCGTTTTCTTATGT (scaffold 3'-5')


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
    design.write_idt_file(directory='idt')
    design.write_idt_plate_excel_file(directory='idt', use_default_plates=True)
