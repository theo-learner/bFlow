#!/usr/bin/python2.7

'''
	processRef: 
	  Processes a verilog file and extracts the XML birthmark 
		for it	
'''

import os;
import sys;
import re;
import time;
import datetime;
import yosys;
import traceback;
import socket;
import dataflow as dfx
from bs4 import BeautifulSoup

def generateXML(dotfile, cktName):
	result = dfx.extractDataflow(dotfile);

#######################################################
	soup = BeautifulSoup();
	ckttag = soup.new_tag("CIRCUIT");
	ckttag['name'] = cktName;
	ckttag['id'] = -1 
	soup.append(ckttag);

	#Store the max seq
	maxList = result[0];
	for seq in maxList:
		seqtag = soup.new_tag("MAXSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
		
	minList = result[1];
	for seq in maxList:
		seqtag = soup.new_tag("MINSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
	
	constSet= result[2];
	for const in constSet:
		consttag = soup.new_tag("CONSTANT");
		consttag.string = const
		ckttag.append(consttag);
	
	fpDict= result[3];
	name = result[4];
	if(len(fpDict) != len(name)):
		raise error.SizeError("Fingerprint Dictionary and Name size do not match");

	i = 0;
	for fp in fpDict:
		fptag = soup.new_tag("FP");
		fptag['type'] = name[i];
		for k, v in fp.iteritems():
			attrTag = soup.new_tag("DATA");
			attrTag['size'] = k;
			attrTag['count'] = v;
			fptag.append(attrTag);
		i = i + 1;

		ckttag.append(fptag);
	return soup
#######################################################


def generateYosysScript(verilogFile):
	if(".v" not in verilogFile):
		print "[ERROR] -- File does not have verilog extension";
		exit();

	scriptName = "yoscript_ref"
	scriptResult = yosys.create_yosys_script(verilogFile, scriptName)
	dotfile = scriptResult[0];
	return (scriptName, dotfile);



def main():
	if len(sys.argv) != 2: 
		print "[ERROR] -- Not enough argument. Provide V File to process" 
		print "        -- ARG1: verilog file";
		exit();
	
	vfile = sys.argv[1];
	fileName = yosys.getFileData(vfile);

	#Preprocess yosys script
	(scriptName, dotfile) = generateYosysScript(vfile);
	rVal = yosys.execute(scriptName);
	soup = generateXML(dotfile, fileName[1])
	
	fileStream = open("data/" + fileName[1] + ".xml", 'w');
	fileStream.write(repr(soup));
	fileStream.close();



if __name__ == '__main__':
	main();
