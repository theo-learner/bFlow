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



def generateYosysScript(verilogFile):
	scriptName = "data/yoscript"
	scriptResult = yosys.create_yosys_script(verilogFile, scriptName)
	dotFiles = scriptResult[0];
	top = scriptResult[1];
	return (scriptName, dotFiles, top);



def main():
	try:
		if len(sys.argv) != 2: 
			raise error.ArgError();

		
		vfile = sys.argv[1];

		#Preprocess yosys script
		(scriptName, dotFiles, top) = generateYosysScript(vfile);
		rVal = yosys.execute(scriptName);
		soup = BeautifulSoup();

		ckttag = xmlExtraction.generateXML("./dot/" + top+".dot", -1, top, soup)
		soup.append(ckttag);

		
		
		fileStream = open("data/reference.xml", 'w');
		fileStream.write(repr(soup));
		fileStream.close();

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  processVerilog");
			print("  ================================================================================");
			print("    This program reads the files in a verilog file and extracts AST with yosys");
			print("    Birthmark is then extracted and stored in an XML file ");
			print("    OUTPUT: data/reference.xml");
			print("\n  Usage: python processVerilog.py [Verilog]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide Verilog File to process";
			print("           Usage: python processVerilog.py [Verilog]\n");


	except error.YosysError as e:
		print "[ERROR] -- Yosys has encountered an error...";
		print e.msg;

	except error.GenError as e:
		print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();
