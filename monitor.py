#!/usr/bin/python2.7

'''
	Monitor: 
		Monitors a verilog file for changes made such that it can be compared with a database 

'''
import os;
import sys;
import re;
import time;
import datetime;
import yosys;
import traceback;


if len(sys.argv) != 2:
	print "[ERROR] -- Not enough argument. Provide Verilog file to monitor";
	exit();


verilogFile = sys.argv[1];
if(".v" not in verilogFile):
	print "[ERROR] -- File does not have verilog extension";
	exit();


fileName = yosys.getFileData(verilogFile);
print "Monitoring Verilog File: " + fileName[0] + fileName[1] + "." + fileName[2];


#Preprocess yosys script
scriptName = "yoscript_ref"
yosys.create_yosys_script(verilogFile, fileName[0], fileName[1], scriptName)


#Start Monitoring
prevTime = os.stat(verilogFile).st_mtime

try:
	while(True):
		curTime = os.stat(verilogFile).st_mtime
		st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
		print "[" + st + "] -- Checking for changes..";

		if(prevTime != curTime ):
			print "[" + st + "] -- -- Reference has been modified: " + repr(curTime);
			prevTime = curTime;
			status = yosys.execute(scriptName);
				

		time.sleep(5);

except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);
	st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
	print "---------------------------------------------------------------"
	print "[" + st + "] -- User has stopped editing file...quitting";

print "[" + st + "] -- COMPLETE!";


