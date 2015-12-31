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
from bs4 import BeautifulSoup
import argparse
import process_verilog 




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
    parser = argparse.ArgumentParser();
    parser.add_argument("verilog", help="Verilog File");
    parser.add_argument("kval", help="Value for k to use");
    parser.add_argument("ip", help="IP Address");
    parser.add_argument("port", help="Port");
    parser.add_argument("-O", "--optimize", help="Turns on optimizations when processing the circuits", action="store_true");
    parser.add_argument("-s", "--strict", help="Adds additional contraints to make the search more strict", action="store_true");
    parser.add_argument("-p", "--predict", help="Performs partial q-gram matching", action="store_true");

    arguments = parser.parse_args()

    verilogFile = arguments.verilog;
    ipaddr = arguments.ip;
    port = int(arguments.port);
    port_display = 8002; 
    ipaddr_display = "10.0.1.11";
    kval = arguments.kval;
    strictFlag = arguments.strict;
    predictFlag = arguments.predict;
    print arguments.optimize
    optFlag= 0
    if(arguments.optimize):
        optFlag= 3;            #Full optimization
    print optFlag


    # Processes the verilog files 
    print "[*] -- Creating Yosys script..."
    scriptName = ".yosys_script"
    (dotfiles, top, vfile) = process_verilog.generateYosysScript(verilogFile, scriptName, optFlag)





    #Set up communication with backend server
    csocket1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
    try:
        print "[MONITOR] -- Setting up socket- IP: " + ipaddr + "\tPORT: " + repr(port);
        csocket1.connect((ipaddr, port));
    except:
        print "[ERROR] -- Make sure server size is running. Check IP and PORT"
        exit();
	
    #Set up communication with display client
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
    try:
        print "[MONITOR] -- Setting up server for display: " + ipaddr_display + "\tPORT: " + repr(port_display);
        server.bind((ipaddr_display, port_display));
    except socket.error as msg:
        print "[ERROR] -- Bind Failed: " + str(msg[0]) + " Message " + msg[1];
        sys.exit();

    #INITIAL HANDSHAKE for backend
    csocket1.send("CLIENT_READY");
    val = skt_receive(csocket1);
    if(val != 'SERVER_READY'):
        print "[ERROR] -- Server did not send ready signal"
        exit()
    print "[MONITOR] -- CONNECTED!";


    #INITIAL HANDSHAKE for display
    print "[MONITOR] -- Waiting for display client to connect..."
    server.listen(1);
    (server_conn, addr) = server.accept();
    server_conn.send("SERVER_READY");

	








    #Start Monitoring
    prevTime = os.stat(verilogFile).st_mtime
    try:
        sleepTime = 3;

        while(True):
            curTime = os.stat(verilogFile).st_mtime
            st = datetime.datetime.fromtimestamp(time.time()).strftime('%H:%M:%S');
            print "[" + st + "] -- Checking for changes..";


            #Check to see if the modified time is different
            if(prevTime != curTime ):
                print "[" + st + "] -- -- Reference has been modified: " + repr(curTime);
                prevTime = curTime;

                soup = process_verilog.process_verilog_file(verilogFile, scriptName, top, vfile, kval, optFlag, False, predictFlag, strictFlag, False, True);
                if(soup == None):
                    continue;

                print "Sending XML Representation of Birthmark to server..."
                csocket1.send(repr(soup));
                
                print "Waiting for response..."
                result = skt_receive(csocket1);
                print "Finished! Continue monitoring..."
                
                server_conn.send(result);
                                                         
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
