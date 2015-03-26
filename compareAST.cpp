/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @  compareAST.cpp
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

		std::string dotfile2= argv[2];
		std::string dotfile1= argv[1];


		//########################################################################
		//Process first ast
		//########################################################################
		printf("[REF] -- Reading AST 1\n");
		std::string cmd = "python scripts/processAST.py " + dotfile1; 
		system(cmd.c_str());
		std::string xmlREF = "data/reference.xml";
		std::string xmldata= "";
		std::string xmlline;
		std::ifstream refStream;
		refStream.open(xmlREF.c_str());
		if (!refStream.is_open()) throw Exception("(MAIN:T1) Cannot open file: " + xmlREF);
		while(getline(refStream, xmlline))
			xmldata+= xmlline + "\n";
		refStream.close();

		//Parse the XML Data
		xml_document<> xmldoc;
		char* cstr = new char[xmldata.size() + 1];
		strcpy(cstr, xmldata.c_str());

		printf("[REF] -- Generating AST1 Birthmark\n");
		xmldoc.parse<0>(cstr);
		xml_node<>* cktNode= xmldoc.first_node();
		Birthmark* birthmark1 = new Birthmark();
		birthmark1->importXML(cktNode);
		delete cstr;

		//########################################################################
		//Process second ast
		//########################################################################
		cmd = "python scripts/processAST.py " + dotfile2; 
		system(cmd.c_str());
		xmldata= "";
		refStream.open(xmlREF.c_str());
		if (!refStream.is_open()) throw Exception("(MAIN:T0) Cannot open file: " + xmlREF);
		while(getline(refStream, xmlline))
			xmldata+= xmlline + "\n";
		refStream.close();
		
		cstr = new char[xmldata.size() + 1];
		strcpy(cstr, xmldata.c_str());

		printf("[REF] -- Generating AST2 Birthmark\n");
		xmldoc.parse<0>(cstr);
		cktNode = xmldoc.first_node();
		Birthmark* birthmark2 = new Birthmark();
		birthmark2->importXML(cktNode);
		delete cstr;



		//########################################################################
		// Compare Two Birthmarks
		//########################################################################
		timeval start_time, end_time;
		gettimeofday(&start_time, NULL); //----------------------------------
		db = new Database();
		db->compareBirthmark(birthmark1, birthmark2);
		gettimeofday(&end_time, NULL); //----------------------------------
		delete birthmark1;
		delete birthmark2;

		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
	}
	catch(Exception e){
		printf("%s", e.what());
	}
	catch(ArgException e){
		if(argc == 1){
			printf("\n  compareAST\n");
			printf("  ================================================================================\n");

			printf("    This program reads in two DOT file representing ast of two designs\n");
			printf("    It preprocesses the ast and extracts the birthmark\n");
			printf("    Compares the two  birthmark \n");
			printf("    Outputs comparison results\n");

			printf("\n  Usage: ./compareAST [DOT file 1]  [DOT file 2]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("\n  Usage: ./compareAST [DOT file 1]  [DOT file 2]\n\n");
		}
	}

	if(db != NULL) delete db;
	return 0;
}

#endif
