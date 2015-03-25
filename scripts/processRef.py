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
import error;

def generateXML(dotfile, ID,  cktName, soup):
	result = dfx.extractDataflow(dotfile);

#######################################################
	ckttag = soup.new_tag("CIRCUIT");
	ckttag['name'] = cktName;
	ckttag['id'] = ID 

	#Store the max seq
	maxList = result[0];
	for seq in maxList:
		seqtag = soup.new_tag("MAXSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
		
	minList = result[1];
	for seq in minList:
		seqtag = soup.new_tag("MINSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
	
	constSet= result[2];
	for const in constSet:
		consttag = soup.new_tag("CONSTANT");
		consttag.string = const
		ckttag.append(consttag);
	
	fpDict= result[3];

	i = 0;
	for n, fp in fpDict.iteritems():		
		fptag = soup.new_tag("FP");
		fptag['type'] = n;
		for k, v in fp.iteritems():
			attrTag = soup.new_tag("DATA");
			attrTag['size'] = k;
			attrTag['count'] = v;
			fptag.append(attrTag);
		i = i + 1;

		ckttag.append(fptag);
		
	alphaList = result[5];
	for seq in alphaList:
		seqtag = soup.new_tag("ALPHASEQ");
		seqtag.string = seq 
		ckttag.append(seqtag);
	
	statstr = result[4];
	stattag = soup.new_tag("STAT");
	stattag.string = statstr;
	ckttag.append(stattag);

	return ckttag

	#return soup
#######################################################


def generateYosysScript(verilogFile):
	scriptName = "data/yoscript"
	scriptResult = yosys.create_yosys_script(verilogFile, scriptName)
	dotFiles = scriptResult[0];
	top = scriptResult[1];
	return (scriptName, dotFiles, top);



def main():
	try:
		if len(sys.argv) != 2: 
			print "[ERROR] -- Not enough argument. Provide V File to process" 
			print "        -- ARG1: verilog file";
			exit();

		
		vfile = sys.argv[1];
		fileName = yosys.getFileData(vfile);

		#Preprocess yosys script
		(scriptName, dotFiles, top) = generateYosysScript(vfile);
		rVal = yosys.execute(scriptName);
		soup = BeautifulSoup();

		ckttag = generateXML("./dot/" + top+".dot", -1, top, soup)
		soup.append(ckttag);

		
		
		fileStream = open("data/reference.xml", 'w');
		fileStream.write(repr(soup));
		fileStream.close();

	except error.YosysError as e:
		print "[ERROR] -- Yosys has encountered an error...";
		print e.msg;

	except error.GenError as e:
		print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();
