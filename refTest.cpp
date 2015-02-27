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
#include "database.hpp"
#include "error.hpp"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"
using namespace rapidxml;



int main( int argc, char *argv[] ){
	enum Error{
		eARGS,
		eBIRTHMARK,
		eCLIENT_READY,
		eFILE
	};

	Database* db = NULL;
	try{
		if(argc != 3) throw eARGS;



		//**************************************************************************
		//* MKR- CONECTING WITH FRONT END
		//**************************************************************************
		std::string xmlDB= argv[2];
		std::string vREF= argv[1];
		db = new Database(xmlDB);

	
		//Read in contents in the XML File
		printf("Processing verilog file\n");
		std::string cmd = "python processRef.py " + vREF; 
		system(cmd.c_str());
	
		int lastSlashIndex = vREF.find_last_of("/") + 1;
		if(lastSlashIndex == -1) lastSlashIndex = 0;

		int lastDotIndex= vREF.find_last_of(".");
		std::string xmlREF = "." +  vREF.substr(lastSlashIndex, lastDotIndex-lastSlashIndex) + ".xml";

		printf("Opening xml file\n");
		std::string xmldata= "";
		std::string xmlline;
		std::ifstream refStream;
		refStream.open(xmlREF.c_str());
		if (!refStream.is_open()) throw eFILE;
		while(getline(refStream, xmlline))
			xmldata+= xmlline + "\n";

		xml_document<> xmldoc;
		char* cstr = new char[xmldata.size() + 1];
		strcpy(cstr, xmldata.c_str());

		//Parse the XML Data
		xmldoc.parse<0>(cstr);
		xml_node<>* cktNode= xmldoc.first_node();
		Birthmark* refBirthmark = new Birthmark();
		if(!refBirthmark->importXML(cktNode)) throw eBIRTHMARK;

		//refBirthmark->print(); 
		std::vector<double> fsim;
		db->searchDatabase(refBirthmark, fsim);
		for(unsigned int i = 0; i < fsim.size(); i++)
			printf("fSIM C%3d: %f\n", i, fsim[i]);


		delete refBirthmark;
		
	}
	catch(int e){
		switch(e){
			case eCLIENT_READY: 	
				printf("Error\n[ERROR] -- Client did not send RDY Signal\n");
			case eARGS:  
				printf("[ERROR] -- Invalid Arguments\n\t./server <port number> <XML Database File>\n\n");
			case eFILE:  
				printf("[ERROR] -- Cannot open file for importing\n\n");
			case eBIRTHMARK:  
				printf("[ERROR] -- Invalid Arguments\n\t./server <port number> <XML Database File>\n\n\n");
			default:
				printf("[ERROR] -- Exception occured\n"); 
		}
	}
	
	if(db != NULL) delete db;


	return 0;
}

#endif
