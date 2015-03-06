#!/usr/bin/python2.7

'''
	preprocess database module: 
		Functions for interacting with the yosys tools
'''

import os;
import sys;
import re;
import time;
import datetime;
from bs4 import BeautifulSoup
import error;
import yosys;
import dataflow as dfx
import traceback
import timeit
import processRef


if len(sys.argv) != 3: 
	print "[ERROR] -- Not enough argument. Provide direction of DOT files to process";
	print "        -- ARG1: list of .v, ARG2: Name of sql database";
	exit();
	
#xmlFile= sys.argv[1];
#handler = open(xmlFile);
#xmlContent = handler.read();
#soup = BeautifulSoup(xmlContent,  'xml');
#cList = soup.DATABASE.find_all('CIRCUIT');
#for circuit in cList:
#	content = circuit.MAXSEQUENCE.string	
#	content = re.sub(r"\s+", "", content);
#	print content;

cfiles= sys.argv[1];
dbFile= sys.argv[2];

try:
	print
	print "########################################################################";
	print "[PPDB] -- Begin Circuit Database Preprocessing..."
	print "########################################################################";
	print

	soup = BeautifulSoup();
	dbtag = soup.new_tag("DATABASE");
	soup.append(dbtag)


	ID = 0;
	scriptName = "data/yoscript"
	fstream = open(cfiles);
	flines = fstream.readlines();

	for line in flines:
		start_time = timeit.default_timer();
		line= re.sub(r"\s+", "", line);
		print "--------------------------------------------------------------------------------"
		print "[PPDB] -- Extracting feature from verilog file: " + line;
		print "--------------------------------------------------------------------------------"

		val  = yosys.create_yosys_script(line, scriptName)
		top = val[1];

		rVal = yosys.execute(scriptName);
		if(rVal != ""):
			raise error.YosysError(rVal);


		ckttag = processRef.generateXML(val[0], top, soup)
		dbtag.append(ckttag)

	
		elapsed = timeit.default_timer() - start_time;
		print "ELASPED TIME: " + repr(elapsed);
		print
		
	#print soup.prettify()
	fileStream = open(dbFile, 'w');
	fileStream.write(repr(soup));
	fileStream.close();
	
	fileStream = open("data/prettify.xml", 'w');
	fileStream.write(soup.prettify());
	fileStream.close();
	
	print " -- XML File saved  : " + dbFile;
	print " -- Files processed : " + repr(ID);
	

except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print e.msg;
except error.YosysError as e:
	print "[ERROR] -- Yosys Error...";
	print "        -- " +  e.msg;
except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
finally:
	print "-----------------------------------------------------------------------"
	print "[PPDB] -- COMPLETE!";
	print 
