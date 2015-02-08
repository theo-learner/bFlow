#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include <assert.h>
#include <map>
#include <set>
#include <list>
#include "sw/src/ssw.h"
#include "sw/src/ssw_cpp.h"
#include "similarity.hpp"
#include "print.hpp"

std::string create_yosys_script(std::string, std::string, std::string);
bool readDumpFile(std::string, std::string);
void readFile(std::string file, std::list<std::string>& list);
void readFile(std::string file, std::set<std::string>& set);
void readFile(std::string file, std::vector<std::map<unsigned, unsigned> >& );
void readSeqFile(std::string file, std::list<std::string>&, std::list<std::string>&);
void readScoreMatrix(std::string file, std::map<char, std::map<char, double> >& scoreMatrix);
const std::string g_YosysScript= "ys";
void extractDataflow(std::string, std::string, std::string, std::list<std::string>&, std::list<std::string>&);
void optimizeWeights(std::vector<std::vector<double> >& sim1,
                     std::vector<std::vector<double> >& sim2,
										 std::vector<std::vector<double> >& sim3);
void optimizeFSIMweights(std::map<std::string, std::vector<std::map<unsigned, unsigned> > >& fdata);

double calculateSimilarity(std::map<unsigned, unsigned>&,
                         std::map<unsigned, unsigned>& );

bool dle(double a, double b, double eps = 0.001){
		return b-a > eps;
}


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
			if (!ifs.is_open()) throw 5;

			std::string questr, refstr, dummy;
			getline(ifs, questr);
			//getline(ifs, result);
			getline(ifs, refstr);
			
			int qlen, rlen, score, matches;
			double psim;
			ifs>>dummy>>qlen;
			ifs>>dummy>>rlen;
			ifs>>dummy>>score;
			ifs>>dummy>>matches;
			ifs>>dummy>>psim;
			ifs.close();

			double penalty = 0.0;
			double wildcard = 0.0;
			for(unsigned int i = 0; i < questr.length(); i++){
				//printf("comparing %c - %c\n", questr[i], refstr[i]);
				if(questr[i] == '-'){
					if(refstr[i] == 'N')
						wildcard += 0.80;	
					else
						penalty += 0.01	;
				}
				else if(refstr[i] == '-'){
					if(questr[i] == 'N')
						wildcard += 0.80;	
					else
						penalty += 0.01	;
				}
				else if(refstr[i] != questr[i]){
		
					std::map<char, std::map<char, double> > scoreMatrix;
					readScoreMatrix("scoreMatrix", scoreMatrix);

					double scoreRef = scoreMatrix[refstr[i]][questr[i]];
					if(scoreRef < -1.00)
						penalty += 0.25;
					else if (scoreRef < -0.50)
						penalty += 0.1;
					else if (scoreRef > 0)
						penalty -= 0.75;
				}
			}


			double cursim= ((double)(matches - penalty) + wildcard) / (double) rlen;
			double curscore = (double) score;
			if(cursim> maxSim) maxSim = cursim;
			if(curscore> maxScore) maxScore = curscore;


			printf("REFLENGTH:  %d", rlen);
			printf("\t\tQUERY: %d\t", qlen);
			printf("\t\tMATCH: %d\t", matches);
			printf("\t\tWILD: %f\t", wildcard);
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
			if(extension != "v" && extension != "d") throw 3;

			std::list<std::string> seqMax;
			std::list<std::string> seqMin;
			extractDataflow(file, topName, extension, seqMax, seqMin);
			seqMaxDatabase[file] = seqMax;
			seqMinDatabase[file] = seqMin;

			std::set<std::string> cnst;
			readFile(".const", cnst);
			cnst.erase("0");
			cnst.erase("1");
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
		
		std::vector<std::vector<double> > simTable4;
		simTable4.reserve(seqMinDatabase.size());
		for(unsigned int i = 0; i < seqMinDatabase.size(); i++){
			std::vector<double> sim;
			sim.reserve(seqMinDatabase.size());
			simTable4.push_back(sim);
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
				double maxSim= 0.0;
				double minSim = 0.0;
				double asc = 0.0;
				align(iMax->second, iMax2->second, maxSim, asc);
				printf("\n\nCHECKING MIN SET\n");
				align(iMin->second, iMin2->second, minSim, asc);

				Score result;
				result.name = iMax->first;
				//result.score = avg/(iMax->second.size()+iMin->second.size());
				printf("MAX: %f MIN: %f\n", maxSim, minSim);
				result.score = (maxSim *0.650 + minSim* 0.350);
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

				//The more features both doesn't have, the less effect it has on the overall score

				double weights[9] = {
					0.12, 0.12, 0.05, 0.08, 0.08, 0.1, 0.05, 0.20, 0.20
				};

				double fsim = 0.0;
				double tsim;
				int fcount = 0; 
				//int fempty= 0; 
				for(unsigned int q = 0; q < iFRef->second.size(); q++){
					tsim = calculateSimilarity(iFRef->second[q], iFQue->second[q]);
					printf("SIM: %f\n", tsim);
					if(tsim >= 0){
						fcount++;
						fsim += tsim* weights[q];
					}
					else{
						fsim += (-1.0 * tsim * weights[q]);//fempty++;
						fcount++;
					}
				}


				//fsim = fsim / ((double) fcount);
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
		
		
		//optimizeWeights(simTable, simTable2, simTable3);

		//optimizeFSIMweights(fpDatabase);

/*
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
				double simVal = simTable[i][k]*100.0*0.70 + 
				                simTable2[i][k]*100.0*0.10 + 
				                simTable3[i][k]*100.0*0.20 ;
				printf("%.3f ", simVal);

			}
			printf("\n");
			//index++;
		}
		printf("\n");
		*/


		
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
				double simVal = simTable[i][k]*100.0*0.67 + 
				                simTable2[i][k]*100.0*0.12 + 
				                simTable3[i][k]*100.0*0.21 ;
				printf("%.3f ", simVal);
			}

			printf("\n");
			//index++;
		}
		printf("\n");


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

		std::string create_yosys_script(std::string infile, std::string top, std::string extension){
			//Create Yosys Script	
			std::string yosysScript = "";
			yosysScript += "echo on\n";
			printf("EXTENSION: %s\n", extension.c_str());

			//If the file is just a verilog file
			if(extension == "v"){
				yosysScript += "read_verilog ";
				yosysScript += infile + "\n\n";
			}

			//If it is a directory, read in all the files
			else if(extension == "d"){
				std::ifstream ifs;
				infile += "/files";
				ifs.open(infile.c_str());
				if (!ifs.is_open()) throw 5;

				std::string line;
				std::vector<std::string> files;
				while(getline(ifs, line))
					files.push_back(line);


				for(unsigned int i = 0; i < files.size(); i++){
					yosysScript += "read_verilog ";
					yosysScript += files[i]+ "\n";
				}
					
				yosysScript += "\n";
			}

			yosysScript += "hierarchy -check\n";
			yosysScript += "proc; opt; fsm; opt; wreduce; opt\n\n";
			yosysScript += "flatten "+ top +"; opt\n";
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
			if (!ifs.is_open()) throw 5;
			ss<<ifs.rdbuf();
			ifs.close();

			if(ss.str().find(errorString) != std::string::npos)
				throw 1;
			else return true;
		}

		void readFile(std::string file, std::list<std::string>& list){
			std::ifstream ifs;
			ifs.open(file.c_str());
			if (!ifs.is_open()) throw 5;

			std::string line;
			while(getline(ifs, line))
				list.push_back(line);

			ifs.close();
		}

		void readFile(std::string file, std::set<std::string>& set){
			std::ifstream ifs;
			ifs.open(file.c_str());
			if (!ifs.is_open()) throw 5;

			std::string line;
			while(getline(ifs, line))
				set.insert(line);

			ifs.close();
		}
		
		void readFile(std::string file, std::vector<std::map<unsigned, unsigned> >& fingerprint){
			std::ifstream ifs;
			ifs.open(file.c_str());
			if (!ifs.is_open()) throw 5;
			
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
			if (!ifs.is_open()) throw 5;

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
		
		void readScoreMatrix(std::string file, std::map<char, std::map<char, double> >& scoreMatrix){
			std::ifstream ifs;
			ifs.open(file.c_str());
			if (!ifs.is_open()) throw 5;

			std::string line;
			std::vector<char> alphabet;
			getline(ifs, line);

			for(unsigned int i = 1; i < line.size(); i=i+2)
				alphabet.push_back(line[i]);	

			char ch;
			double score;
			for(int i = 0; i < alphabet.size(); i++){
				std::map<char,double> alphaScore;
				ifs>>ch;
				for(int k = 0; k < alphabet.size(); k++){
					ifs>>score;
					alphaScore[alphabet[k]] = score/100.00;
				}

				scoreMatrix[ch] = alphaScore;
			}

			ifs.close();
		}

		void extractDataflow(std::string file, std::string top,  std::string extension, std::list<std::string>& max, std::list<std::string>& min){
			if(extension == "v")
				printf("\nVerilog File: %s\n", file.c_str());
			else if(extension == "v")
				printf("\nDirectory File: %s\n", file.c_str());

			//printf("VNAME: %s\tVEXT: %s\n", cname.c_str(), extension.c_str());


			//RUN YOSYS TO GET DATAFLOW OF THE VERILOG FILE
			std::string scriptFile = create_yosys_script(file, top, extension);
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
			//readDumpFile(".pscript.dmp", "Traceback");

			printf("READING SEQ FILE\n");
			readSeqFile(".seq", max, min);
			printf("DONE READING SEQ FILE\n");
		}


double calculateSimilarity(std::map<unsigned, unsigned>& fingerprint1,
		std::map<unsigned, unsigned>& fingerprint2){

	double sim;
	if(fingerprint1.size() == 0 and fingerprint2.size() == 0)
		sim = -1.00;
	else
		sim = SIMILARITY::tanimotoWindow_size(fingerprint1, fingerprint2);

	return sim;
}


void optimizeWeights(std::vector<std::vector<double> >& simTable,
                     std::vector<std::vector<double> >& simTable2,
										 std::vector<std::vector<double> >& simTable3){
		int arrangeSize	= 7;
		int arrangement[7] = {
			3, 3, 2, 2, 2, 3, 4
		};



		bool pos;
		std::vector<double> diffmaxv, t1v, t2v, t3v;
		for(int i = 0; i < arrangeSize; i++) {
			diffmaxv.push_back(0.0);
			t1v.push_back(0.0);
			t2v.push_back(0.0);
			t3v.push_back(0.0);
		}

		for(double t1 = 0.55; t1 <0.95; t1=t1+0.01){
			for(double t2 = 0.01; t2 < 1.0-t1-0.02 ; t2=t2+0.01){
				double t3 = 1.0-t1-t2;
				assert(t1+t2+t3 == 1.0);
				//printf(" CHECKING t1: %f   t2: %f   t3:%f\n", t1, t2, t3);

				double posval = 0.0, negval = 0.0;
				int numpos = 0, numneg = 0;

				int startp = 0;
				int endp = 0;

				pos = false;
				std::vector<double> diffv;

				for(int q = 0 ; q < arrangeSize; q++){
					//printf("ARRANGEMENT: %d\n", q);
					endp = endp + arrangement[q];	

					for(unsigned int i = 0; i < simTable.size(); i++){
						for(unsigned int k = 0; k < simTable.size(); k++){
							if((i < endp && i >= startp) || 
									(k < endp && k >= startp)){
								double simVal = simTable[i][k]*100.0*t1 + 
									simTable2[i][k]*100.0*t2 + 
									simTable3[i][k]*100.0*t3 ;

								if(i < endp && k < endp &&
										i >= startp && k >= startp){
									numpos++;
									posval+=simVal;

								}
								else{
									numneg++;
									negval+=simVal;
								}
									//printf("checking %d %d S: %d  E: %d P %d N %d\n", i, k, startp, endp, numpos, numneg);

							}
						}
					}

					//printf("NUMPOS: %d\tNUMNEG: %d\n", numpos, numneg);
					diffv.push_back( posval/(double)numpos - negval/(double)numneg);

					startp = endp;
				}
				//printf("checking %d %d S: %d  E: %d POS?:%d\n", i, k, startp, endp, pos);



				printf(" PARAM: t1: %f %f %f ", t1, t2, t3);
				for(unsigned int i = 0; i < diffv.size(); i++) printf("%f ", diffv[i]);
				printf("\n");
				for(unsigned int i = 0; i < diffv.size(); i++){
					 if(diffv[i] > diffmaxv[i]){
						 diffmaxv[i] = diffv[i];
						 t1v[i] = t1;
						 t2v[i] = t2;
						 t3v[i] = t3;
					 }
				}
			}
		}

		printf("DONE\n");
		for(unsigned int i = 0; i < t1v.size(); i++)
			printf(" OPTPARAM %d: t1: %f   t2: %f   t3:%f\n",i,  t1v[i], t2v[i], t3v[i]);

}

void optimizeFSIMweights(std::map<std::string, std::vector<std::map<unsigned, unsigned> > >& fdata){
	printf("OPTIMIZING FINGERPRINT WEIGHTS\n");
		
		int arrangeSize	= 7;
		int arrangement[7] = {
			3, 3, 2, 2, 2, 3, 4
		};

				//Fingerprint  Calculation
				std::map<std::string, std::vector<std::map<unsigned, unsigned> > >::iterator iFRef;
				std::map<std::string, std::vector<std::map<unsigned, unsigned> > >::iterator iFQue;
				//The more features both doesn't have, the less effect it has on the overall score
				/*
				double weights[9] = {
					0.12, 0.12, 0.05, 0.08, 0.08, 0.1, 0.05, 0.20, 0.20
				};
				*/

				std::map<int, std::vector<double> > wOpt;
				for(int i = 0; i < arrangeSize; i++){
					std::vector<double> vd(9, 0.0);
					wOpt[i] = vd;
				}
					

		std::vector<double> diffmaxv;
		for(int i = 0; i < arrangeSize; i++) 
			diffmaxv.push_back(0.0);

				double pt1 = 0.00;
				for(double t1 = 0.05; dle(t1, 1.0-0.05*8.0+0.01); t1=t1+0.05){
					for(double t2 = 0.05; dle(t2, 1.0-t1); t2=t2+0.05){
						for(double t3 = 0.05; dle(t3, 1.0-t1-t2); t3=t3+0.05){
							for(double t4 = 0.05; dle(t4, 1.0-t1-t2-t3); t4=t4+0.05){
								for(double t5 = 0.05; dle(t5, 1.0-t1-t2-t3-t4); t5=t5+0.05){
									for(double t6 = 0.05;dle(t6, 1.0-t1-t2-t3-t4-t5) ; t6=t6+0.05){
										for(double t7 = 0.05; dle(t7, 1.0-t1-t2-t3-t4-t5-t6); t7=t7+0.05){
											for(double t8 = 0.05; dle(t8, 1.0-t1-t2-t3-t4-t5-t6-t7) ; t8=t8+0.05){
												
												double t9 = 1.00-t1-t2-t3-t4-t5-t6-t7-t8;


													printf("w1: %4.2f w2: %4.2f w3: %4.2f w4: %4.2f w5: %4.2f w6: %4.2f w7: %4.2f w8: %4.2f w9: %4.2f\n", t1, t2, t3, t4, t5, t6, t7, t8, t9 );
													pt1 = t6;

												//printf("w1: %4.2f w2: %4.2f w3: %4.2f w4: %4.2f w5: %4.2f w6: %4.2f w7: %4.2f w8: %4.2f w9: %4.2f", t1, t2, t3, t4, t5, t6, t7, t8, t9 );
												//double sum = (t1+t2+t3+t4+t5+t6+t7+t8+t9);
												//printf("\tSUM: %f\n", sum);

												std::vector<double> w;
												w.push_back(t1);
												w.push_back(t2);
												w.push_back(t3);
												w.push_back(t4);
												w.push_back(t5);
												w.push_back(t6);
												w.push_back(t7);
												w.push_back(t8);
												w.push_back(t9);

				double posval = 0.0, negval = 0.0;
				int numpos = 0, numneg = 0;

				int startp = 0;
				int endp = 0;
				std::vector<double> diffv;
				for(int q = 0 ; q < arrangeSize; q++){
					//printf("ARRANGEMENT: %d\n", q);
					endp = endp + arrangement[q];	

					unsigned int i = 0;
					for(iFRef = fdata.begin(); iFRef != fdata.end(); iFRef++){
						unsigned int k = 0;
						for(iFQue = fdata.begin(); iFQue != fdata.end(); iFQue++){
							if((i < endp && i >= startp)){
								
							double tsim = 0.0;
							double fsim = 0.0;

							for(unsigned int a = 0; a < iFRef->second.size(); a++){
								tsim = calculateSimilarity(iFRef->second[a], iFQue->second[a]);
								//printf("SIM: %f\n", tsim);
								if(tsim >= 0)
									fsim += tsim* w[a];
								else
									fsim += (-1.0 * tsim * w[a]);//fempty++;
							}


								if(i < endp && k < endp &&
										i >= startp && k >= startp){
									numpos++;
									posval+=fsim;

								}
								else{
									numneg++;
									negval+=fsim;
								}

						}
						k++;
					}
					i++;

				}
					//printf("NUMPOS: %d\tNUMNEG: %d\n", numpos, numneg);
					diffv.push_back( posval/(double)numpos - negval/(double)numneg);
					startp = endp;
				}

				for(unsigned int i = 0; i < diffv.size(); i++){
					 if(diffv[i] > diffmaxv[i]){
						 diffmaxv[i] = diffv[i];
						 wOpt[i].clear();
						 for(unsigned int p = 0; p < 9; p++)
							 wOpt[i].push_back(w[p]);

						 //printf("OPT: %d WEIGHTS: ", i);
						 //cprint(wOpt[i]);
					 }
				}



											}
										}
									}
								}
							}
						}
					}
				}


		printf("DONE\n");
		
		std::map<int, std::vector<double> >::iterator iMap;
		for(iMap = wOpt.begin(); iMap != wOpt.end(); iMap++){
			printf(" OPTPARAM %d: w: ",iMap->first);
			for(unsigned int q= 0; q < iMap->second.size(); q++){
				printf("%f ", iMap->second[q])	;
			}
			printf("\n");
		}


}
