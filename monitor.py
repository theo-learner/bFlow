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
 
 
#Check Argument Length
if len(sys.argv) != 4:
	print "[ERROR] -- Not enough arguments";
	print "        -- python monitor.py <verilog file> <IP ADDR> <PORT>"
	exit();

verilogFile = sys.argv[1];
ipaddr = sys.argv[2];
port = int(sys.argv[3]);


if(".v" not in verilogFile):
	print "[ERROR] -- File does not have verilog extension";
	exit();


#Preprocess yosys script
fileName = yosys.getFileData(verilogFile);
scriptName = "yoscript_ref"
print "Monitoring Verilog File: " + fileName[0] + fileName[1] + "." + fileName[2];
scriptResult = yosys.create_yosys_script(verilogFile, scriptName)
dotfile = scriptResult[0];




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
				time.sleep(5);
				continue;

			result = dfx.extractDataflow(dotfile);


#######################################################
			soup = BeautifulSoup();
			ckttag = soup.new_tag("CIRCUIT");
			ckttag['name'] = fileName[1];
			ckttag['id'] = -1 
			soup.append(ckttag);

			#Store the max seq
			maxList = result[0];
			for seq in maxList:
				seqtag = soup.new_tag("MAXSEQ");
				seqtag.string =seq 
				ckttag.append(seqtag);
				
			minList = result[1];
			for seq in maxList:
				seqtag = soup.new_tag("MINSEQ");
				seqtag.string =seq 
				ckttag.append(seqtag);
			
			constSet= result[2];
			for const in constSet:
				consttag = soup.new_tag("CONSTANT");
				consttag.string = const
				ckttag.append(consttag);
			
			fpDict= result[3];
			name = result[4];
			if(len(fpDict) != len(name)):
				raise error.SizeError("Fingerprint Dictionary and Name size do not match");
	
			i = 0;
			for fp in fpDict:
				fptag = soup.new_tag("FP");
				fptag['type'] = name[i];
				for k, v in fp.iteritems():
					attrTag = soup.new_tag("DATA");
					attrTag['size'] = k;
					attrTag['count'] = v;
					fptag.append(attrTag);
				i = i + 1;
	
				ckttag.append(fptag);
			#print soup.prettify();
#######################################################
		
			print "Sending XML Representation of Birthmark to server..."
			xmldata = soup.prettify().replace('\n', '');
			csocket.send(xmldata);
			
			print "Waiting for response..."
			val = skt_receive(csocket);
			if(val != 'SERVER_READY'):
				print "[ERROR] -- Server did not send ready signal"
				exit()
			print "Finished! Continue monitoring..."
								 
		time.sleep(5);

except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);
	st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
	print "---------------------------------------------------------------"
	print "[" + st + "] -- User has stopped editing file...quitting";

print "[" + st + "] -- COMPLETE!";


