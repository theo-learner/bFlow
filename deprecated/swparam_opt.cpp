#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include <map>
#include <iostream>
#include "sw/src/ssw.h"
#include "sw/src/ssw_cpp.h"


std::string create_yosys_script(std::string, std::string);
bool readDumpFile(std::string, std::string);
std::string readSeqFile(std::string);
const std::string g_YosysScript= "ys";
std::string extractDataflow(std::string);

int main(int argc, char** argv){
	try{
		if(argc != 3) throw 4;

		printf("Extracting dataflow from reference design\n");	
		std::string targetseq = extractDataflow(argv[1]);

		//Make sure database file is okay
		std::ifstream infile;
		infile.open(argv[2]);
		if (!infile.is_open()) throw 5;

		std::string file;
		printf("Extracting dataflows from database\n");	


		//File name, sequence
		std::map<std::string, std::string> sequenceDatabase;
		std::map<std::string, std::string>::iterator iMap;
		while(getline(infile, file)){
			std::string queryseq= extractDataflow(file);
			sequenceDatabase[file] = queryseq;
		}

		double maxScore = 0.0;
		int matchMax= 0;
		int mismatchMax= 0;
		int gapoMax= 0;
		int gapeMax= 0;
		int match = 0;
		int mismatch= 0;
		int gapo= 0;
		int gape= 0;

		for(match = 1; match < 10; match++){
			for(mismatch = 1; mismatch <= match; mismatch++){
				for(gapo = 1; gapo <= match; gapo++){
					for(gape = 1; gape <= gapo; gape++){

						double simSum = 0.0;
						//printf("***********************************************\n");
						printf("CHK M: %d MM: %d GO: %d GE: %d\t\t", match, mismatch, gapo, gape);
						for(iMap = sequenceDatabase.begin(); iMap != sequenceDatabase.end(); iMap++){
							//printf("COMPARING CIRCUIT: %s\n", iMap->first.c_str());

							// Declares a Aligner with weighted score penalties
							StripedSmithWaterman::Aligner aligner(match, mismatch, gapo, gape);
							// Declares a default filter
							StripedSmithWaterman::Filter filter;
							// Declares an alignment that stores the result
							StripedSmithWaterman::Alignment alignment;

							// Aligns the query to the ref
							//Make sure the first item in align is the longest. Otherwise seg fault may occur. 
							int numMatch = 0;
							double score = 0.0;
							if(iMap->second.length() > targetseq.length()){
								numMatch = aligner.Align(targetseq.c_str(), iMap->second.c_str(), iMap->second.size(), filter, &alignment);
								//printf("COMPARING QUERY: %s \tTARGET: %s\n", targetseq.c_str(), iMap->second.c_str());
							}
							else{
								numMatch = aligner.Align(iMap->second.c_str(), targetseq.c_str(), targetseq.size(), filter, &alignment);
								//printf("COMPARING QUERY: %s \tTARGET: %s\n", iMap->second.c_str(), targetseq.c_str());
							}
							
							score = (double)numMatch / targetseq.length();
							
							/*
							std::cout << "===== SSW result =====" << std::endl;
							std::cout << "Best Smith-Waterman score:\t" << alignment.sw_score << std::endl
								        << "Next-best Smith-Waterman score:\t" << alignment.sw_score_next_best << std::endl;
							std::cout << "======================" << std::endl;
							*/

							//score = swAlignment(targetseq.c_str(), targetseq.length(), iMap->second.c_str(), iMap->second.length());
							//simSum += alignment.sw_score;
							simSum += score;
							//printf(" * SIM: %f\n", score);
						}
						//printf("***********************************************\n");

						printf("SC: %.10f\t\t", simSum);
						if(simSum > maxScore){
							printf("NEWMAX!");
							maxScore = simSum;
							matchMax = match;
							mismatchMax = mismatch;
							gapoMax = gapo;
							gapeMax = gape;
						}
						printf("\n");

					}
				}
			}
		}
		printf("\nMax: MATCH: %d MISMATCH: %d GAPO: %d GAPE: %d SCORE: %f\n", matchMax, mismatchMax, gapoMax, gapeMax, maxScore);
		
	}
	catch(int e){
		if(e == 1)
			printf("[ERROR] -- Error encountered in DMP file. Exiting\n");
		else if(e == 2)
			printf("[ERROR] -- There was no sequence extracted. Exiting\n");
		else if(e == 3)
			printf("[ERROR] -- Unknown File extension. Expecting Verilog or VHDL File\n");
		else if(e == 4)
			printf("[ERROR] -- Not enough arguments <Verilog File> <Database File> \n");
		else if(e == 5)
			printf("[ERROR] -- Cannot open the database for import...exiting\n");
		else
			printf("[ERROR] -- Error Occurred that was not mapped before\n");

		return 0;
	}

	return 1;
}

std::string create_yosys_script(std::string infile, std::string outFile){
	//Create Yosys Script	
	std::string yosysScript = "";
	yosysScript += "read_verilog ";
	yosysScript += infile + "\n\n";

	yosysScript += "hierarchy -check\n";
	yosysScript += "proc; opt; fsm; opt; wreduce; opt\n\n";

	yosysScript += "show -width -format dot -prefix ./" + outFile + "\n";

	std::ofstream ofs;
	ofs.open(g_YosysScript.c_str());

	ofs<< yosysScript;
	printf("Yosys script generated\n");
	return g_YosysScript.c_str();

}

bool readDumpFile(std::string file, std::string errorString)	{
	std::stringstream ss;
	std::ifstream ifs;
	ifs.open(file.c_str());
	ss<<ifs.rdbuf();
	ifs.close();

	if(ss.str().find(errorString) != std::string::npos)
		throw 1;
	else return true;
}

std::string readSeqFile(std::string file){

	std::stringstream ss;
	std::ifstream ifs;
	ifs.open(file.c_str());
	ss<<ifs.rdbuf();
	ifs.close();

	std::string seq = ss.str();
	if(seq == "") throw 2;

	return seq;
}

std::string extractDataflow(std::string file){
	printf("\nVerilog File: %s\n", file.c_str());

	int lastSlashIndex = file.find_last_of("/") + 1;
	if(lastSlashIndex == -1) lastSlashIndex = 0;

	int lastDotIndex= file.find_last_of(".");
	std::string cname = file.substr(lastSlashIndex, lastDotIndex-lastSlashIndex);
	std::string extension= file.substr(lastDotIndex+1, file.length()-lastDotIndex);
	//printf("VNAME: %s\tVEXT: %s\n", cname.c_str(), extension.c_str());

	//Make sure the file is a verilog file
	if(extension != "v" && extension != "vhd") throw 3;

	//RUN YOSYS TO GET DATAFLOW OF THE VERILOG FILE
	std::string scriptFile = create_yosys_script(file, "dot/" + cname + "_df");
	if(scriptFile == "") return 0;

	std::string cmd = "yosys -Qq -s ";
	cmd += scriptFile + " -l .yosys.dmp";
	printf("[CMD] -- Running command: %s\n", cmd.c_str());
	system(cmd.c_str());

	//Check to see if yosys encountered an error
	readDumpFile(".yosys.dmp", "ERROR:");

	//RUN PYTHON SCRIPT TO EXTRACT DATAFLOW FROM DOT FILE THAT IS GENERATED
	cmd = "python pscript.py dot/" + cname + "_df.dot";// > .pscript.dmp";
	printf("[CMD] -- Running command: %s\n", cmd.c_str());
	system(cmd.c_str());

	//Check to see if yosys encountered an error
	readDumpFile(".pscript.dmp", "Traceback");

	std::string seq = readSeqFile(".yscript.seq");
	return seq;
}
