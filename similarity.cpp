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
double SIMILARITY::align(std::list<std::string>& ref, std::list<std::string>& db, int& alignScore){
//	timeval start_time, end_time;
//	gettimeofday(&start_time, NULL); //----------------------------------


	std::list<std::string>::iterator iSeq;	
	std::list<std::string>::iterator iRef;	
	double maxSim = 0.0;
	unsigned totalScore = 0;

	for(iRef= ref.begin(); iRef!= ref.end(); iRef++){
		for(iSeq = db.begin(); iSeq != db.end(); iSeq++){

			TSequence seq1 = *iRef;
			TSequence seq2 = *iSeq;
			assignSource(row(s_Align, 0), seq1);
			assignSource(row(s_Align, 1), seq2);

			double sizeRatio;
			if(iRef->length() < iSeq->length())
				sizeRatio = (double)iRef->length()/ (double)iSeq->length();
			else
				sizeRatio = (double)iSeq->length()/ (double)iRef->length();

			//int score = localAlignment(s_Align, Score<int, Simple>(10, -10, -8, -1));

			//printf("GAP: %d  GAPOPEN: %d  GAPEXTEND: %d\n", scoreGap(s_Score), scoreGapOpen(s_Score), scoreGapExtend(s_Score));
			int score = localAlignment(s_Align, s_Score);
			//printAlignment();

//////////////////////////////////////////////////////////////
    TRowIterator it1 = begin(row(s_Align,0));
    TRowIterator it2 = begin(row(s_Align,1));
    TRowIterator it1End = end(row(s_Align,0));

		double penalty = 0.0;
		double match = 0.0;
		double gaps = 0.0;
		for (; it1 != it1End; ++it1){
        if (isGap(it1)){
					gaps += 1.0;
					match += 0.2;
					score += CircuitGapPenaltyMatrix[*it2];

				}
        else if(isGap(it2)){
					match += 0.2;
					score += CircuitGapPenaltyMatrix[*it1];
				}
        else if(*it2 != *it1)   penalty += 0.75;
				else                    match += 1.0;
				++it2;
    }

		double refSizeWithGap = ((double)(length(value(stringSet(s_Align), 0))) + gaps);
		double sim = (match - penalty) / refSizeWithGap;
		////////////////////////////////////////////////////////////////



			//double cursim = alignScore() * sizeRatio;
			double cursim = sim * sizeRatio;
			score *= sizeRatio;
			if(cursim > maxSim) maxSim = cursim;
			printf("[SIM] -- SCORE: %7.4f - %5d   ALIGN: %s - %s\n", cursim, score, iRef->c_str(), iSeq->c_str());
			totalScore += score;
		}
		//printf("***************************************************\n");
	}

/*
	gettimeofday(&end_time, NULL); //----------------------------------
	double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
	elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
	printf("[SIM] -- Align elapsed time: %f\n", elapsedTime/1000.0);
	*/

	alignScore = totalScore;
	return maxSim;
	//return totalScore;

}

/*#############################################################################
 *
 * align 
 *  given a list of sequences (REF and DB), align the sequences and extract
 *  the similarity of the alignment (AVG SIM) 
 *
 *#############################################################################*/
double SIMILARITY::align(std::list<std::string>& ref, std::list<std::string>& db){
//	timeval start_time, end_time;
//	gettimeofday(&start_time, NULL); //----------------------------------


	std::list<std::string>::iterator iSeq;	
	std::list<std::string>::iterator iRef;	
	double maxSim = 0.0;
	unsigned totalScore = 0;

	for(iRef= ref.begin(); iRef!= ref.end(); iRef++){
		for(iSeq = db.begin(); iSeq != db.end(); iSeq++){

			TSequence seq1 = *iRef;
			TSequence seq2 = *iSeq;
			assignSource(row(s_Align, 0), seq1);
			assignSource(row(s_Align, 1), seq2);

			double sizeRatio;
			if(iRef->length() < iSeq->length())
				sizeRatio = (double)iRef->length()/ (double)iSeq->length();
			else
				sizeRatio = (double)iSeq->length()/ (double)iRef->length();

			//int score = localAlignment(s_Align, Score<int, Simple>(10, -10, -8, -1));

			//printf("GAP: %d  GAPOPEN: %d  GAPEXTEND: %d\n", scoreGap(s_Score), scoreGapOpen(s_Score), scoreGapExtend(s_Score));
			int score = localAlignment(s_Align, s_Score);

//////////////////////////////////////////////////////////////
    TRowIterator it1 = begin(row(s_Align,0));
    TRowIterator it2 = begin(row(s_Align,1));
    TRowIterator it1End = end(row(s_Align,0));

		double penalty = 0.0;
		double match = 0.0;
		double gaps = 0.0;
		for (; it1 != it1End; ++it1){
        if (isGap(it1)){
					gaps += 1.0;
					match += 0.2;
					score += CircuitGapPenaltyMatrix[*it2];

				}
        else if(isGap(it2)){
					match += 0.2;
					score += CircuitGapPenaltyMatrix[*it1];
				}
        else if(*it2 != *it1)   penalty += 0.75;
				else                    match += 1.0;
				++it2;
    }

		double refSizeWithGap = ((double)(length(value(stringSet(s_Align), 0))) + gaps);
		double sim = (match - penalty) / refSizeWithGap;
		////////////////////////////////////////////////////////////////



			//double cursim = alignScore() * sizeRatio;
			double cursim = sim * sizeRatio;
			if(cursim > maxSim) maxSim = cursim;
			totalScore += score;
			printf("[SIM] -- SCORE: %7.4f - %5d   ALIGN: %s - %s\n", cursim, score, iRef->c_str(), iSeq->c_str());
		}
		//printf("***************************************************\n");
	}

/*
	gettimeofday(&end_time, NULL); //----------------------------------
	double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
	elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
	printf("[SIM] -- Align elapsed time: %f\n", elapsedTime/1000.0);
	*/

	return maxSim;
	//return totalScore;

}

double SIMILARITY::alignScore(){
    TRowIterator it1 = begin(row(s_Align,0));
    TRowIterator it2 = begin(row(s_Align,1));
    TRowIterator it1End = end(row(s_Align,0));

		double penalty = 0.0;
		double match = 0.0;
		double gaps = 0.0;
		for (; it1 != it1End; ++it1){
        if (isGap(it1)){
					match += 0.2;
					gaps += 1.0;

				}
        else if(isGap(it2)){
					match += 0.2;

				}
        else if(*it2 != *it1)   penalty += 0.75;
				else                    match += 1.0;
				++it2;
    }

		double refSizeWithGap = ((double)(length(value(stringSet(s_Align), 0))) + gaps);
		double sim = (match - penalty) / refSizeWithGap;
		return sim;
}

void SIMILARITY::printAlignment(){
    TRowIterator it1 = begin(row(s_Align,0));
    TRowIterator it2 = begin(row(s_Align,1));
    TRowIterator it1End = end(row(s_Align,0));
    TRowIterator it2End = end(row(s_Align,1));
		for (; it1 != it1End; ++it1){
        if (isGap(it1))    std::cout << gapValue<char>();
        else              std::cout << *it1;
    }
    std::cout << std::endl;
		
    it1 = begin(row(s_Align,0));
    it2 = begin(row(s_Align,1));
		for (; it1 != it1End; ++it1){
        if (isGap(it1))         std::cout << "*" ;
        else if(isGap(it2))     std::cout << "*" ;
        else if(*it2 != *it1)  	std::cout << "X";
				else                    std::cout << "|";
				++it2;
    }
    std::cout << std::endl;
    
		it1 = begin(row(s_Align,0));
    it2 = begin(row(s_Align,1));
    for (; it2 != it2End; ++it2){
        if (isGap(it2))   std::cout << gapValue<char>();
        else              std::cout << *it2;
    }
    std::cout << std::endl;
    std::cout << std::endl;
}

void SIMILARITY::initAlignment(){
	//Set up the aligner
	resize(rows(s_Align), 2);

	//Set up the scoring scheme using a custom scoring matrix
	//Located in header file
	setDefaultScoreMatrix(s_Score, CircuitScoringMatrix());
	showScoringMatrix(s_Score);
	
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

