/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @
  @  MAINREF.cpp
  @  
  @  @AUTHOR:Kevin Zeng
  @  Copyright 2012 – 2013 
  @  Virginia Polytechnic Institute and State University
  @
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
using namespace rapidxml;



int main( int argc, char *argv[] ){
	enum Error{
		eARGS,
		eBIRTHMARK,
		eCLIENT_READY
	};

	Database* db = NULL;
	Server* server = NULL;

	try{
		if(argc != 3) throw eARGS;



		//**************************************************************************
		//* MKR- CONECTING WITH FRONT END
		//**************************************************************************
		std::string xmlFile = argv[2];
		unsigned port = (unsigned)s2i::string2int(argv[1]);
		db = new Database(xmlFile);
		server = new Server(port);
		server->waitForClient();
		

		//INITIAL HANDSHAKE
		printf(" -- Performing initial handshake\n" );
		std::string ready = server->receiveAllData();
		if(ready != "CLIENT_READY") throw eCLIENT_READY;
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
			if(!refBirthmark->importXML(cktNode)) throw eBIRTHMARK;

			//refBirthmark->print(); 
			db->searchDatabase(refBirthmark);


			delete refBirthmark;
			server->sendData("SERVER_READY");
		}
		
		server->closeSocket();
	}
	catch(ServerException e){
		printf("%s", e.what());
	}
	catch(int e){
		switch(e){
			case eCLIENT_READY: 	
				printf("Error\n[ERROR] -- Client did not send RDY Signal\n");
			case eARGS:  
				printf("[ERROR] -- Invalid Arguments\n\t./server <port number> <XML Database File>\n\n");
			case eBIRTHMARK:  
				printf("[ERROR] -- Invalid Arguments\n\t./server <port number> <XML Database File>\n\n\n");
			default:
				printf("[ERROR] -- Exception occured\n"); 
		}
	}
	
	if(db != NULL) delete db;
	if(server != NULL) delete server;























	return 0;
}

#endif
