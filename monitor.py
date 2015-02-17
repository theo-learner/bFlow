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
import socket;


def skt_receive(csocket,timeout=2):
    #make socket non blocking
    csocket.setblocking(0)
     
    total_data=[];
    data='';
    begin=time.time()

    while 1:
        #if you got some data, then break after timeout
        if total_data and time.time()-begin > timeout:
            break
         
        #if you got no data at all, wait a little longer, twice the timeout
        elif time.time()-begin > timeout*2:
            break
         
        try:
            data = csocket.recv(8192)
            if data:
                total_data.append(data)
                begin=time.time()
            else:
                time.sleep(0.1)
        except:
            pass
     
	return ''.join(total_data)
 
 
#Check Argument Length
if len(sys.argv) != 4:
	print "[ERROR] -- Not enough argument. Provide Verilog file to monitor";
	exit();

verilogFile = sys.argv[1];
ipaddr = sys.argv[2];
port = int(sys.argv[3]);


if(".v" not in verilogFile):
	print "[ERROR] -- File does not have verilog extension";
	exit();


fileName = yosys.getFileData(verilogFile);
print "Monitoring Verilog File: " + fileName[0] + fileName[1] + "." + fileName[2];


#Preprocess yosys script
scriptName = "yoscript_ref"
yosys.create_yosys_script(verilogFile, scriptName)

#Set up communication with server
try:
	print "[MONITOR] -- Setting up socket- IP: " + ipaddr + "\tPORT: " + repr(port);
	csocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
	csocket.connect((ipaddr, port));
except:
	print "[ERROR] -- Make sure server size is running. Check IP and PORT"
	exit();


csocket.send("CLIENT_READY");
rVal = skt_receive(csocket);
print "[MONITOR] -- CONNECTED!";


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
			#status = yosys.execute(scriptName);
				

		time.sleep(5);

except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);
	st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
	print "---------------------------------------------------------------"
	print "[" + st + "] -- User has stopped editing file...quitting";

print "[" + st + "] -- COMPLETE!";


