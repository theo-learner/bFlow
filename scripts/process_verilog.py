#!/usr/bin/python2.7

'''
	processVerilog: 
	  Processes a verilog file and extracts the XML birthmark 
		for it	
'''

import sys;
import xmlExtraction;
import yosys;
from bs4 import BeautifulSoup
import error;
import os;



def generateYosysScript(verilogFile, optVal):
	scriptName = "data/yoscript"
	scriptResult = yosys.create_yosys_script(verilogFile, scriptName, opt=optVal)
	dotFiles = scriptResult[0];
	top = scriptResult[1];
	vfile= scriptResult[2];
	return (scriptName, dotFiles, top, vfile);



def main():
	try:
		if len(sys.argv) < 3 or len(sys.argv) > 5: 
			raise error.ArgError();

		#Remove the reference XML file if it exists
		referenceFile = "data/reference.xml";
		if(os.path.exists(referenceFile)):
			os.remove(referenceFile);

		
		vfile = sys.argv[1];
		kVal = sys.argv[2];
		opt = False
		verboseValue = False
		if(len(sys.argv) == 4):
			if(sys.argv[3] == "-O"):
				opt = True
			if(sys.argv[3] == "-v" ):
				print "VERBOSE IS SET"
				verboseValue = True;
		elif(len(sys.argv) == 5):
			if(sys.argv[4] == "-O"):
				opt = True
			if(sys.argv[4] == "-v"):
				print "VERBOSE IS SET"
				verboseValue = True;


		#Preprocess yosys script
		(scriptName, dotFiles, top, vfile) = generateYosysScript(vfile, opt);
		rVal = yosys.execute(scriptName);
		soup = BeautifulSoup();

		ckttag = xmlExtraction.generateXML("./dot/" + top+".dot", soup, kVal, verbose=verboseValue, findEndGram=True)
		ckttag['name'] = top;
		ckttag['file'] = vfile;
		ckttag['id'] = -1

		soup.append(ckttag);

		
		
		fileStream = open(referenceFile, 'w');
		fileStream.write(repr(soup));
		fileStream.close();

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  processVerilog");
			print("  ================================================================================");
			print("    This program reads the files in a verilog file and extracts AST with yosys");
			print("    Birthmark is then extracted and stored in an XML file ");
			print("    OUTPUT: data/reference.xml");
			print("\n  Usage: python process_verilog.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide Verilog File to process";
			print("           Usage: python process_verilog.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");


	except error.YosysError as e:
		print "[ERROR] -- Yosys has encountered an error...";
		print e.msg;

	except error.GenError as e:
		print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();
