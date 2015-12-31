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
		TCLAP::SwitchArg printAllResultArg("v", "verbose", "Print detailed results", cmdline, false);
		TCLAP::SwitchArg optimizeArg("O", "optimize", "Optimize the reference circuit", cmdline, false);
		TCLAP::SwitchArg strictArg("s", "strict", "Use stricter search constraints", cmdline, false);
		TCLAP::SwitchArg trustArg("t", "trust", "Trust mode: only use kgram info", cmdline, false);
		TCLAP::SwitchArg allArg("a", "all", "Does all the kgram comparison. Rank based on kflag", cmdline, false);
		TCLAP::SwitchArg partialArg("p", "parital", "Partial Kgram matching", cmdline, false);
		TCLAP::SwitchArg invertedArg("i", "inverted", "Performed search using inverted index", cmdline, false);


		cmdline.parse(argc, argv);

		std::string xmlDB= databaseArg.getValue();
		std::string referenceFile = referenceArg.getValue();
		bool printallresult = printAllResultArg.getValue();
		bool strictFlag = strictArg.getValue();
		bool trustFlag = trustArg.getValue();
		bool allFlag = allArg.getValue();
		bool partialFlag = partialArg.getValue();
    bool invertedFlag = invertedArg.getValue();
		std::string kFlag = kArg.getValue();
		int lineNumber= lineArg.getValue();

		Optmode optMode;
		if(optimizeArg.getValue())
			optMode = eOpt;
		else
			optMode = eOpt_NoClean;
		
		
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
		if(!trustFlag){
			SearchType searchType = ePredict;
			//SearchType searchType = eSimilarity;
			db = new Database(xmlDB, searchType);
		}
		else{
			SearchType searchType = eTrust;
			db = new Database(xmlDB, searchType);
		}

		//Settings
		db->m_Settings->kgramSimilarity = kFlag;
		db->m_Settings->show_all_result = printallresult;
		db->m_Settings->allsim= allFlag;
		db->m_Settings->partialMatch= partialFlag;
    db->invertDatabase();

		//Extract birthmark of reference circuit
		Birthmark* refBirthmark = extractBirthmark(referenceFile, db->getKVal(), lineNumber!=-1,  strictFlag, optMode);


		timeval start_time, end_time;
		gettimeofday(&start_time, NULL); //----------------------------------
		db->t_CurLine = lineNumber;

    if(invertedFlag && kFlag[0] == 'K')
		  db->searchIDatabase(refBirthmark);
    else
		  db->searchDatabase(refBirthmark);

		if(lineNumber != -1){
			printf("\n[RSEARCH] -- Current line number given. Searching for future operation\n");
			printf("\n[RSEARCH] -- Preprocessing kGram database\n");
			db->processKGramDatabase();
			printf("\n[RSEARCH] -- Retrieving future operation\n");
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
