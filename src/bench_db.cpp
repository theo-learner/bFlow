/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @  bench_db.cpp
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
	Database* db = NULL;

	try{
		//Check arguments : XML Database File
		if(argc != 2) throw ArgException();
		std::string xmlDB= argv[1];

		//Read Database
		printf("[BENCH_DB] -- Reading Database\n");
		//SearchType searchtype = eTrust;       //Set the search to "trust" so that containment goes both ways
		//db = new Database(xmlDB, searchtype);
		db = new Database(xmlDB);
		db->suppressOutput();
		db->m_Settings->kgramSimilarity = "KFR";
		db->m_Settings->allsim= true;
		db->m_Settings->partialMatch = false;
    db->invertDatabase();
		
		timeval start_time, end_time;
		timeval start_search, end_search;
		std::ofstream ofs;
		std::ofstream ofs2;
		std::ofstream ofsi;
		std::ofstream ofsq;
		ofs.open("data/c2DB_Time.dat");
		ofsi.open("data/c2DB_qTime_inverted.dat");
		ofsq.open("data/c2DB_qTime.dat");
		ofs2.open("data/avgSeqLength.dat");


		//Time how long it takes for each circuit in the database to complete a circuit across the database
		//std::ofstream fastaout;
		//fastaout.open("data/dataflow.fasta");

		gettimeofday(&start_time, NULL);
		printf("[BENCH_DB] -- Performing single pass through database vs database\n");
		for(unsigned int i = 0; i < db->getSize(); i++){
			printf("[BENCH_DB] -- Reference Circuit: %s\n", db->getBirthmark(i)->getName().c_str());
      //Functional
      printf("Functional Search\n");
		  db->m_Settings->kgramSimilarity = "FUNC";
			gettimeofday(&start_search, NULL); 
			db->searchDatabase(db->getBirthmark(i));
			gettimeofday(&end_search, NULL);

			double elapsedTime = (end_search.tv_sec - start_search.tv_sec) * 1000.0;
			elapsedTime += (end_search.tv_usec - start_search.tv_usec) / 1000.0;
			ofs<<elapsedTime/1000.0<<"\n";
			ofs2<<db->getBirthmark(i)->getAvgSequenceLength()<<"\n";
      printf("ELAPSED: %f\n", elapsedTime/1000.0);
			
      //qgram
      printf("Qgram Linear Search\n");
		  db->m_Settings->kgramSimilarity = "KFR";
      gettimeofday(&start_search, NULL); 
			db->searchDatabase(db->getBirthmark(i));
			gettimeofday(&end_search, NULL);

			elapsedTime = (end_search.tv_sec - start_search.tv_sec) * 1000.0;
			elapsedTime += (end_search.tv_usec - start_search.tv_usec) / 1000.0;
			ofsq<<elapsedTime/1000.0<<"\n";
      printf("ELAPSED: %f\n", elapsedTime/1000.0);

      //Inverted qgram
      printf("Qgram inverted Search\n");
      gettimeofday(&start_search, NULL); 
			db->searchIDatabase(db->getBirthmark(i));
			gettimeofday(&end_search, NULL);

			elapsedTime = (end_search.tv_sec - start_search.tv_sec) * 1000.0;
			elapsedTime += (end_search.tv_usec - start_search.tv_usec) / 1000.0;
			ofsi<<elapsedTime/1000.0<<"\n";
      printf("ELAPSED: %f\n", elapsedTime/1000.0);

			printf("[BENCH_DB] --  * Elapsed search time: %f\n\n", elapsedTime/1000.0);
		}

		ofs.close();
		ofsi.close();
		ofsq.close();
		ofs2.close();
		gettimeofday(&end_time, NULL);

		printf("------------------------------------------------------------\n");
		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[BENCH_DB] -- Elapsed search time: %f\n", elapsedTime/1000.0);
		printf("------------------------------------------------------------\n\n");



		//Autocorrelate the database
		/*
		printf("[BENCH_DB] -- Autocorrelating the database...\n");
		db->autoCorrelate2();
		printf("[BENCH_DB] -- Performaing k-fold cross validation\n");
		db->crossValidation();
		db->crossValidation();
		db->crossValidation();
		db->crossValidation();
		db->crossValidation();
		*/

		db->printStats();

		printf(" -- COMPLETE!\n");
	}
	catch(cException e){
		printf("%s", e.what());
	}
	catch(ArgException e){
		if(argc == 1){
			printf("\n  bench_db\n");
			printf("  ================================================================================\n");

			printf("    This program reads in a database files and performs performance benchmark test\n");
			printf("    It runs each a search of each circuit of the database to the database\n");
			printf("    Execution time and average sequence length of each circuit search is recorded\n");
			printf("    Output: data/c2DB_Time.dat and data/avgSeqLength.dat\n");

			printf("\n  Usage: ./bench_db [XML Database]\n\n");
		}
		else{
			printf("%s", e.what());
			printf("\n  Usage: ./bench_db [XML Database]\n\n");
		}
	}

	if(db != NULL) delete db;

	return 0;
}

#endif
