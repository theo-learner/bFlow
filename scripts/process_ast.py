#!/usr/bin/python2.7

'''
	processAST: 
	  Processes a dot file (AST) and extracts the XML birthmark 
		for it	
'''

import sys;
import yosys;
import xmlExtraction;
from bs4 import BeautifulSoup
import error;



def main():
	try:
		if len(sys.argv) < 3 or len(sys.argv) > 4: 
			raise error.ArgError();

		
		dotfile= sys.argv[1];
		kVal = sys.argv[2];
		opt = False
		if(len(sys.argv) == 4):
			if(sys.argv[3] == "-O"):
				opt = True
			else:
				raise error.ArgError();

		fileName = yosys.getFileData(dotfile);

		soup = BeautifulSoup();
		ckttag = xmlExtraction.generateXML(dotfile, -1, fileName[1], soup)
		soup.append(ckttag);

		fileStream = open("data/reference.xml", 'w');
		fileStream.write(repr(soup));
		fileStream.close();

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  processAST");
			print("  ================================================================================");
			print("    This program reads the files in a dot file (AST)");
			print("    Birthmark is then extracted and stored in an XML file ");
			print("    OUTPUT: data/reference.xml");
			print("\n  Usage: python process_ast.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print("           Usage: python process_ast.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");
	except error.GenError as e:
		print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();
