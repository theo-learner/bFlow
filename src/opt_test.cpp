/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  opt_test.cpp
	@   Tests to see if the top result is the unoptimized version of the circuit
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
		TCLAP::ValueArg<std::string> databaseArg("d", "database", "Processed Database file (XML)", true, "", "XML");
		cmdline.add(databaseArg);

		//Database XML
		TCLAP::ValueArg<std::string> circuitListArg("c", "circuits", "File that contains circuits to process", true, "", "DB");
		cmdline.add(circuitListArg);

		//Database XML
		TCLAP::ValueArg<std::string> kArg("k", "kflag", "KLC, KLR, KSC, KSR, KFC, KFR", false, "KLR", "FLAG");
		cmdline.add(kArg);

		//Print all ranking switch
		TCLAP::SwitchArg printAllArg("v", "verbose", "Print detailed results", cmdline, false);
		
		TCLAP::SwitchArg allArg("a", "all", "Does all the kgram comparison. Rank based on kflag", cmdline, false);

		//TCLAP::SwitchArg optimizeArg("O", "optimize", "Optimize the reference circuit", cmdline, false);


		cmdline.parse(argc, argv);

		std::string xmlDB= databaseArg.getValue();
		std::string database_file= circuitListArg.getValue();
		bool printallresult = printAllArg.getValue();
		bool allFlag = allArg.getValue();
		//bool optimize = optimizeArg.getValue();
		std::string kFlag = kArg.getValue();

		printf("########################################################################\n");
		printf("[*] -- Begin HOST circuit optimization similarity testing...\n");
		printf("########################################################################\n");

		//Read Database
		printf("[*] -- Reading Database\n");
		SearchType searchtype = eTrust;       //Set the search to "trust" so that containment goes both ways
		db = new Database(xmlDB, searchtype);

		//Settings
		db->m_Settings->kgramSimilarity = kFlag;
		db->m_Settings->show_all_result = printallresult;
		db->m_Settings->allsim= allFlag;
		db->suppressOutput();

		db->t_CurLine = -1;


		//File stream for reading circuit list
		printf("[*] -- Reading circuit list\n");
		std::ifstream circuitStream;
		circuitStream.open(database_file.c_str());
		if (!circuitStream.is_open()) throw cException("(opt_test:T2) Cannot open file: " + database_file);




		//Run test to see how similar the unoptimized is to the optimized
		timeval start_time, end_time;
		gettimeofday(&start_time, NULL); //----------------------------------
		int totalCircuit = 0;
		int topCircuitCount = 0;
		std::string circuit_name;
		std::map<std::string, sResult*> foundList; //circuit name, top circuit that was returned
		while(getline(circuitStream, circuit_name)){
			printf( "\n\n===================================================================\n");
			printf( "[%3d] -- Extracting birthmark from verilog file: %s\n", totalCircuit, circuit_name.c_str());
			printf( "===================================================================\n");

			//Extract birthmark of reference circuit
			Birthmark* birthmark = extractBirthmark(circuit_name, db->getKVal(), false, true,  eOpt);//eNoOpt_Clean);

			printf(" - Searching database for top circuit\n");
			sResult* result = db->searchDatabase(birthmark);
			foundList[circuit_name] = result;

			totalCircuit++;
			delete birthmark;
		}
		gettimeofday(&end_time, NULL); //----------------------------------





		FILE* ofs;
		ofs = fopen("data/host_test1.out", "w");
		double maxScoreNext = 0.0;
		double minScoreNext = 200.0;
		double sumScore2 = 0.0;

		printf( "[*] -- Finished processing circuits\n");
		std::map<std::string, sResult*>::iterator iMap; //circuit name, top circuit that was returned
		for(iMap = foundList.begin(); iMap != foundList.end(); iMap++){
			printf("-----------------------------------------------------------------------------\n");
			printf("%s:\n", iMap->first.c_str());
			bool found = false;
			if(iMap->second->topMatch.size() > 0){
				for(unsigned int i = 0; i < iMap->second->topMatch.size(); i++){
					printf("\033[1;32m    %5.2f : %s\033[0m\n", iMap->second->topScore[i], iMap->second->topMatch[i].c_str());
				}
				found = true;
			}

			if(iMap->second->okayMatch.size() > 0){
				for(unsigned int i = 0; i < iMap->second->okayMatch.size(); i++){
					printf("\033[1;33m    %5.2f : %s\033[0m\n", iMap->second->okayScore[i], iMap->second->okayMatch[i].c_str());
				}
				found = true;
			}

			if(!found){
				  printf("\033[1;31m    NO designs have been found to match reference\033[0m\n");
			}

			printf("  Next Top: %s -- %7.4f\n", iMap->second->topNextCircuit.c_str(), iMap->second->topNext);


			if(iMap->second->topNext > maxScoreNext){
				maxScoreNext = iMap->second->topNext;
			}
			else if(iMap->second->topNext < minScoreNext) {
				minScoreNext = iMap->second->topNext;
			}

			sumScore2 += iMap->second->topNext;
		}


		printf(" -- Max Score2: %f\n", maxScoreNext);
		printf(" -- Min Score2: %f\n", minScoreNext);
		printf(" -- AVG Score2: %f\n\n", sumScore2/(double) totalCircuit);

		fprintf(ofs, " -- Total Match   : %d\n", topCircuitCount);
		fprintf(ofs, " -- Total Circuits: %d\n", totalCircuit);
		fprintf(ofs, " -- Naive Accuracy: %f\n", ((double)topCircuitCount/(double)totalCircuit));
		fclose(ofs);






		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[TIME] -- : %f\n", elapsedTime/1000.0);
		printf("[*] -- COMPLETE!!\n");

		//Cleanup: Release Memory
		for(iMap = foundList.begin(); iMap != foundList.end(); iMap++)
			delete iMap->second;
	}
	catch(cException e){
		printf("%s", e.what());
	}
	catch(TCLAP::ArgException &e){
		std::cerr<< "Argument Error: " << e.error() <<" for arg " << e.argId() <<std::endl;
	}

	if(db != NULL) delete db;
	return 0;
}

#endif
