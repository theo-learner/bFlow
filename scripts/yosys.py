#!/usr/bin/python2.7

'''
	yosys module: 
		Functions for interacting with the yosys tools
'''

import os;
import sys;
import re;
import timeit;
import datetime;
from subprocess import call
import error;
import constructHierarchy as hier;

def create_yosys_script(fileName, scriptName):
	script = "";	
	script = script + "echo on\n";

	moduleList = dict();
	fileList = hier.extractModuleNames(moduleList, fileName);
	if(len(fileList) == 0):
		raise error.GenError("File list is empty")

	topModules = hier.findModuleChildren(moduleList);
	top = topModules[0];

	for vfile in fileList:
		script = script + "read_verilog " + vfile + "\n";

	script = script + "\n\n";
	script = script + "hierarchy -check\n";
	script = script + "proc; opt; fsm; opt;\n\n";
	script = script + "memory_collect; opt;\n\n";
	#script = script + "techmap -map /usr/local/share/yosys/pmux2mux.v;\n\n"
	script = script + "flatten; opt\n";
	script = script + "wreduce; opt\n\n";
	script = script + "stat " + top + "\n\n";


	dotFile = [];
	for k,v in moduleList.iteritems():
		if(k == top):
			dotName = top
		else:
			dotName = top + "__" + k

		script = script + "show -width -format dot -prefix ./dot/"+ dotName +" " + k + "\n";
		dotFile.append(dotName);


	fileStream = open(scriptName, 'w');
	fileStream.write(script);
	fileStream.close();

	return (dotFile, top);




def execute(scriptFile):
	print "[YOSYS] -- Running yosys tools..."
	cmd = "yosys -Qq -s " + scriptFile + " -l data/.pyosys.log";
	rc = call(cmd, shell=True);

	msg = ""
	hasError = False;
	with open("data/.pyosys.log") as f:
		fsc = open("data/statcell.dat", "a");
		fsw = open("data/statwire.dat", "a");
		for line in f:
			if("ERROR:" in line or hasError):
				hasError = True;
				msg = msg + line;
			elif("Number of cells:" in line):
				fsc.write(line);
			elif("Number of wire bits:" in line):
				fsw.write(line);
		fsc.close()
		fsw.close()


	if hasError:
		print msg;
		return msg;
	
	return "";




def getFileData(fileName):
	data = re.search("(.+\/)*(.+)\.(.+)$", fileName);
	return (data.group(1), data.group(2), data.group(3));








def main():
	'''
    MAIN 
		 Main function: Creates Yosys script and runs yosys
	'''
	try:
		if len(sys.argv) != 2: 
			raise error.ArgError();


		start_time = timeit.default_timer();

		scriptName = "data/yoscript"
		(dotFiles, top) = create_yosys_script(sys.argv[1], scriptName)
		execute(scriptName)

		elapsed = timeit.default_timer() - start_time;
		print "[HIER] -- ELAPSED: " +  repr(elapsed) + "\n";

		print dotFiles;
		print "TOP: " + top
		

	except error.ArgError as e:
		if len(sys.argv) == 1 :
			print("\n  yosys");
			print("  ================================================================================");
			print("    This program reads the files in a directory or a verilog file");
			print("    Creates a yosys script and runs it");
			print("\n  Usage: python yosys.py [Verilog or folder]\n");
		else:
			print "[ERROR] -- Not enough argument. Provide DOT File to process";
			print("           Usage: python yosys.py [Verilog or folder]\n");
	except error.GenError as e:
		print "[ERROR] -- " + e.msg;





if __name__ == '__main__':
	main();


