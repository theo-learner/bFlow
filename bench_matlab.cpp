/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  bench_db.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include <assert.h>
#include <map>
#include <set>
#include <list>

#include "similarity.hpp"
#include "print.hpp"
#include "database.hpp"
#include "error.hpp"

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"
using namespace rapidxml;


int main(int argc, char** argv){
	Database* db = NULL;

	try{
		//Check arguments : XML Database File
		if(argc != 2 && argc != 3) throw ArgException();
		std::string xmlDB= argv[1];

		//Read Database
		printf("[BENCH_MAT] -- Reading Database\n");
		db = new Database(xmlDB);


		//Classification file is provided. Create labels for circuit
		if(argc == 3)	{
			printf("[BENCH_MAT] -- Creating labels\n");

			//Prepare classification labeling
			std::ifstream ifs;
			std::string labelFile = argv[2];
			ifs.open(labelFile.c_str());
			if(!ifs.is_open()) throw cException("(MAIN) Cannot open label file");

			int labelCount;
			ifs>>labelCount;    //Get number of labels

			std::stringstream ls;
			int totalLabels = 0;;

			for(int i = 0; i < labelCount; i++){
				std::string dummy;
				int labelValue;
				ifs>>labelValue;
				ifs>>dummy;

				totalLabels+=labelValue;
				for(int k = 0; k < labelValue; k++)
					ls<<i+1<<",";
			}

			if((int)db->getSize() != totalLabels){
				printf("[WARNING] -- Number of labels and number of circuits do not match\n");
				printf("          -- Number of CKT: %4d\tNumber of Labels: %4d\n", (int)db->getSize(), totalLabels);
				throw cException("(MAIN) Labels don't match");
			}
			else{
				std::ofstream ofs;
				ofs.open("data/labels.csv");
				ofs<<ls.str().substr(0, ls.str().size()-1);  //Remove the last comma
				ofs.close();
				printf(" -- Outputting label table to labels.csv\n");

			}
		}
		else
			printf("[BENCH_MAT] -- Classification file is not provided...skipping\n");


		//SET UP THE VECTOR TABLE for fingerprint //Vec of each circuit, vec of each fingerprint, vec of the count
		//number of circuits,      13 types:add..       index = size, val = count 
		std::vector<std::vector<int> >ftable;
		ftable.reserve(db->getSize());
		int numSubcomponents = db->getBirthmark(0)->getNumFPSubcomponents();
		for(unsigned int i = 0; i < db->getSize(); i++){
			std::vector<int> fVector;
			fVector.reserve(numSubcomponents);
			ftable.push_back(fVector);
		}

		for(unsigned int cIndex = 0; cIndex < db->getSize(); cIndex++){
			std::map<std::string, unsigned> fpDatabase;
			std::map<std::string, unsigned>::iterator iFP;
			db->getBirthmark(cIndex)->getFingerprint(fpDatabase);

			//printf(" CKT: %d* Number of features: %d\n",cIndex+1, (int)iFP->second.size());
			for(iFP = fpDatabase.begin(); iFP != fpDatabase.end(); iFP++){
				//printf(" * *  INDEXES: %d %d\n", cIndex, q);
					ftable[cIndex].push_back(iFP->second);	
			}
		}




		//POPULATE THE VECTOR TABLE with constant data
		std::vector<std::vector<unsigned> > ctable;
		ctable.reserve(db->getSize());

		for(unsigned int cIndex = 0; cIndex < db->getSize(); cIndex++){
			std::vector<unsigned> binnedConstVector;
			db->getBirthmark(cIndex)->getBinnedConstants(binnedConstVector);
			ctable.push_back(binnedConstVector);
		}


		std::stringstream statstream;
		for(unsigned int cIndex = 0; cIndex < db->getSize(); cIndex++){
			std::string statstr = db->getBirthmark(cIndex)->getStatstr();
			statstream<<statstr<<"\n";
		}





		std::stringstream scstream;
		std::stringstream cstream;
		std::stringstream sstream;

		//printf("LabelCount: %d\tFTABLE: %d\n", labelCount, (int)ftable.size());
		for(unsigned int q = 0; q < ftable.size(); q++){

			//STRUCTURAL
			std::stringstream ss;
			for(unsigned int w = 0; w < ftable[q].size(); w++)
					ss<<ftable[q][w]<<",";

			//CONSTANT
			std::stringstream cs;
			for(unsigned int w = 0; w < ctable[q].size(); w++)
				cs<<ctable[q][w]<<",";


			std::string cstr = cs.str();
			std::string sstr = ss.str();

			cstr = cstr.substr(0, cstr.size()-1);  //Remove the last comma
			sstr = sstr.substr(0, sstr.size()-1);  //Remove the last comma

			scstream<<sstr<<","<<cstr<<"\n";
			cstream<<cstr<<"\n";
			sstream<<sstr<<"\n";

		}





		std::ofstream ofs;
		printf(" -- Outputing fixed length fingerprint table to sTable.csv\n");
		ofs.open("data/sTable.csv");
		ofs<< sstream.str();
		ofs.close();

		printf(" -- Outputing fixed length binned constant table to cTable.csv\n");
		ofs.open("data/cTable.csv");
		ofs<< cstream.str();
		ofs.close();

		printf(" -- Outputing fixed length structural and constant to scTable.csv\n");
		ofs.open("data/scTable.csv");
		ofs<< scstream.str();
		ofs.close();

		printf(" -- Outputing additional structural statistics to stat.csv\n");
		ofs.open("data/stat.csv");
		ofs<< statstream.str();
		ofs.close();


		printf("------------------------------------------------------------\n");
		printf(" -- COMPLETE!\n");
	}
	catch(cException e){
		printf("%s", e.what());
	}
	catch(ArgException e){
		if(argc == 1){
			printf("\n  bench_matlab\n");
			printf("  ============================================================================\n");

			printf("    This program reads in a database files and performs data extraction\n");
			printf("    Most of data is stored in .csv files so it can be analyzed in Matlab \n");

			printf("\n  Usage: ./bench_matlab [XML Database] [Classification labels]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("  Usage: ./bench_matlab [XML Database] [Classification labels]\n\n");
		}
	}

	if(db != NULL) delete db;
	return 0;
}



