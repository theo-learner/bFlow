#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include <map>
#include <set>
#include <list>
#include "sw/src/ssw.h"
#include "sw/src/ssw_cpp.h"
#include "similarity.hpp"
#include "swalign.h"

std::string create_yosys_script(std::string, std::string);
bool readDumpFile(std::string, std::string);
void readFile(std::string file, std::list<std::string>& list);
void readFile(std::string file, std::set<std::string>& set);
void readSeqFile(std::string file, std::list<std::string>&, std::list<std::string>&);
const std::string g_YosysScript= "ys";
void extractDataflow(std::string, std::string, std::list<std::string>&, std::list<std::string>&);

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

void align(std::list<std::string>& ref, std::list<std::string>& db, double& sim, double& score){
	std::list<std::string>::iterator iSeq;	
	std::list<std::string>::iterator iRef;	
	double maxSim = 0.0;
	double maxScore = 0.0;
	for(iRef= ref.begin(); iRef!= ref.end(); iRef++){
		for(iSeq = db.begin(); iSeq != db.end(); iSeq++){
			// Declares a Aligner with weighted score penalties
			StripedSmithWaterman::Aligner aligner(100, 100, 90, 5);
			// Declares a default filter
			StripedSmithWaterman::Filter filter;
			// Declares an alignment that stores the result
			StripedSmithWaterman::Alignment alignment;

			// Aligns the query to the ref
			//Make sure the first item in align is the longest. Otherwise seg fault may occur. 
			int refMatchLen = 0;
			if(iSeq->length() > iRef->length()){
				printf(" * COMPARING REF: %s \tDB: %s\n", iRef->c_str(), iSeq->c_str());
				aligner.Align(iRef->c_str(), iSeq->c_str(), iSeq->length(), filter, &alignment);
				refMatchLen = alignment.query_end - alignment.query_begin + 1;
			}
			else{
				printf(" * COMPARING DB: %s \tREF: %s\n", iSeq->c_str(), iRef->c_str());
				aligner.Align(iSeq->c_str(), iRef->c_str(), iRef->length(), filter, &alignment);

				refMatchLen = alignment.ref_end- alignment.ref_begin + 1;

				//sim= (double)alignment.matches/ iSeq->length();
				///printf(" -- MATCHED WITH SMALLER score: %f\n", score);
			}

			double mismatches = 0.0;
			if(alignment.result.length() != alignment.result.length()) throw 6;
			if(alignment.query.length() != alignment.result.length()) throw 6;

			for(unsigned int i = 0; i < alignment.result.length(); i++){
				if(alignment.result[i] == '*'){
					if(alignment.ref[i] == '-' || alignment.query[i] == '-')
						mismatches += 0.01;
					else
						mismatches += 0.20;
				}
			}



			int refLength = alignment.length-refMatchLen+iRef->size();
			double cursim= (double)(alignment.matches - mismatches) / (double) refLength;
			double curscore = alignment.sw_score;
			//if(alignment.sw_score > maxScore) maxScore = alignment.sw_score;
			if(cursim> maxSim) maxSim = cursim;
			if(curscore> maxScore) maxScore = curscore;
			
			printf("REFLENGTH: %d +GAP: %d", (int)iRef->size(), refLength);
			printf("\t\tQUERY: %d\t", (int)(iSeq->size()));
			printf("\t\tTOTAL: %d\t", (int)(alignment.length-refMatchLen+iRef->size()));
			printf("\t\tMATCH: %d\t", alignment.matches);
			printf("\t\tMISMATCH: %f\n", mismatches);

			printf(" -- Best Smith-Waterman score:\t%d\t\tSIM: %f\n", alignment.sw_score, cursim);

			/*
				 seq_pair problem;
				 seq_pair_t result;
				 if(iSeq->length() > iRef->length()){
				 printf(" * COMPARING REF: %s \tDB: %s\n", iRef->c_str(), iSeq->c_str());
				 char c[strlen(iRef->c_str())], d[strlen(iSeq->c_str())];

				 strcpy(c, iRef->c_str());
				 strcpy(d, iSeq->c_str());
				 problem.a = c;
				 problem.b = d;
				 problem.alen = strlen(problem.a);
				 problem.blen = strlen(problem.b);
				 result = smith_waterman(&problem);
				 printf("     REF:     %s\n     QUE:     %s\n", result->a, result->b);

				 }
				 else{
				 printf(" * COMPARING DB: %s \tREF: %s\n", iSeq->c_str(), iRef->c_str());
				 char c[strlen(iSeq->c_str())], d[strlen(iRef->c_str())];

				 strcpy(c, iSeq->c_str());
				 strcpy(d, iRef->c_str());
				 problem.a = c;
				 problem.b = d;
				 problem.alen = strlen(problem.a);
				 problem.blen = strlen(problem.b);
				 result = smith_waterman(&problem);
				 printf("     REF:     %s\n     QUE:     %s\n", result->b, result->a);
				 }



				 std::string resultRef = result->a;
				 std::string resultQuery = result->b;



				 double mismatches = 0.0;
				 double matches = 0.0;
				 int refGap = 0;
				 if(resultRef.length() != resultQuery.length()) throw 6;

				 for(unsigned int i = 0; i < resultRef.length(); i++){
				 if(resultRef[i] == '-'){
				 mismatches += 0.05;
				 refGap++;
				 }
				 else if(resultQuery[i] == '-')
				 mismatches += 0.05;
				 else if(resultRef[i] != resultQuery[i])
				 mismatches += 0.25;
				 else if(resultRef[i] == resultQuery[i])
				 matches += 1.0;
				 }



				 int refLength = iRef->length() + refGap;
				 sim= (matches - mismatches) / (double) refLength;
				 if(sim> maxSim) maxSim = sim;

				 printf("REFLENGTH: %d", refLength);
				 printf("\t\tMATCH: %f\t", matches);
				 printf("\t\tMISMATCH: %f\n", mismatches);

				 printf(" -- Best Smith-Waterman score: %f\n", sim);
			 */

		}

		//sim += maxSim;
		printf("***************************************************\n");
	}
	sim += maxSim;
	score += maxScore;

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
		std::list<std::string> refseqmax, refseqmin;
		extractDataflow(referenceCircuit, topName, refseqmax, refseqmin);

		std::set<std::string> refCnst;
		readFile(".const", refCnst);





		//Make sure database file is okay
		std::ifstream infile;
		infile.open(argv[2]);
		if (!infile.is_open()) throw 5;

		std::string file;
		printf("Extracting dataflows from database\n");	

		//File, sequence
		std::map<std::string, std::list<std::string> > seqMaxDatabase;
		std::map<std::string, std::list<std::string> > seqMinDatabase;
		std::map<std::string, std::list<std::string> >::iterator iMin;
		std::map<std::string, std::list<std::string> >::iterator iMin2;
		std::map<std::string, std::list<std::string> >::iterator iMax;
		std::map<std::string, std::list<std::string> >::iterator iMax2;
		//File, list of constants
		std::map<std::string, std::set<std::string> > constantDatabase;


		std::vector<std::string> cktname;
		while(getline(infile, file)){
			getFileProperties(file, topName, extension);

			//Make sure the file is a verilog file
			if(extension != "v" && extension != "vhd") throw 3;

			std::list<std::string> seqMax;
			std::list<std::string> seqMin;
			extractDataflow(file, topName, seqMax, seqMin);

			std::set<std::string> cnst;
			readFile(".const", cnst);
			seqMaxDatabase[file] = seqMax;
			seqMinDatabase[file] = seqMin;

			constantDatabase[file] = cnst;
			cktname.push_back(file);
		}

		std::set<Score, setCompare> resultsMax;
		std::set<Score, setCompare> resultsMin;
		std::set<Score, setCompare> resultsAvg;
		std::set<Score, setCompare> resultsAsc;

		std::vector<std::vector<double> > simTable;
		simTable.reserve(seqMinDatabase.size());
		for(unsigned int i = 0; i < seqMinDatabase.size(); i++){
			std::vector<double> sim;
			sim.reserve(seqMinDatabase.size());
			simTable.push_back(sim);
		}

		std::vector<std::vector<double> > simTable2;
		simTable2.reserve(seqMinDatabase.size());
		for(unsigned int i = 0; i < seqMinDatabase.size(); i++){
			std::vector<double> sim;
			sim.reserve(seqMinDatabase.size());
			simTable2.push_back(sim);
		}


		//iMin = seqMinDatabase.begin();
		int index = 0; 
		//for(iMax = seqMaxDatabase.begin(); iMax != seqMaxDatabase.end(); iMax++){
		for(unsigned int i = 0; i < cktname.size(); i++){

			//iMin2 = seqMinDatabase.begin();
			iMax = seqMaxDatabase.find(cktname[i]);
			iMin = seqMinDatabase.find(cktname[i]);

			//	for(iMax2 = seqMaxDatabase.begin(); iMax2 != seqMaxDatabase.end(); iMax2++){
			for(unsigned int k = 0; k < cktname.size(); k++){
				iMin2 = seqMinDatabase.find(cktname[k]);
				iMax2 = seqMaxDatabase.find(cktname[k]);
				//std::string maxDBSeq iMax->second.front();
				//std::string minDBSeq = iMax->second.back();
				printf("\n\n\n#############################################################\n");
				printf("#############################################################\n");
				printf("#############################################################\n");
				printf("\nREF: %s\t - DB: %s\n", iMax->first.c_str(), iMax2->first.c_str());

				std::vector<double> simScore;
				simScore.reserve(3);

				//Two sequences...one max path, max path or shortestpaths
				double avg = 0.0;
				double asc = 0.0;
				align(iMax->second, iMax2->second, avg, asc);
				printf("\n\nCHECKING MIN SET\n");
				align(iMin->second, iMin2->second, avg, asc);

				Score result;
				result.name = iMax->first;
				//result.score = avg/(iMax->second.size()+iMin->second.size());
				result.score = avg/2;
				resultsAvg.insert(result);
				simTable[index].push_back(result.score);

				/*
				Score result2;
				result2.name = iMax->first;
				result2.score = asc/2;
				resultsAsc.insert(result2);
				simTable2[index].push_back(result2.score);
				*/	

				printf(" -------------------------------------------------\n");
				printf(" -- MATCHED WITH MAXREF score: %f\n", result.score);
				//printf(" -- MATCHED WITH MINREF score: %f\n", result2.score);


				std::set<std::string>::iterator iSet;
				std::map<std::string, std::set<std::string> >::iterator iCRef;
				std::map<std::string, std::set<std::string> >::iterator iCQue;
				iCQue = constantDatabase.find(iMax2->first);
				printf("CONST  DB: ");
				for(iSet = iCQue->second.begin(); iSet != iCQue->second.end(); iSet++)
					printf("%s ", iSet->c_str());
				printf("\nCONST REF: ");
				iCRef = constantDatabase.find(iMax->first);
				for(iSet = iCRef->second.begin(); iSet != iCRef->second.end(); iSet++)
					printf("%s ", iSet->c_str());
				printf("\nSIM: %f\n\n", SIMILARITY::tanimoto(iCQue->second, iCRef->second));
				
				double csim = SIMILARITY::tanimoto(iCQue->second, iCRef->second);
				if(iCQue->second.size() == 0 && iCRef->second.size() == 0)
					csim = 1.0;
				simTable2[index].push_back(csim);


				iMin2++;

			}

			iMin++;
			index++;
		}
		/*
			 std::set<Score, setCompare>::iterator iSet;
			 printf("\nResults Avg:\n");
			 printf("----------------------\n");
			 for(iSet = resultsAvg.begin(); iSet != resultsAvg.end(); iSet++){
			 printf("Sim: %7.4f\tCircuit: %s\n", iSet->score, iSet->name.c_str());
			 }
			 printf("\nResults Score:\n");
			 printf("----------------------\n");
			 for(iSet = resultsAsc.begin(); iSet != resultsAsc.end(); iSet++){
			 printf("Sim: %7.4f\tCircuit: %s\n", iSet->score, iSet->name.c_str());
			 }
		 */

		printf("Excel Format\n");
		printf("Circuits\t");
		//for(iMax = seqMaxDatabase.begin(); iMax != seqMaxDatabase.end(); iMax++){
		for(unsigned int i = 0; i < cktname.size(); i++){
			std::string name = cktname[i];
			int lastSlashIndex = name.find_last_of("/") + 1;
			printf("%s ", name.substr(lastSlashIndex, name.length()-lastSlashIndex-2).c_str());
		}
		printf("\n");

		//index = 0;
		//for(iMax = seqMaxDatabase.begin(); iMax != seqMaxDatabase.end(); iMax++){
		for(unsigned int i = 0; i < cktname.size(); i++){
			std::string name = cktname[i];
			int lastSlashIndex = name.find_last_of("/") + 1;
			printf("%s ", name.substr(lastSlashIndex, name.length()-lastSlashIndex-2).c_str());


			for(unsigned int k = 0; k < simTable.size(); k++)
				printf("%.3f ", simTable[i][k]*100.0*0.8+ simTable2[i][k]*100*0.2);

			printf("\n");
			//index++;
		}
		printf("\n");

		/*
			 printf("Excel Format\n");
			 printf("Circuits\t");
		//for(iMax = seqMaxDatabase.begin(); iMax != seqMaxDatabase.end(); iMax++){
		for(unsigned int i = 0; i < cktname.size(); i++){
		std::string name = cktname[i];
		int lastSlashIndex = name.find_last_of("/") + 1;
		printf("%s ", name.substr(lastSlashIndex, name.length()-lastSlashIndex-2).c_str());
		}
		printf("\n");

		//index = 0;
		//for(iMax = seqMaxDatabase.begin(); iMax != seqMaxDatabase.end(); iMax++){
		for(unsigned int i = 0; i < cktname.size(); i++){
		std::string name = cktname[i];
		int lastSlashIndex = name.find_last_of("/") + 1;
		printf("%s ", name.substr(lastSlashIndex, name.length()-lastSlashIndex-2).c_str());


		for(unsigned int k = 0; k < simTable2.size(); k++)
		printf("%.3f ", simTable2[i][k]);

		printf("\n");
		//index++;
		}
		printf("\n");
		 */

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
			else if(e == 6)
				printf("[ERROR] -- Smith Waterman Error\n");
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

		void readFile(std::string file, std::set<std::string>& set){
			std::ifstream ifs;
			ifs.open(file.c_str());

			std::string line;
			while(getline(ifs, line))
				set.insert(line);

			ifs.close();
		}

		void readSeqFile(std::string file, std::list<std::string>& max, std::list<std::string>& min){
			std::ifstream ifs;
			ifs.open(file.c_str());

			std::string line;
			std::string seq;

			int count; 
			ifs>>count;
			for(int i = 0; i < count; i++){
				ifs>>seq;
				max.push_back(seq);
			}

			ifs>>count;
			for(int i = 0; i < count; i++){
				ifs>>seq;
				min.push_back(seq);
			}

			ifs.close();
		}

		void extractDataflow(std::string file, std::string top, std::list<std::string>& max, std::list<std::string>& min){
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

			readSeqFile(".seq", max, min);
		}
