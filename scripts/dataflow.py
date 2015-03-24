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
from collections import Counter
import yosys;
import math
from bExtractor import BirthmarkExtractor


	





def extractDataflow(fileName):
	'''
   extractDataflow	
	   Extracts the birthmark features from the dotfile representation of circuit
		 @PARAM: fileName- Dot file of the circuit to read in
		 @RETURN: Returns the results of the birthmark extraction
	'''
	start_time = timeit.default_timer();
	# Read in dot file of the dataflow
	print "[DFX] -- Extracting structural features..."# from : " + fileName;
	if(".dot" not in fileName):
		print "[ERROR] -- Input file does not seem to be a dot file"
		exit()	
	
	bExtractor = BirthmarkExtractor(fileName);
	result = bExtractor.getBirthmark();

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
		if len(sys.argv) != 2: 
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print "        -- ARG1: dot file";
			exit();
		
		dotfile = sys.argv[1];
		result = extractDataflow(dotfile);
		print result;

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  dataflow");
			print("  ================================================================================");
			print("    This program reads the files in a directory (dot files of circuits from YOSYS)");
			print("    It converts the graphical representation to a format that can be passed");
			print("    into gSpan such that frequent subgraphs between the set of circuits");
			print("\n  Usage: python dataflow.py [DOT FILE]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print("           Usage: python dataflow.py [DOT FILE]\n");





if __name__ == '__main__':
	main();
