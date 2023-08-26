import origami_rectangle as rect
import scadnano as sc


def create_design():
    # this is a very large origami (taking ~25,000 bases). It is useful for testing the performance of
    # rendering code, since at the time it was created, it is very janky to update, particularly for
    # things that edit strands such as adding a strand or adding a nick in a strand
    design = rect.create(num_helices=40, num_cols=40)
    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
