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

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"
using namespace rapidxml;

int main( int argc, char *argv[] ){
	Database* db = NULL;
	Server* server = NULL;

	try{
		if(argc != 3) throw ArgException();

		//Read the xml database in
		std::string xmlFile = argv[2];
		unsigned port = (unsigned)s2i::string2int(argv[1]);
		db = new Database(xmlFile);

		//Start up the server
		server = new Server(port);
		server->waitForClient();
		
		//INITIAL HANDSHAKE
		printf(" -- Performing initial handshake\n" );
		std::string ready = server->receiveAllData();
		if(ready != "CLIENT_READY") throw Exception("(main:T1) Client ready signal not returned\n");
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

			db->searchDatabase(refBirthmark);


			delete refBirthmark;
			server->sendData("SERVER_READY");
		}
		
		server->closeSocket();
	}
	catch(Exception e){
		printf("%s", e.what());
	}
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

	
	if(db != NULL) delete db;
	if(server != NULL) delete server;

	return 0;
}

#endif
