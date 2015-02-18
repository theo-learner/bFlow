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
import sqlite3 as sql
import error;
import yosys;
import dataflow as dfx
import traceback


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
	scriptName = "yoscript_db"
	fstream = open(cfiles);
	flines = fstream.readlines();

	for line in flines:
		line= re.sub(r"\s+", "", line);
		print "[PPDB] -- Extracting feature from verilog file: " + line;

		val  = yosys.create_yosys_script(line, scriptName)
		top = val[1];

		yosys.execute(scriptName);

		#(maxList, minList, constSet, fp) 
		result = dfx.extractDataflow(val[0]);
		
		#Create tag for new circuit
		ckttag = soup.new_tag("CIRCUIT");
		ckttag['name'] = top
		ckttag['id'] = ID
		ID = ID + 1;
		dbtag.append(ckttag)
	
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
		print
		
	#print soup.prettify()
	fileStream = open(dbFile, 'w');
	fileStream.write(repr(soup));
	fileStream.close();
	
	print " -- XML File saved  : " + dbFile;
	print " -- Files processed : " + repr(ID);
	

except sql.Error, e:
	print "[ERROR] -- %s:" % e.args[0];
	sys.exit(1);
except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print e.msg;
except error.SizeError as e:
	print "[ERROR] -- Sizing Error...";
	print "        -- " +  e.msg;
except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
finally:
	print "-----------------------------------------------------------------------"
	print "[PPDB] -- COMPLETE!";
	print 
