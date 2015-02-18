/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@ 
	@
	@  SIMILARITY.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "similarity.hpp"

int SIMILARITY::findMinDistance(std::map<unsigned, unsigned>& data, std::set<unsigned>& marked, unsigned value, std::map<unsigned, unsigned>::iterator& minIt){
	std::map<unsigned, unsigned>::iterator iMap;
	int minDiff = 10000;

	for(iMap= data.begin(); iMap!= data.end(); iMap++){
		//If the difference is greater than window size, continue;
		int difference = iMap->first - value;
		if(difference < 0) difference *= -1;


		if(difference < minDiff){
			//Check to see if it has been marked before
			if(marked.find(iMap->first) != marked.end()) continue;
			minDiff = difference;
			minIt = iMap;
		}
	}
	return minDiff;

}





double SIMILARITY::tanimotoWindow_size(std::map<unsigned, unsigned>& data1, std::map<unsigned,unsigned>& data2){
	if(data1.size() == 0 || data2.size() == 0){
		//return -1.0;
		return 0.0;
	}
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	const int windowSize = 5;
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iMap2;
	std::map<unsigned, unsigned>::iterator iTemp;
	std::map<unsigned, unsigned>::iterator iMapF;
	std::set<unsigned> marked1;
	std::set<unsigned> marked2;

	std::map<unsigned, unsigned> temp;
	std::map<unsigned, unsigned> map;

	const double multiplier[windowSize+1] = {
		1.000, 0.9938, 0.9772, 0.9332, 0.8413, 0.6915
	};

	
	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	

		if(iTemp != data2.end()){
			//printf("Both sets have : %d\n", iTemp->first); 
			N_f1f2_ratio += 1.000;

			marked1.insert(iMap->first);
			marked2.insert(iTemp->first);
		}
	}

	//Go through the vector again and try and find similar matches in the bits (WINDOWING)
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		if(marked1.find(iMap->first) == marked1.end()){
			int minDistance1 = findMinDistance(data2, marked2, iMap->first, iTemp);
			int minDistance2 = findMinDistance(data1, marked1, iTemp->first, iMapF);

			//There exists a shorter distance
			if(iMapF->first != iMap->first){
				continue;
			}
			else if(minDistance1 != minDistance2) continue;

			//Similar size found within window
			if(minDistance1 <= windowSize){
				double ratio = multiplier[minDistance1];

				N_f1f2_ratio += ratio;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
		}
	}

	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}








double SIMILARITY::tanimotoWindow(std::map<unsigned, unsigned> data1, std::map<unsigned,unsigned> data2){
	if(data1.size() == 0 || data2.size() == 0){
		//return -1.0;
		return 0.0;
	}
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	const int windowSize = 2;
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iMap2;
	std::map<unsigned, unsigned>::iterator iTemp;
	std::map<unsigned, unsigned>::iterator iMapF;
	std::set<unsigned> marked1;
	std::set<unsigned> marked2;

	const double multiplier[windowSize+1] = {
		1.000, 0.9332, 0.6915
		//1.000, 0.9938, 0.9772, 0.9332, 0.8413, 0.6915
	};
	
	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	
		//printf("Looking for %d in data1...", iMap->first);

		if(iTemp != data2.end()){
			//printf("Both data has: %d\n", iTemp->first);
			double ratio;
			if(iMap->second > iTemp->second){
				ratio = ((double)iTemp->second / (double)iMap->second);
				marked2.insert(iTemp->first);
				iMap->second = iMap->second - iTemp->second;
				//printf("data 1- %d: has %d left unmapped\n", iMap->first, iMap->second);
			}
			else if(iTemp->second >  iMap->second){
				ratio = ((double)iMap->second / (double)iTemp->second);
				marked1.insert(iMap->first);
				iTemp->second = iTemp->second - iMap->second;
				//printf("data 2- %d: has %d left unmapped\n", iTemp->first, iTemp->second);
			}
			else{
				//printf("EQUAL COUNTS\n");
				ratio = 1.000;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
			N_f1f2_ratio += ratio;
		}
		//else printf("\n");
	}

	//Go through the vector again and try and find similar matches in the bits (WINDOWING)
	//printf("\nWindowing on data1:\n");
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		//printf("Checking %d\n", iMap->first);
		if(marked1.find(iMap->first) == marked1.end()){
			//printf("*Not Marked\n");
			int minDistance1 = findMinDistance(data2, marked2, iMap->first, iTemp);
			int minDistance2 = findMinDistance(data1, marked1, iTemp->first, iMapF);

			//There exists a shorter distance
			if(iMapF->first != iMap->first){
				continue;
			}
			else if(minDistance1 != minDistance2) continue;

			//Similar size found within window
			if(minDistance1 <= windowSize){
				double ratio;
			


			if(iMap->second > iTemp->second){
				marked2.insert(iTemp->first);
				//printf("data 1- %d: has %d left unmapped\n", iMap->first, iMap->second-iTemp->second);
				ratio = ((double)iTemp->second / (double)iMap->second);
				iMap->second = iMap->second - iTemp->second;
			}
			else if(iTemp->second >  iMap->second){
				marked1.insert(iMap->first);
				//printf("data 2- %d: has %d left unmapped\n", iTemp->first, iTemp->second-iMap->second);
				ratio = ((double)iMap->second / (double)iTemp->second);
				iTemp->second = iTemp->second - iMap->second;
			}
			else{
				ratio = 1.000;
				//printf("EQUAL COUNTS\n");
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}




				ratio = multiplier[minDistance1]*ratio;// * (1.0 - ratio);

				N_f1f2_ratio += ratio;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
		}
		//printf("\n");
	}

	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}





double SIMILARITY::tanimoto(std::set<int>& data1, std::set<int>& data2){
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	double N_f1f2_ratio = 0.0;

	std::set<int>::iterator iMap;
	std::set<int>::iterator iTemp;

	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(*iMap);	

		if(iTemp != data2.end()){
			N_f1f2_ratio += 1.000;
		}
	}
	
	
	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}


double SIMILARITY::tanimoto(std::map<unsigned, unsigned>& data1, std::map<unsigned, unsigned>& data2){
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iTemp;

	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	

		if(iTemp != data2.end()){
			N_f1f2_ratio += 1.000;
		}
	}
	
	
	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}



/*#############################################################################
 *
 * align 
 *  given a list of sequences (REF and DB), align the sequences and extract
 *  the similarity of the alignment (AVG SIM) 
 *
 *#############################################################################*/
double SIMILARITY::align(std::list<std::string>& ref, std::list<std::string>& db){
	std::list<std::string>::iterator iSeq;	
	std::list<std::string>::iterator iRef;	
	double maxSim = 0.0;

	for(iRef= ref.begin(); iRef!= ref.end(); iRef++){
		for(iSeq = db.begin(); iSeq != db.end(); iSeq++){
			//RUN PYTHON SCRIPT TO EXTRACT DATAFLOW FROM DOT FILE THAT IS GENERATED
			//printf(" * COMPARING REF: #%s# \tDB: #%s#\n", iRef->c_str(), iSeq->c_str());
			std::string cmd = "python ssw.py " + *iRef + " " + *iSeq;// > .pscript.dmp";
			system(cmd.c_str());

			std::ifstream ifs;
			ifs.open(".align");
			if (!ifs.is_open()) throw 5;

			std::string questr, refstr, dummy;
			getline(ifs, questr);
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
/*
		
					std::map<char, std::map<char, double> > scoreMatrix;
					readScoreMatrix("scoreMatrix", scoreMatrix);

					double scoreRef = scoreMatrix[refstr[i]][questr[i]];
					if(scoreRef < -1.00)
						penalty += 0.25;
					else if (scoreRef < -0.50)
						penalty += 0.1;
					else if (scoreRef > 0)
						penalty -= 0.75;
						*/
						penalty -= 0.75;
				}
			}


			double cursim= ((double)(matches - penalty) + wildcard) / (double) rlen;
			//double curscore = (double) score;
			if(cursim> maxSim) maxSim = cursim;


/*
			printf("REFLENGTH:  %d", rlen);
			printf("\t\tQUERY: %d\t", qlen);
			printf("\t\tMATCH: %d\t", matches);
			printf("\t\tWILD: %f\t", wildcard);
			printf("\t\tPEN: %f\n", penalty);
			printf(" -- Best Smith-Waterman score:\t%f\t\tSIM: %f\n", curscore, cursim);
			*/
		}
		//printf("***************************************************\n");
	}
	return maxSim;

}

double SIMILARITY::calculateSimilarity(std::map<unsigned, unsigned>& fingerprint1,
		std::map<unsigned, unsigned>& fingerprint2){

	double sim;
	if(fingerprint1.size() == 0 and fingerprint2.size() == 0)
		sim = -1.00;
	else
		sim = tanimotoWindow_size(fingerprint1, fingerprint2);

	return sim;
}

