/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@ 
	@  similarity.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#ifndef SIM_GUARD 
#define SIM_GUARD

#include <fstream>
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <map>
#include <vector>
#include <set>
#include <list>
#include <math.h>

#include <sys/time.h>
#include <sys/stat.h>

#include "libs/seqan/align.h"
#include "libs/seqan/basic.h"
#include "libs/seqan/score.h"
#include "libs/seqan/stream.h"
#include "error.hpp"


/**
 * SIMILARITY
 *  Namespace similarity functions 
 *  Includes distance functions, as well as sequence alignment functions (SEQAN)
 */
namespace SIMILARITY{
	//Euclidean
	double euclidean(std::map<std::string, unsigned>& , std::map<std::string,unsigned>& );
	double euclidean(std::vector<unsigned>& , std::vector<unsigned>& );

	//Cosine Similarity
	double cosine(std::map<unsigned, unsigned>& , std::map<unsigned,unsigned>& );
	double cosine(std::vector<unsigned>& , std::vector<unsigned>& );

	//SEQAN Library for sequence alignment
	using namespace seqan;
	typedef String<char> TSequence;
	typedef Align<TSequence, ArrayGaps> TAlign;
	typedef Row<TAlign>::Type TRow;
	typedef Iterator<TRow>::Type TRowIterator;

	static TAlign s_Align;
	
	void initAlignment();
	int align(std::list<std::string>&, std::list<std::string>&, bool output = false);
	double alignScore();
	void printAlignment();

	//Custom Scoring Matrix
	typedef Score<int, ScoreMatrix<Circuit_Alpha, CircuitScoringMatrix> > TScoreMatrix;
	static TScoreMatrix s_Score(-5, -1); //-5 for gap penalty...-1 for extended gap penalty

	template <typename TScoreValue, typename TSequenceValue, typename TSpec>
		void showScoringMatrix(Score<TScoreValue, ScoreMatrix<TSequenceValue, TSpec> > const & scoringScheme){
			// Print top row.
			for (unsigned i = 0; i < ValueSize<TSequenceValue>::VALUE; ++i)
				std::cout << "\t" << TSequenceValue(i);
			std::cout << std::endl;

			// Print each row.
			for (unsigned i = 0; i < ValueSize<TSequenceValue>::VALUE; ++i){
				std::cout << TSequenceValue(i);
				for (unsigned j = 0; j < ValueSize<TSequenceValue>::VALUE; ++j)
					std::cout << "\t" << score(scoringScheme, TSequenceValue(i), TSequenceValue(j));
				std::cout << std::endl;
			}
		}
	
	
	//Tanimoto's similarity 
	int findMinDistance(std::map<unsigned, unsigned>& , std::set<unsigned>& , unsigned , std::map<unsigned, unsigned>::iterator& );
	double tanimoto(std::set<int>& , std::set<int>& );
	double tanimoto(std::map<unsigned, unsigned>&, std::map<unsigned, unsigned>&);
	double tanimotoWindow(std::map<unsigned, unsigned> , std::map<unsigned,unsigned> );
	double tanimotoWindow_size(std::map<unsigned, unsigned>& , std::map<unsigned,unsigned>& );


	unsigned hammingDistance(unsigned long , unsigned long );

	double calculateSimilarity(std::map<unsigned, unsigned>&,
		std::map<unsigned, unsigned>&);

}

















#endif
