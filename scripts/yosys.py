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
import subprocess;
import error;
import constructHierarchy as hierarchy;

def create_yosys_script(fileName, scriptName, hier = False, opt=3):
	'''
	create_yosys_script
		Creates a script to be run using yosys for a given design
		@PARAMS: fileName - path of design
		@PARAMS: scriptName - output script name
		@PARAMS: hier - perform hierarchy processing
		@PARAMS: opt - 	0: No optimization 
										1: No optimization (cleans circuit) 
										2: Optimization 
										3: optimize for reference design (clean can cause noshow)
	'''

	script = "";	
	script = script + "echo on\n";

	moduleList = dict();
	fileList = hierarchy.extractModuleNames(moduleList, fileName);
	if(len(fileList) == 0):
		raise error.GenError("File list is empty")

	topModules = hierarchy.getTopModule(moduleList);
	top = topModules[0];
	topfile = topModules[1];


	#Read in the verilog files
	for vfile in fileList:
		script = script + "read_verilog " + vfile + "\n";


	if opt == 3:                  #FULL OPTIMIZATIONS
		optcmd = "opt -keepdc;\n"     #Many unused net and cells will be removed
		#optcmd = "opt_const -keepdc -undriven; opt_muxtree; opt_reduce; opt_share; opt_clean\n"
		print " - Optimizations on"
	elif opt == 2:                #Optimizations with no clean operation. Used for searching incomplete circuits
		print " - Optimizations on (no CLEAN)"
		#optcmd = "opt_const -keepdc -undriven; opt_muxtree; opt_reduce; opt_share\n"
		optcmd = "opt -fast -keepdc\n"
	elif opt == 1:                #No optimizations except to just clean
		print " - Optimizations off (CLEAN)"
		optcmd = "clean;\n"
	elif opt == 0:                #No optimizations at all
		print " - Optimizations off"
		optcmd = "";
	else: 
		raise error.GenError("Optimization flag (0,1,2) is unknown: " + repr(opt));



	#if opt != True:
	if opt == 3 or opt == 1:
		fsmcmd = "fsm;\n"   #Command contains opt_clean
	else:
		fsmcmd = "fsm_detect; fsm_extract; fsm_opt; fsm_recode; fsm_map;\n"



	script = script + "\n\n";
	script = script + "hierarchy -check\n";
	script = script + "proc;\n\n";
	script = script + optcmd;
	script = script + fsmcmd;
	script = script + optcmd;
	script = script + "flatten\n";
	script = script + optcmd;
	#script = script + "memory;\n\n";
	script = script + " memory_dff; memory_share; memory_collect; \n"#memory_map\n";
	script = script + optcmd;


	#script = script + "techmap -map /usr/local/share/yosys/pmux2mux.v;\n\n"
	script = script + "wreduce;\n";
	if opt == 3 or opt == 1:
		script = script + "opt_clean -purge;\n";
	else: 
		script = script + optcmd;
	
        #script = script + "opt_clean -buf_clean;\n"

	#script = script + "dff2dffe\n";
	#script = script + optcmd;
	#script = script + "splice;\n";
	#script = script + "stat " + top + "\n\n";


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
	print " - Running yosys tools..."
	start_yosys = timeit.default_timer();
	cmd = "yosys -Qq -s " + scriptFile# + " -l data/.pyosys.log";
	#rc = call(cmd, shell=True);
	result = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE);
	log = ""
	for line in result.stderr:
		sys.stdout.write("  " + line)
		log += line;
	elapsed = timeit.default_timer() - start_yosys;
	print "[TIME] -- Synthesis: " +  repr(elapsed);
	print " - Yosys complete"
		

	msg = ""
	fscline = ""
	fswline = ""
	hasError = False;

	if "ERROR:" in log:
                yosysErrorFile = "data/.pyosys.error";
                e = open(yosysErrorFile, "w");
                e.write(log);
                e.close()

		return log;
	else:
		return ""

	'''
	fsc = open("data/statcell.dat", "a");
	fsc.write(fscline);
	fsc.close()
	fsw = open("data/statwire.dat", "a");
	fsw.write(fswline);
	fsw.close()
	'''


	




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
		print " - ELAPSED: " +  repr(elapsed) + "\n";

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


