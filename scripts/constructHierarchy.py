#!/usr/bin/python2.7

'''
	constructHierarchy	
	  Constructs the hierarchy of a design
'''

import networkx as nx;
import sys, traceback;
import re;
import error;
import timeit
import yosys;
import os;
from os import listdir;
import string;

node = 0;

class Module:

	def __init__(self):
		self.name = ""
		self.snippet = [];
		self.children = [] ;



def remove_comments(string):
	pattern = r"(\".*?\"|\'.*?\')|(/\*.*?\*/|//[^\r\n]*$)"
	# first group captures quoted strings (double or single)
	# second group captures comments (//single-line or /* multi-line */)
	regex = re.compile(pattern, re.MULTILINE|re.DOTALL)

	def _replacer(match):
		# if the 2nd group (capturing comments) is not None,
		# it means we have captured a non-quoted (real) comment string.
		if match.group(2) is not None:
			return "" # so we will return empty to remove the comment
		else: # otherwise, we will return the 1st group
			return match.group(1) # captured quoted-string

	return regex.sub(_replacer, string)


def extractModuleNames_single(moduleList, vfile):
	badchar = '(# '

	#Read in the verilog file
	fileContent = open(vfile, 'r').read() 
	fileContent = remove_comments(fileContent);
	fileContent = os.linesep.join([s for s in fileContent.splitlines() if s])
	fileContent = fileContent.split("\n")
	
	
	#Find the modules located in the file. Note the location and the module name
	index = 0;	
	moduleName = "";
	hasEnd = True;
	startIndex = 0;
	comment = False;

	for line in fileContent:
		splitted = line.split();
		if len(splitted) > 0:

			#Look for the module tag
			if 'module' == splitted[0]:

				#Remove any unwanted characters such as (
				moduleName = re.split('#|\(',splitted[1])[0]
				print "MODULE NAME: " + moduleName

				if(hasEnd):             #Make sure there is an endmodule with every module
					hasEnd = False
				else:
					raise error.GenError("Found another module before endmodule");

				m = Module();
				m.name = moduleName;
				startIndex = index+1;
				moduleList[moduleName] = m;

			elif 'endmodule' == splitted[0]:
				moduleList[moduleName].snippet = fileContent[startIndex : index];
				hasEnd = True;

		index = index + 1;	



def extractModuleNames(moduleList, name):
	fileList = []

	if(os.path.isfile(name)):
		vfile = name;
		print "[HIER] -- Reading Verilog file: " + vfile;

		if(".v" !=  vfile[-2:]):
			raise error.GenError("Make sure file is a verilog file");

		extractModuleNames_single(moduleList, name)
		fileList.append(vfile);
		
	elif(os.path.isdir(name)):
		vdir = name;
		print "[HIER] -- Reading directory " + vdir;
		if vdir[-1] != '/':
			vdir = vdir+ '/';
	
		for vfile in listdir(vdir):
			print " -- Reading in v File: " + vfile;
	
			#Make sure the file that is being read in is a DOT file
			if(".v" !=  vfile[-2:]):
				print "[WARNING] -- Extension does not match that of Verilog. Skipping file";
				continue;

			extractModuleNames_single(moduleList, vdir + vfile)
			fileList.append(vdir+vfile);
	
	return fileList;


def findModuleChildren(moduleList):
	#Search for module declarations
	moduleHasParent = set();
	index = 0;
	for k, v in moduleList.iteritems():

		#Get the location of the module definitions
		moduleLines = v.snippet;
		print "CHECKING SUBMODULES IN : " + k
		
		for line in moduleLines:
			splitted = line.split();
			if len(splitted) > 0:

				#Get the module that was found in the line
				matching = [s for s in moduleList.keys() if s == splitted[0]]
				if len(matching) > 0:
					print " * SUBMODULE FOUND: " + matching[0]
					v.children.append(matching[0]);
					moduleHasParent.add(matching[0]);    #Used to find top module

		index = index + 1;	


	#Check which module has no parent
	topModules = [s for s in moduleList if s not in moduleHasParent]
	
	#Make sure there is at least 1 module found for top
	if len(topModules) == 0:
		raise error.GenError("No Top Module Found");
	elif len(topModules) > 1:
		print "[WARNING] -- Multiple possible top modules"
		print topModules
	
	return topModules






def growHierarchy(H, moduleName, moduleList):
	global node;
	#print moduleName + " NODE: " + repr(node);
	curNode = node;
	node = node + 1;

	H.add_node(moduleName + "_" + repr(curNode), name=moduleName);

	children = moduleList[moduleName].children
	
	for child in children:
		childNode = growHierarchy(H, child, moduleList);
		H.add_edge(moduleName + "_" + repr(curNode), child + "_" + repr(childNode));
		#print "ADDING EDGE BETWEEN " + repr(curNode) + " " + repr(childNode);
	
	return curNode;




def processHierarchy(vfile):
	moduleList = dict()
	fileList = extractModuleNames(moduleList, vfile)
	topModules = findModuleChildren(moduleList);

	H = nx.DiGraph();	
	growHierarchy(H, topModules[0],  moduleList)	
	nx.write_dot(H, "test.dot")

	return (fileList, topModules, H);





def main():
	'''
    MAIN 
		 Main function: Constructs the hierarchy
	'''
	try:
		if len(sys.argv) != 2: 
			raise error.ArgError();


		start_time = timeit.default_timer();
		processHierarchy(sys.argv[1]);
		elapsed = timeit.default_timer() - start_time;
		print "[HIER] -- ELAPSED: " +  repr(elapsed) + "\n";
		

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  constructHierarchy");
			print("  ================================================================================");
			print("    This program reads the files in a directory or a verilog file");
			print("    Looks for module names and creates a graph of the hierarchy");
			print("\n  Usage: python constructHierarchy.py [Verilog or folder]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print("           Usage: python constructHierarchy.py [Verilog or folder]\n");
	except error.GenError as e:
		print "[ERROR] -- " + e.msg;





if __name__ == '__main__':
	main();
