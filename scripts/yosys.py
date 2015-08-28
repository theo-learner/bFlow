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
import constructHierarchy as hierarchy;

def create_yosys_script(fileName, scriptName, hier = False, opt = False):
	script = "";	
	script = script + "echo on\n";

	moduleList = dict();
	fileList = hierarchy.extractModuleNames(moduleList, fileName);
	if(len(fileList) == 0):
		raise error.GenError("File list is empty")

	topModules = hierarchy.getTopModule(moduleList);
	top = topModules[0];
	topfile = topModules[1];



	if opt == True:                  #simplify only the database circuits
		print "[YOSYS] -- Optimizations on"
	else:
		print "[YOSYS] -- Optimizations off"

	for vfile in fileList:
		script = script + "read_verilog " + vfile + "\n";

	optcmd = "opt_muxtree; opt_reduce -full; opt_share; opt_rmdff;\n"

	if opt == True:                  #simplify only the database circuits
		optcmd = optcmd + "opt_clean;\n"     #Many unused net and cells will be removed

	#if opt != True:
	if opt != True:
		fsmcmd = "fsm_detect; fsm_extract; fsm_opt; fsm_expand; fsm_opt; fsm_recode; fsm_map;\n"
		#fsmcmd = fsmcmd + "fsm_recode; fsm_map;\n"
	else:
		fsmcmd = "fsm;\n"

	

	script = script + "\n\n";
	script = script + "hierarchy -check\n";
	script = script + "proc;\n\n";
	script = script + fsmcmd;
	script = script + "memory_collect;\n\n";

	#script = script + "techmap -map /usr/local/share/yosys/pmux2mux.v;\n\n"
	script = script + "flatten\n";
	
	if opt == True:                  #simplify only the database circuits
		script = script + "wreduce\n";

	script = script + optcmd;
	#script = script + "splice;\n";
	script = script + "stat " + top + "\n\n";


	dotFile = [];
	if hier == True:
		for k,v in moduleList.iteritems():
			if(k == top):
				dotName = top
			else:
				dotName = top + "__" + k

			script = script + "show -width -format dot -prefix ./dot/"+ dotName +" " + k + "\n";
			dotFile.append(dotName);
	else:
		script = script + "show -width -format dot -prefix ./dot/"+ top +" " + top + "\n";
		dotFile.append(top);

	fileStream = open(scriptName, 'w');
	fileStream.write(script);
	fileStream.close();

	return (dotFile, top, topfile);




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
		print "[YOSYS] -- ELAPSED: " +  repr(elapsed) + "\n";

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


