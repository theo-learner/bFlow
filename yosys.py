#!/usr/bin/python2.7

'''
	yosys module: 
		Functions for interacting with the yosys tools
'''

import os;
import sys;
import re;
import time;
import datetime;
from subprocess import call
import error;

def create_yosys_script(fileName, scriptName):
	data = getFileData(fileName);
	path = data[0];
	top= data[1];
	ext= data[2];

	script = "";	
	script = script + "echo on\n";

	if(ext == 'd'):
		files = fileName +   "/files"
		with open(files) as f:
			for line in f:
				script = script + "read_verilog " + line;
	else:
		script = script + "read_verilog " + fileName;

	script = script + "\n\n";
	script = script + "hierarchy -check\n";
	script = script + "proc; opt; fsm; opt; wreduce; opt\n\n";
	script = script + "flatten "+ top +"; opt\n";
	script = script + "wreduce; opt\n\n";
	script = script + "show -width -format dot -prefix " + path + top + "_df " + top + "\n";


	fileStream = open(scriptName, 'w');
	fileStream.write(script);
	fileStream.close();

	dotFile = path+top+"_df.dot";
	return (dotFile, top);




def execute(scriptFile):
	print "[YOSYS] -- Running yosys tools..."
	cmd = "yosys -Qq -s " + scriptFile + " -l .pyosys.dmp";
	rc = call(cmd, shell=True);

	msg = ""
	hasError = False;
	with open(".pyosys.dmp") as f:
		for line in f:
			if("ERROR:" in line or hasError):
				hasError = True;
				msg = msg + line;


	if hasError:
		raise error.YosysError(msg);



def getFileData(fileName):
	data = re.search("(.+\/)*(.+)\.(.+)$", fileName);
	return (data.group(1), data.group(2), data.group(3));










