#!/usr/bin/python2.7

'''
	singleFlow: 
		Extracts the birthmark from a verilog file	
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
	print "[ERROR] -- Not enough argument. Provide a verilog file to process";
	print "        -- ARG1: verilog file";
	exit();



try:
	vfile= sys.argv[1];
		
	print "--------------------------------------------------------------------------------"
	print "[SFlow] -- Extracting feature from verilog file: " + vfile;
	print "--------------------------------------------------------------------------------"

	scriptName = "data/yoscript"
	val  = yosys.create_yosys_script(vfile, scriptName)
	top = val[1];

	rVal = yosys.execute(scriptName);
	if(rVal != ""):
		raise error.YosysError(rVal);


#(maxList, minList, constSet, fp) 
	result = dfx.extractDataflow(val[0]);

except error.YosysError as e:
	print "[ERROR] -- Yosys Error...";
	print "        -- " +  e.msg;
