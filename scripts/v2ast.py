#!/usr/bin/python2.7

'''
	v2ast: 
		Gets the Abstract syntax tree from the verilog file
'''

import os;
import sys;
import re;
import time;
import datetime;
import error;
import yosys;
import dataflow as dfx
import traceback
import timeit


def main():
	'''
    MAIN 
		 Main function: Converts Verilog file into AST representation 
	'''

	try:
		if len(sys.argv) != 2: 
			raise error.ArgError();

		vfile= sys.argv[1];
			
		print "--------------------------------------------------------------------------------"
		print "[v2ast] -- Extracting AST from verilog file: " + vfile;
		print "--------------------------------------------------------------------------------"

		scriptName = "data/yoscript"
		val  = yosys.create_yosys_script(vfile, scriptName)
		top = val[1];

		rVal = yosys.execute(scriptName);
		if(rVal != ""):
			raise error.YosysError(rVal);
		
		print "[v2ast] -- AST File located in dot/" + val[0][0] + ".dot" ;


	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  v2ast");
			print("  ================================================================================");
			print("    This program reads a verilog file and extracts the ast from it")
			print("    AST is saved as a dot file in the dot folder");
			print("\n  Usage: python v2ast.py [Verilog FILE]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide Verilog File to process";
			print "           Usage: python v2ast.py [Verilog FILE]\n";

	except error.YosysError as e:
		print "[ERROR] -- Yosys Error...";
		print "        -- " +  e.msg;



if __name__ == '__main__':
	main();

