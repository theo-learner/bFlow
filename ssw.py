#!/usr/bin/python

import swalign;
import sys;

match = 100 ;
mismatch = -100;
gapo = -35;
gape = -5;

#scoring = swalign.NucleotideScoringMatrix(match, mismatch)
scoring = swalign.ScoringMatrix('scoreMatrix')
sw = swalign.LocalAlignment(scoring, gap_penalty = gapo, gap_extension_penalty = gape )

seq1 = sys.argv[1]; #REF
seq2 = sys.argv[2]; #QUE

alignment = sw.align(seq1, seq2);

fileStream = open(".align", 'w');
alignment.dump(fileStream)
alignment.dump()
