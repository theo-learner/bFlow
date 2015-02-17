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
	enum Error{
		eCLIENT_READY,
	};

int main( int argc, char *argv[] ){
	if(argc != 2){
		printf("./server <port number>\n\n\n");
		return 0;
	}
	
	//**************************************************************************
	//* MKR- CONECTING WITH FRONT END
	//**************************************************************************
	Database* db = new Database();
	try{
		Server* server = new Server((unsigned)db->string2int(argv[1]));
		if(!server->waitForClient()) return 0;

		std::string ready = server->receiveAllData();

		if(ready != "CLIENT_READY") throw eCLIENT_READY;
		if(!server->sendData("SERVER_READY")) throw ServerSendException();


		while(1){
		}

	}
	catch(ServerSendException e){
		printf("%s", e.what());
	}
	catch(Error e){
		if(e == eCLIENT_READY)
			printf("[ERROR] -- CLient did not send RDY Signal\n");
	}























	return 0;
}

#endif
