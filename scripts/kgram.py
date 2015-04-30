#!/usr/bin/python2.7

'''
	kgram: 
	  Finds a kgram  
		for it	
'''

import sys;
import yosys;
import xmlExtraction;
import networkx as nx;
import error;
from bExtractor import BirthmarkExtractor



def main():
	try:
		if len(sys.argv) > 4 or len(sys.argv) < 3: 
			raise error.ArgError();
		
		dotfile = sys.argv[1];
		dotfile1 = "";
		if len(sys.argv) == 3:
			k = int(sys.argv[2]);
		else:
			dotfile1 = sys.argv[2];
			k = int(sys.argv[3]);

		if(".dot" not in dotfile):
			print "[ERROR] -- Input file does not seem to be a dot file"
			raise error.GenError("");

		containmentL = []
		containmentS = []
		containmentC = []
		#for k in xrange(20):
		print "[KGRAM] -- K = " + repr(k);	
		print "[KGRAM] -- Extracting kgram from " + dotfile
		bex = BirthmarkExtractor(dotfile);
		bex.KGram(k);
		print "\ncount of lists"
		for gram, cnt in bex.kgramcountertuple.iteritems():
			print repr(cnt) + "   " + repr(gram);

		print "\n\ncount of set"
		for gram, cnt in bex.kgramcounter.iteritems():
			print repr(cnt) + "   " + repr(gram);

		
		print "\ncount of counters"
		for gram, cnt in bex.kgramccounter.iteritems():
			print repr(cnt) + "   " + repr(gram);

		print "SIZE LST: " + repr(len(bex.kgramcountertuple))
		print "SIZE SET: " + repr(len(bex.kgramcounter))
		print "SIZE CNT: " + repr(len(bex.kgramccounter))

		if(len(sys.argv) == 4):
			print "\n[KGRAM] -- Extracting kgram from " + dotfile1
			bex1 = BirthmarkExtractor(dotfile1);
			bex1.KGram(k);
			'''
			print "\ncount of lists"
			for gram, cnt in bex1.kgramcountertuple.iteritems():
				print repr(cnt) + "   " + repr(gram);

			print "\n\ncount of set"
			for gram, cnt in bex1.kgramcounter.iteritems():
				print repr(cnt) + "   " + repr(gram);

			
			print "\ncount of counters"
			for gram, cnt in bex1.kgramccounter.iteritems():
				print repr(cnt) + "   " + repr(gram);

			print "SIZE LST: " + repr(len(bex1.kgramcountertuple))
			print "SIZE SET: " + repr(len(bex1.kgramcounter))
			print "SIZE CNT: " + repr(len(bex1.kgramccounter))
				'''

			containment = float((len(set.intersection(set(bex1.kgramcountertuple), set(bex.kgramcountertuple)))))/ float(len(bex1.kgramcountertuple))
			containment2 = float((len(set.intersection(set(bex1.kgramcounter), set(bex.kgramcounter)))))/ float(len(bex1.kgramcounter))
			containment3 = float((len(set.intersection(set(bex1.kgramccounter), set(bex.kgramccounter)))))/ float(len(bex1.kgramccounter))

			#containment = float((len(set.intersection(set(bex1.kgramcountertuple), set(bex.kgramcountertuple)))))/ float(len(set.union(set(bex1.kgramcountertuple), set(bex.kgramcountertuple))))
			#containment2 = float((len(set.intersection(set(bex1.kgramcounter), set(bex.kgramcounter)))))/ float(len(set.union(set(bex1.kgramcounter), set(bex.kgramcounter))))
			#containment3 = float((len(set.intersection(set(bex1.kgramccounter), set(bex.kgramccounter)))))/ float(len(set.union(set(bex1.kgramccounter), set(bex.kgramccounter))))
			containmentL.append(containment)
			containmentS.append(containment2)
			containmentC.append(containment3)

			print "CONTAINMENT LST: " + repr(containment)
			print "CONTAINMENT SET: " + repr(containment2)
			print "CONTAINMENT CNT: " + repr(containment3)
			print


		for x in xrange(len(containmentL)):
			print repr(containmentL[x]) + " " + repr(containmentS[x]) + " " + repr(containmentC[x]);

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  kgram");
			print("  ================================================================================");
			print("    This program reads the files in a dot file (AST)");
			print("    extracts a k gram from the graph");
			print("\n  Usage: python kgram.py [DOT File] [k]\n");
			print("           python kgram.py [DOT File1] [DOT File2] [k]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process and a k value";
			print("           Usage: python kgram.py [DOT File] [k]\n");
			print("                  python kgram.py [DOT File1] [DOT File2] [k]\n");
	except error.GenError as e:
		print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();
