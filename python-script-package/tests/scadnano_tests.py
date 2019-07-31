import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import scadnano as sc

import unittest


class TestIllegalStructuresPrevented(unittest.TestCase):
    def test_two_illegally_overlapping_strands(self):
        helix = sc.Helix(idx=0, max_bases=9)
        ss_bot = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=9)
        ss_top = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=9)
        strand_bot = sc.Strand(substrands=[ss_bot])
        strand_top = sc.Strand(substrands=[ss_top])
        strands = [strand_bot, strand_top]
        with self.assertRaises(sc.IllegalDNADesignError):
            sc.DNADesign(grid=sc.square, helices=[helix], strands=strands)

    def test_two_nonconsecutive_illegally_overlapping_strands(self):
        helix = sc.Helix(idx=0, max_bases=9)
        ss_top1 = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=5)
        ss_bot = sc.Substrand(helix_idx=0, direction=sc.right, start=2, end=9)
        ss_top2 = sc.Substrand(helix_idx=0, direction=sc.left, start=4, end=8)
        strand_bot = sc.Strand(substrands=[ss_bot])
        strand_top1 = sc.Strand(substrands=[ss_top1])
        strand_top2 = sc.Strand(substrands=[ss_top2])
        strands = [strand_bot, strand_top1, strand_top2]
        with self.assertRaises(sc.IllegalDNADesignError):
            sc.DNADesign(grid=sc.square, helices=[helix], strands=strands)

    def test_four_legally_leapfrogging_strands(self):
        helix = sc.Helix(idx=0, max_bases=9)
        ss_top1 = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=20)
        ss_bot1 = sc.Substrand(helix_idx=0, direction=sc.right, start=10, end=30)
        ss_top2 = sc.Substrand(helix_idx=0, direction=sc.left, start=20, end=40)
        ss_bot2 = sc.Substrand(helix_idx=0, direction=sc.right, start=30, end=50)
        strand_bot1 = sc.Strand(substrands=[ss_bot1])
        strand_bot2 = sc.Strand(substrands=[ss_bot2])
        strand_top1 = sc.Strand(substrands=[ss_top1])
        strand_top2 = sc.Strand(substrands=[ss_top2])
        strands = [strand_bot1, strand_bot2, strand_top1, strand_top2]
        sc.DNADesign(grid=sc.square, helices=[helix], strands=strands)

    def test_helices_skip_index(self):
        h1 = sc.Helix(idx=0, max_bases=9)
        h2 = sc.Helix(idx=2, max_bases=9)
        with self.assertRaises(sc.IllegalDNADesignError):
            sc.DNADesign(grid=sc.square, helices=[h1, h2], strands=[])

    def test_helices_repeat_index(self):
        h1 = sc.Helix(idx=0, max_bases=9)
        h2 = sc.Helix(idx=1, max_bases=9)
        h3 = sc.Helix(idx=0, max_bases=9)
        with self.assertRaises(sc.IllegalDNADesignError):
            sc.DNADesign(grid=sc.square, helices=[h1, h2, h3], strands=[])

    def test_strand_references_nonexistent_helix(self):
        h1 = sc.Helix(idx=0, max_bases=9)
        h2 = sc.Helix(idx=1, max_bases=9)
        ss_bot = sc.Substrand(helix_idx=2, direction=sc.left, start=0, end=9)
        ss_top = sc.Substrand(helix_idx=3, direction=sc.left, start=0, end=9)
        strand_bot = sc.Strand(substrands=[ss_bot])
        strand_top = sc.Strand(substrands=[ss_top])
        strands = [strand_bot, strand_top]
        with self.assertRaises(sc.IllegalDNADesignError):
            sc.DNADesign(grid=sc.square, helices=[h1, h2], strands=strands)


class TestAssignDNA(unittest.TestCase):

    def test_one_helix_with_one_bottom_strand_and_three_top_strands(self):
        #  012   345   678
        # -TTT> -GGG> -CCC>
        # <AAA---CCC---GGG-
        #  876   543   210
        helix = sc.Helix(idx=0, max_bases=9)
        ss_bot = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=9)
        ss_top1 = sc.Substrand(helix_idx=0, direction=sc.right, start=0, end=3)
        ss_top2 = sc.Substrand(helix_idx=0, direction=sc.right, start=3, end=6)
        ss_top3 = sc.Substrand(helix_idx=0, direction=sc.right, start=6, end=9)
        strand_bot = sc.Strand(substrands=[ss_bot])
        strand_top1 = sc.Strand(substrands=[ss_top1])
        strand_top2 = sc.Strand(substrands=[ss_top2])
        strand_top3 = sc.Strand(substrands=[ss_top3])
        strands = [strand_bot, strand_top1, strand_top2, strand_top3]
        design = sc.DNADesign(grid=sc.square, helices=[helix], strands=strands)
        design.assign_dna(strand_bot, 'AAACCCGGG')
        self.assertEqual('CCC', strand_top1.dna_sequence)
        self.assertEqual('GGG', strand_top2.dna_sequence)
        self.assertEqual('TTT', strand_top3.dna_sequence)

    def test_upper_left_edge_staple_of_16H_origami_rectangle(self):
        # staple <ACATAAGAAAACGGAG--+
        # M13   +-TGTATTCTTTTGCCTC> |
        #       |                   |
        #       +-GATTTTGTGAGTAGAA- |
        #        -CTAAAACACTCATCTT--+
        h0 = sc.Helix(idx=0, max_bases=16)
        h1 = sc.Helix(idx=1, max_bases=16)
        scaf0_ss = sc.Substrand(helix_idx=0, direction=sc.right, start=0, end=16)
        scaf1_ss = sc.Substrand(helix_idx=1, direction=sc.left, start=0, end=16)
        stap0_ss = sc.Substrand(helix_idx=0, direction=sc.left, start=0, end=16)
        stap1_ss = sc.Substrand(helix_idx=1, direction=sc.right, start=0, end=16)
        scaf = sc.Strand(substrands=[scaf1_ss,scaf0_ss])
        stap = sc.Strand(substrands=[stap1_ss,stap0_ss])
        strands = [scaf, stap]
        design = sc.DNADesign(grid=sc.square, helices=[h0,h1], strands=strands)

        seq_m13_upper_left = 'AAGATGAGTGTTTTAGTGTATTCTTTTGCCTC'
        design.assign_dna(scaf, seq_m13_upper_left)
        expected_seq_stap_upperleft = 'CTAAAACACTCATCTTGAGGCAAAAGAATACA'
        self.assertEqual(expected_seq_stap_upperleft, stap.dna_sequence)
