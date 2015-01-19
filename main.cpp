#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include <map>
#include <set>
#include <list>
#include "sw/src/ssw.h"
#include "sw/src/ssw_cpp.h"

std::string create_yosys_script(std::string, std::string);
bool readDumpFile(std::string, std::string);
void readFile(std::string file, std::list<std::string>& list);
const std::string g_YosysScript= "ys";
void extractDataflow(std::string, std::string, std::list<std::string>&);

//Used to sort the id and name by the score
struct Score{
	double score;
	std::string name;
};


//Used to compare the cScore so that it is sorted by the score
struct setCompare{
	bool operator()(const Score& lhs, const Score& rhs) const{
		return lhs.score >= rhs.score;
	}
};

void getFileProperties(std::string file, std::string& name, std::string& ext){
		//Get extension and top name
		int lastSlashIndex = file.find_last_of("/") + 1;
		if(lastSlashIndex == -1) lastSlashIndex = 0;

		int lastDotIndex= file.find_last_of(".");
		name = file.substr(lastSlashIndex, lastDotIndex-lastSlashIndex);
		ext= file.substr(lastDotIndex+1, file.length()-lastDotIndex);
}


int main(int argc, char** argv){
	try{
		if(argc != 3) throw 4;


		//Reference circuit name
		std::string referenceCircuit = argv[1];
		std::string topName = "", extension = "";
		getFileProperties(referenceCircuit, topName, extension);

		//Make sure the file is a verilog file
		if(extension != "v" && extension != "vhd") throw 3;

		printf("Extracting dataflow from reference design\n");	
		std::list<std::string> refseq;
		extractDataflow(referenceCircuit, topName, refseq);

		std::list<std::string> refCnst;
		readFile(".const", refCnst);





		//Make sure database file is okay
		std::ifstream infile;
		infile.open(argv[2]);
		if (!infile.is_open()) throw 5;

		std::string file;
		printf("Extracting dataflows from database\n");	

		//File, sequence
		std::map<std::string, std::list<std::string> > sequenceDatabase;
		std::map<std::string, std::list<std::string> >::iterator iMapS;
		//File, list of constants
		std::map<std::string, std::list<std::string> > constantDatabase;
		std::map<std::string, std::list<std::string> >::iterator iMapC;

		while(getline(infile, file)){
			getFileProperties(file, topName, extension);
		
			//Make sure the file is a verilog file
			if(extension != "v" && extension != "vhd") throw 3;

			std::list<std::string> seq;
			extractDataflow(file, topName, seq);

			std::list<std::string> cnst;
			readFile(".const", cnst);
			sequenceDatabase[file] = seq;
			constantDatabase[file] = cnst;
		}

		std::set<Score, setCompare> resultsMax;
		std::set<Score, setCompare> resultsMin;
		std::set<Score, setCompare> resultsAvg;
		for(iMapS = sequenceDatabase.begin(); iMapS != sequenceDatabase.end(); iMapS++){
			//std::string maxDBSeq iMapS->second.front();
			//std::string minDBSeq = iMapS->second.back();
			printf("\nREF: %s\t - DB: %s\n", referenceCircuit.c_str(), iMapS->first.c_str());

			std::list<std::string>::iterator iSeq;	
			std::list<std::string>::iterator iRef = refseq.begin();	
			std::vector<double> simScore(2);
			int index = 0;

			//Two sequences...one max path, max path or shortestpaths
			double avg = 0.0;
			for(iSeq = iMapS->second.begin(); iSeq != iMapS->second.end(); iSeq++){
				// Declares a Aligner with weighted score penalties
				StripedSmithWaterman::Aligner aligner(10, 10, 9, 1);
				// Declares a default filter
				StripedSmithWaterman::Filter filter;
				// Declares an alignment that stores the result
				StripedSmithWaterman::Alignment alignment;

				// Aligns the query to the ref
				//Make sure the first item in align is the longest. Otherwise seg fault may occur. 
				int numMatch = 0;
				double score = 0.0;
				if(iSeq->length() > iRef->length()){
					printf(" * COMPARING REF: %s \tDB: %s\n", iRef->c_str(), iSeq->c_str());
					numMatch = aligner.Align(iRef->c_str(), iSeq->c_str(), iSeq->length(), filter, &alignment);
				}
				else{
					printf(" * COMPARING DB: %s \tREF: %s\n", iSeq->c_str(), iRef->c_str());
					numMatch = aligner.Align(iSeq->c_str(), iRef->c_str(), iRef->length(), filter, &alignment);

					score = (double)numMatch / iSeq->length();
					printf(" -- MATCHED WITH SMALLER score: %f\n", score);
				}

				score = (double)numMatch / iRef->length();
				simScore[index] = score;
				if(index == 0){
					Score result;
					result.name = iMapS->first;
					result.score = score;
					resultsMax.insert(result);
					avg = score;

				}
				else{
					Score result;
					result.name = iMapS->first;
					result.score = score;
					resultsMin.insert(result);
					avg = (avg + score)/2;
				}


				//printf(" -- Best Smith-Waterman score:\t%d\n", alignment.sw_score);
				//printf(" -- Next-best Smith-Waterman score:\t%d\n", alignment.sw_score_next_best);


				iRef++;
				index++;
			}

			Score result;
			result.name = iMapS->first;
			result.score = avg;
			resultsAvg.insert(result);

			printf(" -------------------------------------------------\n");
			printf(" -- MATCHED WITH MAXREF score: %f\n", simScore[0]);
			printf(" -- MATCHED WITH MINREF score: %f\n", simScore[1]);


			std::list<std::string>::iterator iList;
			iMapC = constantDatabase.find(iMapS->first);
			printf("CONST DB: ");
			for(iList = iMapC->second.begin(); iList != iMapC->second.end(); iList++)
				printf("%s ", iList->c_str());
			printf("\tREF: ");
			for(iList = refCnst.begin(); iList != refCnst.end(); iList++)
				printf("%s ", iList->c_str());
			printf("\n\n");

		}

		std::set<Score, setCompare>::iterator iSet;
		printf("Results Max:\n");
		printf("----------------------\n");
		for(iSet = resultsMax.begin(); iSet != resultsMax.end(); iSet++){
			printf("Sim: %7.4f\tCircuit: %s\n", iSet->score, iSet->name.c_str());
		}
		printf("\nResults Min:\n");
		printf("----------------------\n");
		for(iSet = resultsMin.begin(); iSet != resultsMin.end(); iSet++){
			printf("Sim: %7.4f\tCircuit: %s\n", iSet->score, iSet->name.c_str());
		}
		printf("\nResults Avg:\n");
		printf("----------------------\n");
		for(iSet = resultsAvg.begin(); iSet != resultsAvg.end(); iSet++){
			printf("Sim: %7.4f\tCircuit: %s\n", iSet->score, iSet->name.c_str());
		}


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

std::string create_yosys_script(std::string infile, std::string top){
	//Create Yosys Script	
	std::string yosysScript = "";
	yosysScript += "echo on\n";
	yosysScript += "read_verilog ";
	yosysScript += infile + "\n\n";

	yosysScript += "hierarchy -check\n";
	yosysScript += "proc; opt; fsm; opt; wreduce; opt\n\n";
	yosysScript += "flatten; opt\n";
	yosysScript += "wreduce; opt\n\n";

	yosysScript += "show -width -format dot -prefix ./dot/" + top + "_df " + top + "\n";

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

void readFile(std::string file, std::list<std::string>& list){
	std::ifstream ifs;
	ifs.open(file.c_str());

	std::string line;
	while(getline(ifs, line))
		list.push_back(line);

	ifs.close();
}

void extractDataflow(std::string file, std::string top, std::list<std::string>& dataflow){
	printf("\nVerilog File: %s\n", file.c_str());

	//printf("VNAME: %s\tVEXT: %s\n", cname.c_str(), extension.c_str());


	//RUN YOSYS TO GET DATAFLOW OF THE VERILOG FILE
	std::string scriptFile = create_yosys_script(file, top);
	if(scriptFile == "") return;

	std::string cmd = "yosys -Qq -s ";
	cmd += scriptFile + " -l .yosys.dmp";
	printf("[CMD] -- Running command: %s\n", cmd.c_str());
	system(cmd.c_str());

	//Check to see if yosys encountered an error
	readDumpFile(".yosys.dmp", "ERROR:");

	//RUN PYTHON SCRIPT TO EXTRACT DATAFLOW FROM DOT FILE THAT IS GENERATED
	cmd = "python pscript.py dot/" + top + "_df.dot";// > .pscript.dmp";
	printf("[CMD] -- Running command: %s\n", cmd.c_str());
	system(cmd.c_str());

	//Check to see if yosys encountered an error
	readDumpFile(".pscript.dmp", "Traceback");

	readFile(".seq", dataflow);
}
