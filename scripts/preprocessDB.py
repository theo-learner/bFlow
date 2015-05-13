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
import xmlExtraction



try:
	start_all = timeit.default_timer();
	if len(sys.argv) < 4 or len(sys.argv) > 5: 
		raise error.ArgError()
		
	cfiles = sys.argv[1];
	dbFile = sys.argv[2];
	kVal = sys.argv[3];

	arg = ""
	if len(sys.argv) == 5 :
		arg = sys.argv[4];

	print
	print "########################################################################";
	print "[PPDB] -- Begin Circuit Database Preprocessing..."
	print "########################################################################";
	print

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
		print "--------------------------------------------------------------------------------"
		print "[PPDB] -- Extracting feature from verilog file: " + line;
		print "--------------------------------------------------------------------------------"

		# Processes the verilog files 
		start_yosys = timeit.default_timer();
		if arg == 'h':
			val  = yosys.create_yosys_script(line, scriptName, hier=True)
		else:
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


		start_time= timeit.default_timer();
		if arg == 'h':
			#Goes through the AST extracted from yosys and gets the birthmark components
			for dotfile in dotFiles:
				print "MODULE: " + dotfile
				if dotfile in processedTop:
					print "[WARNING] -- Module " + dotfile + " already exists...skipping...";
					multipleTop.add(dotfile);

				processedTop.add(dotfile);
				dotfilename = "./dot/"+dotfile+".dot";
				ckttag = xmlExtraction.generateXML(dotfilename, ID, dotfile, soup, kVal)
				dbtag.append(ckttag)
				ID = ID + 1;
		elif arg == "":
			dotfilename = "./dot/"+dotFiles[0]+".dot";
			ckttag = xmlExtraction.generateXML(dotfilename, ID, dotFiles[0], soup, kVal)
			dbtag.append(ckttag)
			ID = ID + 1;
		else:
			raise error.GenError("Unknown Argument. Use [-h] for hierarchy preprocessing");

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
	
	print " -- K Gram Value: " + kVal;
	print " -- Hierarchy: " + repr(arg == '-h');
	print " -- XML File saved  : " + dbFile;
	print " -- Files processed : " + repr(ID);
	print " -- Multiple modules found:"
	for top in multipleTop:
		print "   * " + top;

	print "-----------------------------------------------------------------------"
	elapsed = timeit.default_timer() - start_all;
	print "[PPDB] -- ELAPSED: " +  repr(elapsed);
	print "[PPDB] -- COMPLETE!";
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
		print("       h  - process each module as a design\n");
	else:
		print "[ERROR] -- Not enough argument. Provide list of circuits and a XML file ";
		print("\n  Usage: python preprocessDB.py [Verilog] [Output XML] [k] [OPTION: h]");
		print("       DB - File containing list of verilog files")
		print("       O  - Output XML File")
		print("       k  - K value for the kgram analysis")
		print("    OPTION:");
		print("       h  - process each module as a design\n");

except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print "        -- " +  e.msg;
	
except error.GenError as e:
	print "[ERROR] -- " + e.msg;

except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
