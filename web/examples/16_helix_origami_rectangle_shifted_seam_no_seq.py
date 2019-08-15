import origami_rectangle as rect


def main():
    rect_design = rect.create(num_helices=16, num_cols=24, assign_seq=False, seam_left_column=1)
    rect_design.write_to_file("output_designs/16_helix_rectangle_shifted_seam_no_seq.dna")


if __name__ == "__main__":
    main()
