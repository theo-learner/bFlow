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

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"
using namespace rapidxml;


int main( int argc, char *argv[] ){

	try{
		//Check arguments : Verilog File, XML Database File
		if(argc != 5) throw ArgException();

		std::string circuit1= argv[1];
		std::string circuit2= argv[2];
		std::string kval = argv[3];
		std::string opt = argv[4];


		//set opt flags
		Optmode opt1 = eOpt_No_Clean;
		Optmode opt2 = eOpt_No_Clean;
		if(opt == "1") opt2 = eOpt;
		else if(opt == "2") opt1 = eOpt;
		else if(opt == "3"){
			opt1 = eOpt; 
			opt2 = eOpt;
		} 

		Birthmark* birthmark1 = extractBirthmark(circuit1, kval, false,  opt1);
		Birthmark* birthmark2= extractBirthmark(circuit2, kval, false,  opt2);


		//########################################################################
		// Compare Two Birthmarks
		//########################################################################
		timeval start_time, end_time;
		gettimeofday(&start_time, NULL); //----------------------------------
		Database* db = new Database();
		db->compareBirthmark(birthmark1, birthmark2);
		gettimeofday(&end_time, NULL); //----------------------------------

		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
		
		delete db;
		delete birthmark1;
		delete birthmark2;
	}
	catch(cException e){
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

			printf("\n  Usage: ./compareAST [Verilog 1]  [Verilog 2] [K] [OPT]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("\n  Usage: ./compareAST [Verilog 1]  [Verilog 2] [K] [OPT]\n\n");
		}
	}

	return 0;
}

#endif
