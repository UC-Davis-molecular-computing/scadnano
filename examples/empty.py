import scadnano as sc

def create_design():
    return sc.Design(strands=[], grid=sc.square)

if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
