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
#include "print.hpp"

std::string create_yosys_script(std::string, std::string);
bool readDumpFile(std::string, std::string);
void readFile(std::string file, std::list<std::string>& list);
void readFile(std::string file, std::set<std::string>& set);
void readFile(std::string file, std::vector<std::map<unsigned, unsigned> >& );
void readSeqFile(std::string file, std::list<std::string>&, std::list<std::string>&);
const std::string g_YosysScript= "ys";
void extractDataflow(std::string, std::string, std::list<std::string>&, std::list<std::string>&);

double calculateSimilarity(std::map<unsigned, unsigned>&,
                         std::map<unsigned, unsigned>& );


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
			//RUN PYTHON SCRIPT TO EXTRACT DATAFLOW FROM DOT FILE THAT IS GENERATED
			printf(" * COMPARING REF: %s \tDB: %s\n", iRef->c_str(), iSeq->c_str());
			std::string cmd = "python ssw.py " + *iRef + " " + *iSeq;// > .pscript.dmp";
			//printf("[CMD] -- Running command: %s\n", cmd.c_str());
			system(cmd.c_str());

			std::ifstream ifs;
			ifs.open(".align");

			std::string questr, refstr, dummy;
			getline(ifs, questr);
			//getline(ifs, result);
			getline(ifs, refstr);

			double penalty = 0.0;
			for(unsigned int i = 0; i < questr.length(); i++){
				//printf("comparing %c - %c\n", questr[i], refstr[i]);
				if(questr[i] == '-')
					penalty += 0.05	;
				else if(refstr[i] == '-')
					penalty += 0.05	;
				else if(refstr[i] != questr[i])
					penalty += 0.20;
			}

			int qlen, rlen, score, matches, mismatches;
			double psim;
			ifs>>dummy>>qlen;
			ifs>>dummy>>rlen;
			ifs>>dummy>>score;
			ifs>>dummy>>matches;
			ifs>>dummy>>psim;
			ifs>>dummy>>mismatches;
			ifs.close();
			

			double cursim= (double)(matches - penalty) / (double) rlen;
			double curscore = (double) score;
			if(cursim> maxSim) maxSim = cursim;
			if(curscore> maxScore) maxScore = curscore;
			printf("REFLENGTH:  %d", rlen);
			printf("\t\tQUERY: %d\t", qlen);
			printf("\t\tMATCH: %d\t", matches);
			printf("\t\tMISMATCH: %d", mismatches);
			printf("\t\tPEN: %f\n", penalty);
			printf(" -- Best Smith-Waterman score:\t%f\t\tSIM: %f\n", curscore, cursim);
			/*
			// Declares a Aligner with weighted score penalties
			StripedSmithWaterman::Aligner aligner(100, 100, 90, 5);
			// Declares a default filter
			StripedSmithWaterman::Filter filter;
			// Declares an alignment that stores the result
			StripedSmithWaterman::Alignment alignment;

			// Aligns the query to the ref
			//Make sure the first item in align is the longest. Otherwise seg fault may occur. 
			int refMatchLen = 0;
			if(iRef->length() > iSeq->length()){ printf(" * COMPARING REF: %s \tDB: %s\n", iRef->c_str(), iSeq->c_str());
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
      printf("Cigar: %s\n", alignment.cigar_string.c_str());

			printf(" -- Best Smith-Waterman score:\t%d\t\tSIM: %f\n", alignment.sw_score, cursim);
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
		if(argc != 2) throw 4;

/*
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
		*/


		
		//Make sure database file is okay
		std::ifstream infile;
		infile.open(argv[1]);
		if (!infile.is_open()) throw 5;

		std::string file;
		std::string topName = "", extension = "";
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

		//File, fingerprints 
		std::map<std::string, std::vector<std::map<unsigned, unsigned> > > fpDatabase;


		std::vector<std::string> cktname;
		while(getline(infile, file)){
			getFileProperties(file, topName, extension);

			//Make sure the file is a verilog file
			if(extension != "v" && extension != "vhd") throw 3;

			std::list<std::string> seqMax;
			std::list<std::string> seqMin;
			extractDataflow(file, topName, seqMax, seqMin);
			seqMaxDatabase[file] = seqMax;
			seqMinDatabase[file] = seqMin;

			std::set<std::string> cnst;
			readFile(".const", cnst);
			constantDatabase[file] = cnst;
		
			std::vector<std::map<unsigned, unsigned> > fingerprint;
			readFile(".component", fingerprint);
			fpDatabase[file] = fingerprint;
			
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
		
		std::vector<std::vector<double> > simTable3;
		simTable3.reserve(seqMinDatabase.size());
		for(unsigned int i = 0; i < seqMinDatabase.size(); i++){
			std::vector<double> sim;
			sim.reserve(seqMinDatabase.size());
			simTable3.push_back(sim);
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


				//Constant Calculation
				std::set<std::string>::iterator iSet;
				std::map<std::string, std::set<std::string> >::iterator iCRef;
				std::map<std::string, std::set<std::string> >::iterator iCQue;
				iCQue = constantDatabase.find(iMax2->first);
				iCRef = constantDatabase.find(iMax->first);
				printf("CONST  DB: ");
				cprint(iCQue->second);
				printf("CONST REF: ");
				cprint(iCRef->second);

				double csim = SIMILARITY::tanimoto(iCQue->second, iCRef->second);
				if(iCQue->second.size() == 0 && iCRef->second.size() == 0)
					csim = 1.0;
				simTable2[index].push_back(csim);
				printf("\nCSIM: %f\n", csim);

				//Fingerprint  Calculation
				std::map<std::string, std::vector<std::map<unsigned, unsigned> > >::iterator iFRef;
				std::map<std::string, std::vector<std::map<unsigned, unsigned> > >::iterator iFQue;
				iFQue = fpDatabase.find(iMax2->first);
				iFRef = fpDatabase.find(iMax->first);

				double fsim = 0.0;
				for(unsigned int q = 0; q < iFRef->second.size(); q++)
					fsim += calculateSimilarity(iFRef->second[q], iFQue->second[q]);
				
				fsim = fsim / (double) iFRef->second.size();
				simTable3[index].push_back(fsim);
				printf("FP DB: \n");
				cprint(iFQue->second);
				printf("FP REF: \n");
				cprint(iFRef->second);
				printf("FSIM: %f\n\n", fsim);
				
				iMin2++;
			}

			iMin++;
			index++;
		}





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


			for(unsigned int k = 0; k < simTable.size(); k++){
				double simVal =  simTable[i][k]*100.0*0.70 + 
				                simTable2[i][k]*100.0*0.15 + 
				                simTable3[i][k]*100.0*0.15 ;
				printf("%.3f ", simVal);

			}
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
		
		void readFile(std::string file, std::vector<std::map<unsigned, unsigned> >& fingerprint){
			std::ifstream ifs;
			ifs.open(file.c_str());
			
			int numItems;
			int size, count;
			int numLines;

			ifs>>numLines;
			fingerprint.reserve(numLines);

			for(int i = 0; i < numLines; i++){
				ifs>>numItems;
				std::map<unsigned, unsigned> fp;

				for(int k = 0; k < numItems; k++){
					ifs>>size>>count;
					fp[size] = count;
				}

				fingerprint.push_back(fp);
			}

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


double calculateSimilarity(std::map<unsigned, unsigned>& fingerprint1,
		std::map<unsigned, unsigned>& fingerprint2){

	double sim;
	if(fingerprint1.size() == 0 and fingerprint2.size() == 0)
		sim = 1.00;
	else
		sim = SIMILARITY::tanimotoWindow(fingerprint1, fingerprint2);

	return sim;
}
