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

if len(sys.argv) != 2: 
	print "[ERROR] -- Not enough argument. Provide a verilog file to get AST";
	print "        -- ARG1: verilog file";
	exit();


try:
	vfile= sys.argv[1];
		
	print "--------------------------------------------------------------------------------"
	print "[v2ast] -- Extracting feature from verilog file: " + vfile;
	print "--------------------------------------------------------------------------------"

	scriptName = "data/yoscript"
	val  = yosys.create_yosys_script(vfile, scriptName)
	top = val[1];

	rVal = yosys.execute(scriptName);
	if(rVal != ""):
		raise error.YosysError(rVal);
	
	print "[v2ast] -- AST File located in " + val[0] ;


except error.YosysError as e:
	print "[ERROR] -- Yosys Error...";
	print "        -- " +  e.msg;
