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

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"
using namespace rapidxml;


int main( int argc, char *argv[] ){
	Database* db = NULL;

	try{
		//Check arguments : Verilog File, XML Database File
		if(argc != 3) throw ArgException();

		std::string xmlDB= argv[2];
		std::string vREF= argv[1];

		//Read Database
		printf("[REF] -- Reading Database\n");
		db = new Database(xmlDB);

		//Extract the birthmark from the verilog
		printf("[REF] -- Reading Reference Design\n");
		std::string cmd = "python scripts/processVerilog.py " + vREF; 
		system(cmd.c_str());

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
		db->searchDatabase(refBirthmark);
		delete refBirthmark;
		gettimeofday(&end_time, NULL); //----------------------------------

		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
	}
	catch(cException e){
		printf("%s", e.what());
	}
	catch(ArgException e){
		if(argc == 1){
			printf("\n  rsearch\n");
			printf("  ================================================================================\n");

			printf("    This program reads in a verilog file as well as a XMLdatabase files\n");
			printf("    It preprocesses the verilog file and extracts the birthmark\n");
			printf("    Compares the reference birthmark to the birthmarks in the database\n");
			printf("    Outputs a ranked list showing the circuits that are similar to the reference\n");

			printf("\n  Usage: ./rsearch  [Verilog file]  [XML Database]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("\n  Usage: ./rsearch  [Verilog file]  [XML Database]\n\n");
		}
	}

	if(db != NULL) delete db;
	return 0;
}

#endif
