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
import argparse

def calculateKGram(k, verbose, compare, bex, bex1=None, containment=[], resemblance=[]):
	print "[KGRAM] -- K = " + repr(k);	
	bex.KGram2(k);

	if verbose:
		print "\ncount of lists"
		for gram, cnt in bex.kgramlist.iteritems():
			print repr(cnt) + "   " + repr(gram) + "\t\t" + repr(bex.kgramline[gram]);
		
		print "-- count of set"
		for gram, cnt in bex.kgramset.iteritems():
			print repr(cnt) + "\t" + repr(gram);

		#print "\ncount of counters"
		#for gram, cnt in bex.kgramcounter.iteritems():
		#	print repr(cnt) + "   " + repr(gram);

		print "-- SIZE LST: " + repr(len(bex.kgramlist))
		print "-- SIZE SET: " + repr(len(bex.kgramset))
		print "-- SIZE CNT: " + repr(len(bex.kgramcounter))

	if compare:
		bex1.KGram2(k);

		if verbose:
			print "\ncount of lists"
			for gram, cnt in bex1.kgramlist.iteritems():
				print repr(cnt) + "   " + repr(gram);

			print "-- count of set"
			for gram, cnt in bex1.kgramset.iteritems():
				print repr(cnt) + "   " + repr(gram);

			#print "\ncount of counters"
			#for gram, cnt in bex1.kgramcounter.iteritems():
			#	print repr(cnt) + "   " + repr(gram);

			print "-- SIZE LST: " + repr(len(bex1.kgramlist))
			print "-- SIZE SET: " + repr(len(bex1.kgramset))
			print "-- SIZE CNT: " + repr(len(bex1.kgramcounter))

		containment1= float((len(set.intersection(set(bex1.kgramlist), set(bex.kgramlist)))))/ float(len(bex1.kgramlist))
		containment2 = float((len(set.intersection(set(bex1.kgramset), set(bex.kgramset)))))/ float(len(bex1.kgramset))
		containment3= float((len(set.intersection(set(bex1.kgramcounter), set(bex.kgramcounter)))))/ float(len(bex1.kgramcounter))
		containment[0].append(containment1)
		containment[1].append(containment2)
		containment[2].append(containment3)

		resemblance1 = float((len(set.intersection(set(bex1.kgramlist), set(bex.kgramlist)))))/ float(len(set.union(set(bex1.kgramlist), set(bex.kgramlist))))
		resemblance2 = float((len(set.intersection(set(bex1.kgramset), set(bex.kgramset)))))/ float(len(set.union(set(bex1.kgramset), set(bex.kgramset))))
		resemblance3 = float((len(set.intersection(set(bex1.kgramcounter), set(bex.kgramcounter)))))/ float(len(set.union(set(bex1.kgramcounter), set(bex.kgramcounter))))
		resemblance[0].append(resemblance1)
		resemblance[1].append(resemblance2)
		resemblance[2].append(resemblance3)

		if verbose:
			print "\n"
			print "Containment LST: " + repr(containment1)
			print "Containment SET: " + repr(containment2)+ " NUM: " + repr(float((len(set.intersection(set(bex1.kgramset), set(bex.kgramset))))))+ " DEN: " +  repr(float(len(bex1.kgramset)));
			print "Containment CNT: " + repr(containment3)
			print

			print "Resemblance LST: " + repr(resemblance1)
			print "Resemblance SET: " + repr(resemblance2)
			print "Resemblance CNT: " + repr(resemblance3)
			print



def main():
	try:
		parser = argparse.ArgumentParser(description='This program reads the files in a dot file (AST) extracts a k gram from the graph');
		parser.add_argument('files',  nargs="+",  help="A dot file. Two can be given to compare K-Grams");
		parser.add_argument('-k', nargs='?', help="Size of K-Gram", type=int);
		parser.add_argument('-s', '--sweep', action='store_true',help="Sweeps the K values from 2-15");
		parser.add_argument('-v', action='store_true',  help="Verbose");
		args = parser.parse_args(sys.argv);

		files = args.files
		k = args.k
		verbose = args.v
		sweep = args.sweep

		if len(files) > 3 or len(files) < 2: 
			raise error.ArgError();
		
		dotfile = files[1];
		if(".dot" not in dotfile):
			print "[ERROR] -- Input file does not seem to be a dot file"
			raise error.GenError("");

		dotfile1="";
		if(len(files) == 3):
			dotfile1 = files[2];
			if(".dot" not in dotfile1):
				print "[ERROR] -- Input file does not seem to be a dot file"
				raise error.GenError("");

		print "[KGRAM] -- Reading in dotfile " + dotfile
		bex = BirthmarkExtractor(dotfile);
		bex.extractStructural();
		if dotfile1 != "":
			print "[KGRAM] -- Reading in dotfile " + dotfile1
			bex1 = BirthmarkExtractor(dotfile1);
			bex1.extractStructural();


		containmentL = []
		containmentS = []
		containmentC = []
		resemblanceL = []
		resemblanceS = []
		resemblanceC = []
		containment = [containmentL, containmentS, containmentC]
		resemblance = [resemblanceL, resemblanceS, resemblanceC]

		if(sweep):                           #Check if sweep is to be performed
			if dotfile1 != ""	:                
				for k in xrange(13):
					calculateKGram(k+2, verbose, True, bex, bex1, containment, resemblance)     #Sweep single dot file
			else:
				for k in xrange(13):
					calculateKGram(k+2, verbose, False, bex)     #Sweep compare dot file

		else:
			if dotfile1 != ""	:                #No sweep, single
				calculateKGram(k, verbose, True, bex, bex1, containment, resemblance)     #Sweep single dot file
			else:                              #No sweep, compare
				calculateKGram(k, verbose, False, bex)

			
		if dotfile1 != ""	:                
			print "\nRESULTS:"
			print "Containment"	
			print "K List Set Counter"
			for x in xrange(len(containment[0])):
				print repr(x+2) + " " +  repr(containment[0][x]) + " " + repr(containment[1][x]) + " " + repr(containment[2][x]);
			
			print "\nResemblance"	
			print "K List Set Counter"
			for x in xrange(len(resemblance[0])):
				print repr(x+2) +  " " +  repr(resemblance[0][x]) + " " + repr(resemblance[1][x]) + " " + repr(resemblance[2][x]);

		print "==============  COMPLETE  ================"




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
