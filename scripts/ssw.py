#!/usr/bin/python

import swalign;
import sys;


if len(sys.argv) != 3: 
	print "[ERROR] -- Not enough argument. Provide two sequences to align";
	print "        -- ARG1: SEQ1, ARG2: SEQ2";
	exit();
seq1 = sys.argv[1]; #REF
seq2 = sys.argv[2]; #QUE

match = 100 ;
mismatch = -100;
gapo = -35;
gape = -5;

scoring = swalign.NucleotideScoringMatrix(match, mismatch)
#scoring = swalign.ScoringMatrix('data/scoreMatrix')
sw = swalign.LocalAlignment(scoring, gap_penalty = gapo, gap_extension_penalty = gape )


alignment = sw.align(seq1, seq2);

fileStream = open("data/align.dat", 'w');
alignment.dump(fileStream)
