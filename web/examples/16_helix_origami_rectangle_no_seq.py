import origami_rectangle as rect

def main():
    rect_num_helices = 16
    rect_num_cols = 24  # XXX: ensure num_cols is even since we divide it by 2
    rect_design = rect.create(num_helices=rect_num_helices, num_cols=rect_num_cols, assign_seq = False)
    rect_design.write_to_file("output_designs/16_helix_rectangle_no_seq.dna")

if __name__ == "__main__":
    main()
