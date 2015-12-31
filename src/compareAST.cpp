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
#include "tclap/CmdLine.h"
using namespace rapidxml;


int main( int argc, char *argv[] ){

	try{
		TCLAP::CmdLine cmdline("This program reads in a verilog file as well as a XMLdatabase files. It preprocesses the verilog file and extracts the birthmark. Compares the reference birthmark to the birthmarks in the database. Outputs a ranked list showing the circuits that are similar to the reference", ' ', "0.0");

		//Reference
		TCLAP::ValueArg<std::string> circuit1Arg("1", "circuit1", "First circuit", true, "", "ckt1");
		cmdline.add(circuit1Arg);
		
		//Database XML
		TCLAP::ValueArg<std::string> circuit2Arg("2", "circuit2", "Second circuit", true, "", "ckt2");
		cmdline.add(circuit2Arg);
		
		//K 
		TCLAP::ValueArg<std::string > kArg("k", "kval", "size of kgram", true, "5", "K");
		cmdline.add(kArg);
		
		//opt code
		TCLAP::ValueArg<int> optArg("O", "optimize", "0- no opt; 1- opt2; 2- opt1; 3- optimize both circuit", false, 3, "opt");
		cmdline.add(optArg);

		//Print all ranking switch
		TCLAP::SwitchArg strictArg("s", "strict", "Use stricter search constraints", cmdline, false);
		TCLAP::SwitchArg partialArg("p", "partial", "Sets partial matching during kgram match", cmdline, false);

		cmdline.parse(argc, argv);


		std::string circuit1= circuit1Arg.getValue();
		std::string circuit2= circuit2Arg.getValue();
		std::string kval = kArg.getValue();
		bool strict = strictArg.getValue();
		bool partialFlag = partialArg.getValue();
		int opt = optArg.getValue();


		//set opt flags
		Optmode opt1 = eOpt_NoClean;
		Optmode opt2 = eOpt_NoClean;
		if(opt == 1) opt2 = eOpt;
		else if(opt == 2) opt1 = eOpt;
		else if(opt == 3){
			opt1 = eOpt; 
			opt2 = eOpt;
		} 

		Birthmark* birthmark1 = extractBirthmark(circuit1, kval, false, strict,  opt1);
		Birthmark* birthmark2= extractBirthmark(circuit2, kval, false,  strict, opt2);
		birthmark1->print();
		birthmark2->print();


		//########################################################################
		// Compare Two Birthmarks
		//########################################################################
		timeval start_time, end_time;
		gettimeofday(&start_time, NULL); //----------------------------------
		Database* db = new Database();
		db->m_Settings->partialMatch = partialFlag;
		db->m_Settings->allsim= true;

		db->compareBirthmark(birthmark1, birthmark2);
		printf("KGram1: %6d\tKGram2: %6d\n", birthmark1->getKGramListSize(), birthmark2->getKGramListSize());
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
	catch(TCLAP::ArgException &e){
		std::cerr<<"Argument Error: " << e.error() << " for arg " << e.argId() <<std::endl;
	}

	return 0;
}

#endif
