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
import argparse
import flag;



def generateYosysScript(verilogFile, optVal):
	scriptName = "data/yoscript"
	scriptResult = yosys.create_yosys_script(verilogFile, scriptName, opt=optVal)
	dotFiles = scriptResult[0];
	top = scriptResult[1];
	vfile= scriptResult[2];
	return (scriptName, dotFiles, top, vfile);



def main():
	try:

		#Parse command arguments
		parser = argparse.ArgumentParser();
		parser.add_argument("circuit", help="Verilog circuit to process");
		parser.add_argument("k", help="Value of K-gram");
		parser.add_argument("-O", "--optimize", help="Set optimization: 3: Full Opt, 2: Full opt no clean, 1: No opt w/ clean, 2: No Opt", type=int);
		parser.add_argument("-v", "--verbose", help="Prints additional information", action="store_true");
		parser.add_argument("-p", "--predict", help="Extracts information inorder to do prediction", action="store_true");
		parser.add_argument("-s", "--strict", help="Perform a stricter search by adding more constraints", action="store_true");
	
		arguments = parser.parse_args()
		source = arguments.circuit;
		kVal = arguments.k;
		optFlag =  arguments.optimize
		verboseFlag = arguments.verbose
		predictFlag= arguments.verbose
		strictFlag = arguments.strict


		#Remove the reference XML file if it exists
		referenceFile = "data/reference.xml";
		if(os.path.exists(referenceFile)):
			os.remove(referenceFile);



		#Preprocess yosys script
		print "--------------------------------------------------------------"
		print "[*] -- Synthesizing circuit design..."
		print "--------------------------------------------------------------"
		(scriptName, dotFiles, top, vfile) = generateYosysScript(source, optFlag);
		rVal = yosys.execute(scriptName);
		if(rVal != ""):                       #Make sure no Error occurred during synthesis
			if(("show") in  rVal):
				print "[WARNING] -- Show error encountered..."
				print "          -- Performing Yosys Synthesis without optimizations..."
				(scriptName, dotFiles, top, vfile) = generateYosysScript(source, optFlag-1);

				rVal = yosys.execute(scriptName);

				if(rVal != ""):                       #Make sure no Error occurred during synthesis
					raise error.YosysError(rVal);
			else:
				raise error.YosysError(rVal);


		print "\n--------------------------------------------------------------"
		print "[*] -- Extracting birthmark from AST..."
		print "--------------------------------------------------------------"
		soup = BeautifulSoup();

		ckttag = xmlExtraction.generateXML("./dot/" + top+".dot", soup, kVal, verbose=verboseFlag, findEndGram=predictFlag, strict=strictFlag);
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

