import scadnano as sc

ROWS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
COLS = list(range(1, 13))

def create_design():
    num_strands = 208
    start = 0
    strands = []
    plate = 1
    row_idx = 0
    col_idx = 0

    for s in range(1, num_strands+1):
        ss_f = sc.Domain(helix=0, forward=True, start=start, end=start + 10)
        ss_r = sc.Domain(helix=1, forward=False, start=start, end=start + 10)

        row = ROWS[row_idx]
        col = COLS[col_idx]
        well = f'{row}{col}'
        idt = sc.IDTFields(name=f"staple{s}", plate=f'plate{plate}', well=well)

        strand = sc.Strand(domains=[ss_f, ss_r], idt=idt)
        strands.append(strand)
        row_idx += 1
        if row_idx == len(ROWS):
            row_idx = 0
            col_idx += 1
            if col_idx == len(COLS):
                col_idx = 0
                plate += 1
        start += 10

    scaffold = sc.Strand([sc.Domain(helix=0, forward=False, start=0, end=start),
                          sc.Domain(helix=1, forward=True, start=0, end=start)], is_scaffold=True)
    strands.append(scaffold)
    design = sc.Design(strands=strands, grid=sc.square)
    design.assign_m13_to_scaffold()

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
    design.write_idt_bulk_input_file(directory='idt')
    design.write_idt_plate_excel_file(directory='idt', use_default_plates=False)
