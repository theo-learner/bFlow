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



try:
	if len(sys.argv) != 3: 
		raise error.ArgError()
		
	cfiles= sys.argv[1];
	dbFile= sys.argv[2];

	print
	print "########################################################################";
	print "[PPDB] -- Begin Circuit Database Preprocessing..."
	print "########################################################################";
	print

	#Initialize the XML creator
	soup = BeautifulSoup();
	dbtag = soup.new_tag("DATABASE");
	soup.append(dbtag)

	ID = 0;
	scriptName = "data/yoscript"
	fstream = open(cfiles);
	flines = fstream.readlines();

	#Go through each circuit in the circuit list
	for line in flines:
		start_time = timeit.default_timer();
		line= re.sub(r"\s+", "", line);
		print "--------------------------------------------------------------------------------"
		print "[PPDB] -- Extracting feature from verilog file: " + line;
		print "--------------------------------------------------------------------------------"

		# Processes the verilog files 
		start_yosys = timeit.default_timer();
		val  = yosys.create_yosys_script(line, scriptName)
		top = val[1];
		dotFiles = val[0];

		rVal = yosys.execute(scriptName);
		if(rVal != ""):                       #Make sure no Error occurred during synthesis
			raise error.YosysError(rVal);

		elapsed = timeit.default_timer() - start_yosys;
		print "[PPDB] -- ELAPSED: " +  repr(elapsed);
		fsy = open("data/yosystime.dat", "a");
		fsy.write(repr(elapsed)+ "\n")
		fsy.close()
		print


		#Goes through the AST extracted from yosys and gets the birthmark components
		for dotfile in dotFiles:
			print "MODULE: " + dotfile
			dotfile = "./dot/"+dotfile+".dot";
			ckttag = processRef.generateXML(dotfile, ID, top, soup)
			dbtag.append(ckttag)
			ID = ID + 1;

		elapsed = timeit.default_timer() - start_time;
		print "ELASPED TIME: " + repr(elapsed);
		fse = open("data/elapsedtime.dat", "a");
		fse.write(repr(elapsed)+ "\n")
		fse.close()
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
	print "-----------------------------------------------------------------------"
	print "[PPDB] -- COMPLETE!";
	print 
	

except error.ArgError as e:
	if len(sys.argv) == 1 :
		print("\n  preprocessDB");
		print("  ==========================================================================");
		print("    This program reads in a list of circuits in Verilog to process ");
		print("    The preprocessing extracts and stores the birthmark representation");
		print("    Results are stored in an XML file");
		print("\n  Usage: python preprocessDB.py [List of Verilog]  [Output XML]\n");
	else:
		print "[ERROR] -- Not enough argument. Provide list of circuits and a XML file ";
		print("           Usage: python preprocessDB.py [List of Verilog]  [Output XML]\n");

except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print "        -- " +  e.msg;
	
except error.GenError as e:
	print "[ERROR] -- " + e.msg;

except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
