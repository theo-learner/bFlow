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
import dataflow as dfx
import processRef as ref 
from bs4 import BeautifulSoup




def skt_receive(csocket,timeout=2):
    #make socket blocking
    csocket.setblocking(1);

    total_data=[];
    data = csocket.recv(8192)
    total_data.append(data)

    #make socket non blocking
    csocket.setblocking(0)
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
 
 
def main():
	#Check Argument Length
	if len(sys.argv) != 4:
		print "[ERROR] -- Not enough arguments";
		print "        -- python monitor.py <verilog file> <IP ADDR> <PORT>"
		exit();

	verilogFile = sys.argv[1];
	ipaddr = sys.argv[2];
	port = int(sys.argv[3]);




	#Preprocess yosys script
	fileName = yosys.getFileData(verilogFile);
	(scriptName, dotfile) = ref.generateYosysScript(verilogFile);



#Set up communication with server
	try:
		print "[MONITOR] -- Setting up socket- IP: " + ipaddr + "\tPORT: " + repr(port);
		csocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
		csocket.connect((ipaddr, port));
	except:
		print "[ERROR] -- Make sure server size is running. Check IP and PORT"
		exit();


#INITIAL HANDSHAKE
	csocket.send("CLIENT_READY");
	val = skt_receive(csocket);

	if(val != 'SERVER_READY'):
		print "[ERROR] -- Server did not send ready signal"
		exit()

	print "[MONITOR] -- CONNECTED!";





#Start Monitoring
	prevTime = os.stat(verilogFile).st_mtime

	try:
		sleepTime = 3;

		while(True):
			curTime = os.stat(verilogFile).st_mtime
			st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
			print "[" + st + "] -- Checking for changes..";

			if(prevTime != curTime ):
				print "[" + st + "] -- -- Reference has been modified: " + repr(curTime);
				prevTime = curTime;

				rVal = yosys.execute(scriptName);
				if(rVal != ""):
					print "Continuing to monitor..."
					time.sleep(sleepTime);
					continue;

				soup = ref.generateXML(dotfile, fileName[1]);
				print "Sending XML Representation of Birthmark to server..."
				csocket.send(repr(soup));
				
				print "Waiting for response..."
				val = skt_receive(csocket);
				if(val != 'SERVER_READY'):
					print "[ERROR] -- Server did not send ready signal"
					exit()
				print "Finished! Continue monitoring..."
									 
			time.sleep(sleepTime);

	except:
		print "Error: ", sys.exc_info()[0];
		traceback.print_exc(file=sys.stdout);
		st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
		print "---------------------------------------------------------------"
		print "[" + st + "] -- User has stopped editing file...quitting";

	print "[" + st + "] -- COMPLETE!";




if __name__ == '__main__':
	main();
