/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @  rsearch.cpp
  @  
  @  @AUTHOR:Kevin Zeng
  @  Copyright 2012 – 2015
  @  Virginia Polytechnic Institute and State University
  @#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/


#ifndef MAIN_GUARD
#define MAIN_GUARD

//System Includes
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <sys/time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <math.h>
#include <fstream>

#include <sys/time.h>
#include <sys/stat.h>

//Server Includes
#include "similarity.hpp"
#include "database.hpp"
#include "error.hpp"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"
#include "tclap/CmdLine.h"

using namespace rapidxml;
using namespace TCLAP;


int main( int argc, char *argv[] ){
	Database* db = NULL;

	try{

		TCLAP::CmdLine cmdline("This program reads in a verilog file as well as a XMLdatabase files. It preprocesses the verilog file and extracts the birthmark. Compares the reference birthmark to the birthmarks in the database. Outputs a ranked list showing the circuits that are similar to the reference", ' ', "0.0");

		//Reference
		TCLAP::ValueArg<std::string> referenceArg("r", "reference", "Reference design file", true, "", "Verilog");
		cmdline.add(referenceArg);
		
		//Database XML
		TCLAP::ValueArg<std::string> databaseArg("d", "database", "Database XML file", true, "", "XML");
		cmdline.add(databaseArg);
		
		//Database XML
		TCLAP::ValueArg<std::string> kArg("k", "kflag", "KLC, KLR, KSC, KSR, KFC, KFR", false, "BIRTHMARK", "FLAG");
		cmdline.add(kArg);
		
		//Line number
		TCLAP::ValueArg<int> lineArg("l", "line", "Current line number of design", false, -1, "Line Number");
		cmdline.add(lineArg);
		
		//Print all ranking switch
		TCLAP::SwitchArg printAllArg("v", "verbose", "Print detailed results", cmdline, false);


		cmdline.parse(argc, argv);

		std::string xmlDB= databaseArg.getValue();
		std::string referenceFile = referenceArg.getValue();
		bool printall = printAllArg.getValue();
		std::string kFlag = kArg.getValue();
		int lineNumber= lineArg.getValue();
		
		/*
		//Check arguments : Verilog File, XML Database File
		int args = 3;
		int optional_args = 1;
		if(argc < args  || argc > (args + optional_args)) throw ArgException();

		//std::string kVal= argv[3];
		std::string xmlDB= argv[2];
		std::string referenceFile = argv[1];
		
		bool printall = false;
		if(argc == args+optional_args)
			printall = true;
			*/

		//Read Database
		printf("[REF] -- Reading Database\n");
		db = new Database(xmlDB);

		//Get extension
		int lastDotIndex= referenceFile.find_last_of(".");
		std::string ext = referenceFile.substr(lastDotIndex+1, referenceFile.length()-lastDotIndex);

		std::string cmd = "";

		struct stat statbuf;

		if(ext == "v"){
			//Extract the birthmark from the verilog
			printf("[REF] -- Reading Reference Verilog Design\n");
			cmd = "python scripts/process_verilog.py " + referenceFile + " " + db->getKVal(); 
		}
		else if(stat(referenceFile.c_str(), &statbuf) != -1){
			if(S_ISDIR(statbuf.st_mode))
				cmd = "python scripts/process_verilog.py " + referenceFile + " " + db->getKVal(); 
		}
		else if(ext == "dot"){
			printf("[REF] -- Reading Reference AST\n");
			cmd = "python scripts/process_ast.py " + referenceFile + " " + db->getKVal(); 
		}
		else throw cException("(MAIN:T2) Unknown Extension: " + ext);
			
		int status = system(cmd.c_str());

		std::string xmlREF = "data/reference.xml";
		std::string xmldata= "";
		std::string xmlline;
		std::ifstream refStream;
		refStream.open(xmlREF.c_str());
		if (!refStream.is_open()) throw cException("(MAIN:T1) Cannot open file: " + xmlREF);
		while(getline(refStream, xmlline))
			xmldata+= xmlline + "\n";

		xml_document<> xmldoc;
		char* cstr = new char[xmldata.size() + 1];
		strcpy(cstr, xmldata.c_str());

		//Parse the XML Data
		printf("[REF] -- Generating Reference Birthmark\n");
		xmldoc.parse<0>(cstr);
		xml_node<>* cktNode= xmldoc.first_node();
		Birthmark* refBirthmark = new Birthmark();
		refBirthmark->importXML(cktNode);

		timeval start_time, end_time;

		gettimeofday(&start_time, NULL); //----------------------------------
		db->t_CurLine = lineNumber;
		db->searchDatabase(refBirthmark, kFlag, printall);

		if(lineNumber != -1){
			printf("[RSEARCH] -- Current line number given. Searching for future op\n");
			db->processKGramDatabase();
			db->getFutureOp(refBirthmark);
		}
		delete refBirthmark;
		gettimeofday(&end_time, NULL); //----------------------------------

		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
	}
	catch(cException e){
		printf("%s", e.what());
	}
	catch(TCLAP::ArgException &e){
		std::cerr<< "Argument Error: " << e.error() <<" for arg " << e.argId() <<std::endl;
	}
	/*
	catch(ArgException e){
		if(argc == 1){
			printf("\n  rsearch\n");
			printf("  ================================================================================\n");

			printf("    This program reads in a verilog file as well as a XMLdatabase files\n");
			printf("    It preprocesses the verilog file and extracts the birthmark\n");
			printf("    Compares the reference birthmark to the birthmarks in the database\n");
			printf("    Outputs a ranked list showing the circuits that are similar to the reference\n");

			printf("\n  Usage: ./rsearch  [Verilog file]  [XML Database] [OPTIONAL: a (prints all results)]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("\n  Usage: ./rsearch  [Verilog file]  [XML Database] [OPTIONAL: a (prints all results)]\n\n");
		}
	}
	*/

	if(db != NULL) delete db;
	return 0;
}

#endif
