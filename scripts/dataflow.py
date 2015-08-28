#!/usr/bin/python2.7

'''
	dataflow module
		Contains functions to extract a dataflow from a dot file
		Given after yosys synthesis of a verilog file
'''

import networkx as nx;
import sys, traceback;
import re;
import copy;
import error;
import timeit
import yosys;
import math
from bExtractor import BirthmarkExtractor
from collections import Counter


	
def extractDataflow(fileName, kVal):
	'''
   extractDataflow	
	   Extracts the birthmark features from the dotfile representation of circuit
		 @PARAM: fileName- Dot file of the circuit to read in
		 @RETURN: Returns the results of the birthmark extraction
	'''
	start_time = timeit.default_timer();
	# Read in dot file of the dataflow

	if(".dot" not in fileName):
		print "[ERROR] -- Input file does not seem to be a dot file"
		raise error.GenError("");
	
	bExtractor = BirthmarkExtractor(fileName);
	result = bExtractor.getBirthmark(kVal);

	elapsed = timeit.default_timer() - start_time;
	print "[DFX] -- ELAPSED: " +  repr(elapsed);
	print

	#fsd = open("data/dataflowtime.dat", "a");
	#fsd.write(repr(elapsed)+ "\n")
	#fsd.close()

	return result;



def main():
	'''
    MAIN 
		 Main function: Shows the birthmark that was extracted
	'''
	try:
		if len(sys.argv) != 3: 
			raise error.ArgError();
		
		dotfile = sys.argv[1];
		kVal = sys.argv[2];
		result = extractDataflow(dotfile, kVal);
		#print result;
		#f = open("tmpoptimizednew", 'w');
		#f.write(repr(result))

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  dataflow");
			print("  ================================================================================");
			print("    This program reads the files in a directory (dot files of circuits from YOSYS)");
			print("    It converts the graphical representation to a format that can be passed");
			print("    into gSpan such that frequent subgraphs between the set of circuits");
			print("\n  Usage: python dataflow.py [DOT FILE] [k]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print("           Usage: python dataflow.py [DOT FILE] [k]\n");





if __name__ == '__main__':
	main();
