import origami_rectangle as rect

def main():
    rect_num_helices = 6
    rect_num_cols = 12  # XXX: ensure num_cols is even since we divide it by 2
    rect_design = rect.create(num_helices=rect_num_helices, num_cols=rect_num_cols,
                              nick_pattern=rect.staggered, twist_correction_deletion_spacing=3)
    rect_design.write_to_file("output_designs/6_helix_rectangle.dna")

if __name__ == "__main__":
    main()