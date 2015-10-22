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
import error, errno;
import yosys;
import dataflow as dfx
import traceback
import timeit
import xmlExtraction
import argparse



def removeFile(filename):
	'''
		removeFile:
		   Removes a file if it exists. 
			 PARAM: filename:  File to remove
	'''
	try:
		os.remove(filename)
	except OSError as e:
		if e.errno != errno.ENOENT: #If te error is not a no file found, raise exception again
			raise





try:
	#Parse command arguments
	parser = argparse.ArgumentParser();
	parser.add_argument("db", help="File containing list of circuits in the database");
	parser.add_argument("output", help="File of the processed circuits (XML)");
	parser.add_argument("k", help="Value of K-gram");
	parser.add_argument("-O", "--optimize", help="Turns on optimizations when processing the circuits", action="store_true");
	parser.add_argument("-s", "--strict", help="Adds additional contraints to make the search more strict", action="store_true");
	parser.add_argument("-l", "--hierarchy", help="Extracts hierarchical information (WIP)", action="store_true");
	parser.add_argument("-p", "--prettify", help="Saves a prettified XML version of the database in data/", action="store_true");
	start_all = timeit.default_timer();

	arguments = parser.parse_args()
	
	optFlag= 0
	hierFlag= False
	if(arguments.optimize):
		optFlag= 3;            #Full optimization
	if(arguments.hierarchy):
		hierFlag= True;

		
	strictFlag = arguments.strict;
	cfiles = arguments.db;
	dbFile = arguments.output;
	kVal = arguments.k;

	print
	print "########################################################################";
	print "[*] -- Begin Circuit Database Preprocessing..."
	print "########################################################################";
	print

	print "Cleaning old files..."
	removeFile("data/statcell.dat")
	removeFile("data/statwire.dat")
	removeFile("data/yosystime.dat")
	removeFile("data/elapsedtime.dat")
	removeFile("data/kgramExtractionTime.csv")

	#Initialize the XML creator
	soup = BeautifulSoup();
	dbtag = soup.new_tag("DATABASE");
	dbtag["K"] = kVal
	soup.append(dbtag)

	ID = 0;
	scriptName = "data/yoscript"
	fstream = open(cfiles);
	flines = fstream.readlines();

	#Go through each circuit in the circuit list
	processedTop = set();
	multipleTop= set();
	for line in flines:
		start_time = timeit.default_timer();
		line= re.sub(r"\s+", "", line);
		print "========================================================================="
		print "[*] -- Extracting feature from verilog file: " + line;
		print "========================================================================="

		# Processes the verilog files 
		print "--------------------------------------------------------------"
		print "[*] -- Synthesizing circuit design..."
		print "--------------------------------------------------------------"
		start_yosys = timeit.default_timer();
		val  = yosys.create_yosys_script(line, scriptName, hier=hierFlag, opt=optFlag)


		rVal = yosys.execute(scriptName);

		if(rVal != ""):                       #Make sure no Error occurred during synthesis
			if(("show") in  rVal):
				print "[WARNING] -- Show error encountered..."
				print "          -- Performing Yosys Synthesis without optimizations..."
				start_yosys = timeit.default_timer();
				val  = yosys.create_yosys_script(line, scriptName, hier=hierFlag, opt=optFlag-1)

				rVal = yosys.execute(scriptName);

				if(rVal != ""):                       #Make sure no Error occurred during synthesis
					raise error.YosysError(rVal);
			else:
				raise error.YosysError(rVal);
		
		vfile = val[2];
		top = val[1];
		dotFiles = val[0];

		elapsed = timeit.default_timer() - start_yosys;
		#print "[TIME] -- Synthesis: " +  repr(elapsed);
		fsy = open("data/yosystime.dat", "a");
		fsy.write(repr(elapsed)+ "\n")
		fsy.close()


		print "\n\n--------------------------------------------------------------"
		print "[*] -- Extracting birthmark from AST..."
		print "--------------------------------------------------------------"
		start_time= timeit.default_timer();
		if hierFlag:
			#Goes through the AST extracted from yosys and gets the birthmark components
			for dotfile in dotFiles:
				print "MODULE: " + dotfile
				if dotfile in processedTop:
					print "[WARNING] -- Module " + dotfile + " already exists...skipping...";
					multipleTop.add(dotfile);

				processedTop.add(dotfile);
				dotfilename = "./dot/"+dotfile+".dot";
				ckttag = xmlExtraction.generateXML(dotfilename, soup, kVal, strict=strictFlag)
				ckttag['name'] = dotfile;
				ckttag['file'] = vfile;
				ckttag['id'] = ID 

				dbtag.append(ckttag)
				ID = ID + 1;
		else:
			dotfilename = "./dot/"+dotFiles[0]+".dot";
			ckttag = xmlExtraction.generateXML(dotfilename, soup, kVal, strict=strictFlag)
			ckttag['name'] = dotFiles[0];
			ckttag['file'] = vfile;
			ckttag['id'] = ID 
			dbtag.append(ckttag)
			ID = ID + 1;

		elapsed = timeit.default_timer() - start_time;
		print "[TIME]-- Birthmark Extraction: " + repr(elapsed);
		fse = open("data/elapsedtime.dat", "a");
		fse.write(repr(elapsed)+ "\n")
		fse.close()
		print
		
	#print soup.prettify()
	print ("[*] -- All circuits processed!")
	print ("[*] -- Saving database...\n")
	fileStream = open(dbFile, 'w');
	fileStream.write(repr(soup));
	fileStream.close();
	
	if(arguments.prettify):
		fileStream = open("data/prettify.xml", 'w');
		fileStream.write(soup.prettify());
		fileStream.close();
	
	print " -- K Gram Value:     " + kVal;
	print " -- Hierarchy:        " + repr(hierFlag);
	print " -- Optimization:     " + repr(optFlag);
	print " -- XML File saved  : " + dbFile;
	print " -- Files processed : " + repr(ID);
	if(len(multipleTop) > 0):
		print " -- Multiple modules found:"
		for top in multipleTop:
			print "   * " + top;

	print "-----------------------------------------------------------------------"
	elapsed = timeit.default_timer() - start_all;
	print "[TIME] --  " +  repr(elapsed);
	print "[*] -- COMPLETE!";
	print 
	

except error.ArgError as e:
	if len(sys.argv) == 1 :
		print("\n  preprocessDB");
		print("  ==========================================================================");
		print("    This program reads in a list of circuits in Verilog to process ");
		print("    The preprocessing extracts and stores the birthmark representation");
		print("    Results are stored in an XML file");
		print("    Option to process each module individual as a design [h] option");
		print("\n  Usage: python preprocessDB.py [Verilog] [Output XML] [k] [OPTION: h]");
		print("       DB - File containing list of verilog files")
		print("       O  - Output XML File")
		print("       k  - K value for the kgram analysis")
		print("    OPTION:");
		print("       -O  - optimize all designs \n");
		#print("       h  - process each module as a design\n");
	else:
		print "[ERROR] -- Not enough argument. Provide list of circuits and a XML file ";
		print("\n  Usage: python preprocessDB.py [Verilog] [Output XML] [k] [OPTION: h]");
		print("       DB - File containing list of verilog files")
		print("       O  - Output XML File")
		print("       k  - K value for the kgram analysis")
		print("    OPTION:");
		print("       -O  - optimize all designs \n");
		#print("       h  - process each module as a design\n");

except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print "        -- " +  e.msg;
	
except error.GenError as e:
	if("File list is empty" in e.msg):
		print("[ERROR] -- The design cannot be found");
	else:
		print "[ERROR] -- " + e.msg;

except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
