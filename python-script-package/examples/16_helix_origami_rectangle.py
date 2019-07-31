import scadnano as sc
import origami_rectangle as rect

# here's an example of using `origami_rectangle.create` to create a 6-helix rectangle
if __name__ == "__main__":
    rect_num_helices = 16
    rect_num_cols = 24  # XXX: ensure num_cols is even since we divide it by 2
    rect_design = rect.create(num_helices=rect_num_helices, num_cols=rect_num_cols, nick_pattern=rect.staggered)
    rect_design.assign_dna(sc.m13_sequence)
    rect_design.write_to_file("output_designs/16_helix_rectangle.dna")

# M13 in on helix 1 is (going left-to-right, which is 3'-to-5')
# GATTTTGTGAGTAGAA

# M13 in on helix 0 is (going right-to-left, which is 3'-to-5')
# CTCCGTTTTCTTATGT

# so top-left corner edge staple (going 5'-to-3', start left on helix 1, going right until crossover, then going right on helix 0) should be:
# CTAAAACACTCATCTT GAGGCAAAAGAATACA (staple   5'-3')
#
# GATTTTGTGAGTAGAA CTCCGTTTTCTTATGT (scaffold 3'-5')
