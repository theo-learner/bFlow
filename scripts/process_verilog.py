#!/usr/bin/python2.7

'''
	processVerilog: 
	  Processes a verilog file and extracts the XML birthmark 
		for it	
'''

import sys;
import xmlExtraction;
import yosys;
from bs4 import BeautifulSoup
import error;
import os;
import argparse
import flag;


def generateYosysScript(verilogFile, scriptName, optVal):
    scriptResult = yosys.create_yosys_script(verilogFile, scriptName, opt=optVal)
    dotFiles = scriptResult[0];
    top = scriptResult[1];
    vfile= scriptResult[2];
    return (dotFiles, top, vfile);



def process_verilog_file(source, scriptName, top, vfile, kval, optFlag, verboseFlag, predictFlag, strictFlag, debugFlag, runFlag=False):
    #Preprocess yosys script
    if(debugFlag):
        print "--------------------------------------------------------------"
        print "[*] -- Synthesizing circuit design..."
        print "--------------------------------------------------------------"

    noOpt = False;

    rVal = yosys.execute(scriptName);
    if(rVal != ""):                       #Make sure no Error occurred during synthesis
        if(("show") in  rVal):
            if(debugFlag):
                print "[WARNING] -- Show error encountered..."
                print "          -- Performing Yosys Synthesis without optimizations..."

            if(optFlag -1 < 0):
                print "OPTFLAG: " + repr(optFlag) + " SHOW OPT: " + repr(optFlag-1)
                raise error.YosysError(rVal);

            (dotFiles, top, vfile) = generateYosysScript(source, scriptName+"_show", optFlag-1);
            rVal = yosys.execute(scriptName+"_show");
            noOpt = True;

            if(rVal != ""):                       #Make sure no Error occurred during synthesis
                if(runFlag == False):                 #Make sure no Error occurred during synthesis
                    raise error.YosysError(rVal);
                else:
                    return None; 

        elif(runFlag == False):
            raise error.YosysError(rVal);
        else:             
            return None; 


    if(debugFlag):
        print "\n--------------------------------------------------------------"
        print "[*] -- Extracting birthmark from AST..."
        print "--------------------------------------------------------------"

    soup = BeautifulSoup();

    checkSecondRun = False; #Check if the second run without opt has occured or not. 
    try:
        ckttag = xmlExtraction.generateXML("./dot/" + top+".dot", soup, kval, verbose=verboseFlag, findEndGram=predictFlag, strict=strictFlag, runFlag=runFlag);
    except error.GenError as e:
        print "[WARNING] -- " + e.msg;
        checkSecondRun = True;

    if(checkSecondRun == True):
        if(noOpt == False):
            if(optFlag -1 < 0):
                print "OPTFLAG: " + repr(optFlag) + " SHOW OPT: " + repr(optFlag-1)
                raise error.YosysError(rVal);

            (dotFiles, top, vfile) = generateYosysScript(source, scriptName+"_show", optFlag-1);
            rVal = yosys.execute(scriptName+"_show");

            if(rVal != ""):                       #Make sure no Error occurred during synthesis
                if(runFlag == False):                 #Make sure no Error occurred during synthesis
                    raise error.YosysError(rVal);
                else:
                    return None; 
            try:
                ckttag = xmlExtraction.generateXML("./dot/" + top+".dot", soup, kval, verbose=verboseFlag, findEndGram=predictFlag, strict=strictFlag, runFlag=runFlag);
            except error.GenError as e:
                print "[ERROR] -- " + e.msg;
                raise error.YosysError("No Logic detected. Nothing to show")

        else:
            print "[ERROR] -- " + e.msg;
            raise error.YosysError("No Logic detected. Nothing to show")

    ckttag['name'] = top;
    ckttag['file'] = vfile;
    ckttag['id'] = -1

    soup.append(ckttag);
    return soup;

    
    




def main():
    try:
        #Parse command arguments
        parser = argparse.ArgumentParser();
        parser.add_argument("circuit", help="Verilog circuit to process");
        parser.add_argument("k", help="Value of K-gram");
        parser.add_argument("-O", "--optimize", help="Set optimization: 3: Full Opt, 2: Full opt no clean, 1: No opt w/ clean, 2: No Opt", type=int, default=3);
        parser.add_argument("-v", "--verbose", help="Prints additional information", action="store_true");
        parser.add_argument("-p", "--predict", help="Extracts information inorder to do prediction", action="store_true");
        parser.add_argument("-s", "--strict", help="Perform a stricter search by adding more constraints", action="store_true");

        arguments = parser.parse_args()
        source = arguments.circuit;
        kVal = arguments.k;
        optFlag =  arguments.optimize
        verboseFlag = arguments.verbose
        predictFlag= arguments.verbose
        strictFlag = arguments.strict


        #Remove the reference XML file if it exists
        scriptName = "data/yoscript"
        referenceFile = "data/reference.xml";
        if(os.path.exists(referenceFile)):
            os.remove(referenceFile);
        yosysErrorFile = "data/.pyosys.error";
        if(os.path.exists(yosysErrorFile)):
            os.remove(yosysErrorFile);

        (dotFiles, top, vfile) = generateYosysScript(source, scriptName, optFlag);
        soup = process_verilog_file(source, scriptName, top, vfile, kVal, optFlag, verboseFlag, predictFlag, strictFlag, True, True)
        if soup != None:
            fileStream = open(referenceFile, 'w');
            fileStream.write(repr(soup));
            fileStream.close();

    
    except error.ArgError as e:
        if len(sys.argv) == 1 :
            print("\n  processVerilog");
            print("  ================================================================================");
            print("    This program reads the files in a verilog file and extracts AST with yosys");
            print("    Birthmark is then extracted and stored in an XML file ");
            print("    OUTPUT: data/reference.xml");
            print("\n  Usage: python process_verilog.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");
        else:
            print "[ERROR] -- Not enough argument. Provide Verilog File to process";
            print("           Usage: python process_verilog.py [Verilog] [k: KGram Val] [Option: -O optimization]\n");


    except error.YosysError as e:
            print "[ERROR] -- Yosys has encountered an error...";
            print e.msg;

    except error.GenError as e:
            print "[ERROR] -- " + e.msg;



if __name__ == '__main__':
	main();

