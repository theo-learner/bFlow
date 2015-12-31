/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @  cserver.cpp
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

//Server Includes
#include "similarity.hpp"
#include "server.hpp"
#include "database.hpp"
#include "error.hpp"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"
#include "tclap/CmdLine.h"

using namespace rapidxml;
using namespace TCLAP;

int main( int argc, char *argv[] ){
	Database* db = NULL;
	Server* server = NULL;

	try{
		TCLAP::CmdLine cmdline("This program acts as a central server for comparing circuits. XML Database file is read in and waits for a client to connect. Client sends over the birthmark of the circuit in XML format. Server searches for circuits in the database similar to the reference", ' ', "0.0");
			

		//Database XML
		TCLAP::ValueArg<std::string> databaseArg("x", "database", "Database XML file", true, "", "XML");
		cmdline.add(databaseArg);
		
		//KFlag XML
		TCLAP::ValueArg<std::string> kArg("k", "kflag", "KLC, KLR, KSC, KSR, KFC, KFR", false, "BIRTHMARK", "FLAG");
		cmdline.add(kArg);
		
		//Port Number
		TCLAP::ValueArg<int> portArg("n", "port", "Port number to connect to", true, 8001, "PORT");
		cmdline.add(portArg);
		
		//Print all ranking switch
		TCLAP::SwitchArg printAllResultArg("v", "verbose", "Print detailed results", cmdline, false);
		TCLAP::SwitchArg optimizeArg("O", "optimize", "Optimize the reference circuit", cmdline, false);
		TCLAP::SwitchArg strictArg("s", "strict", "Use stricter search constraints", cmdline, false);
		TCLAP::SwitchArg allArg("a", "all", "Does all the kgram comparison. Rank based on kflag", cmdline, false);
		TCLAP::SwitchArg partialArg("p", "partial", "Partial Kgram matching", cmdline, false);


		cmdline.parse(argc, argv);

		//Read the xml database in
		unsigned port = portArg.getValue();
		std::string xmlDB= databaseArg.getValue();
		bool printallresult = printAllResultArg.getValue();
		bool strictFlag = strictArg.getValue();
		bool allFlag = allArg.getValue();
		bool partialFlag = partialArg.getValue();
		std::string kFlag = kArg.getValue();


		//Need to pass in current line number
		//int lineNumber= lineArg.getValue();

		SearchType sType = ePredict;
		db = new Database(xmlDB, sType);

		//Settings
		db->m_Settings->kgramSimilarity = kFlag;
		db->m_Settings->show_all_result = printallresult;
		db->m_Settings->allsim= allFlag;
		db->m_Settings->partialMatch= partialFlag;

		//Start up the server
		server = new Server(port);
		server->waitForClient();
		
		//INITIAL HANDSHAKE
		printf(" -- Performing initial handshake\n" );
		std::string ready = server->receiveAllData();
		if(ready != "CLIENT_READY") throw cException("(main:T1) Client ready signal not returned\n");
		server->sendData("SERVER_READY");
		printf(" -- Server is ready and running!\n\n");

		while(1){
			printf(" -- Waiting for reference birthmark...\n");
			std::string xmldata = server->receiveAllData();

			xml_document<> xmldoc;
			char* cstr = new char[xmldata.size() + 1];
			strcpy(cstr, xmldata.c_str());

			//Parse the XML Data
			xmldoc.parse<0>(cstr);
			xml_node<>* cktNode= xmldoc.first_node();
			Birthmark* refBirthmark = new Birthmark();
			refBirthmark->importXML(cktNode);

			sResult* result = db->searchDatabase(refBirthmark);

			printf(" -- Sending result to monitor\n");
			server->sendData("Resemblance:\n" + result->ranked_result_r + "\n\nContainment:\n" + result->ranked_result_c);
			delete refBirthmark;
			delete result;
		}
		
		server->closeSocket();
	}
	catch(cException e){
		printf("%s", e.what());
	}
	/*
	catch(ArgException e){
		if(argc == 1){
			printf("\n  cserver\n");
			printf("  ================================================================================\n");

			printf("    This program acts as a central server for comparing circuits\n");
			printf("    XML Database file is read in and waits for a client to connect\n");
			printf("    Client sends over the birthmark of the circuit in XML format\n");
			printf("    Server searches for circuits in the database similar to the reference\n\n"); //TODO: Verilog Circuit

			printf("\n  Usage: ./cserver [XML Database] [Port number]\n\n");
		}
		else{
			printf("%s", e.what());
			printf(" -- Usage: ./cserver [XML Database] [Port number]\n\n");
		}
	}
	*/

	
	if(db != NULL) delete db;
	if(server != NULL) delete server;

	return 0;
}

#endif
