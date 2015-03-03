/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@ 
	@
	@  SIMILARITY.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
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


namespace SIMILARITY{
	int findMinDistance(std::map<unsigned, unsigned>& , std::set<unsigned>& , unsigned , std::map<unsigned, unsigned>::iterator& );
	double tanimoto(std::set<int>& , std::set<int>& );
	double tanimoto(std::map<unsigned, unsigned>&, std::map<unsigned, unsigned>&);
	double tanimotoWindow(std::map<unsigned, unsigned> , std::map<unsigned,unsigned> );
	double tanimotoWindow_size(std::map<unsigned, unsigned>& , std::map<unsigned,unsigned>& );




	double euclideanDistanceWNorm(std::vector<double>& , std::vector<double>&);
	double euclideanDistance(std::vector<double>& , std::vector<double>&);
	unsigned hammingDistance(unsigned long , unsigned long );


	double calculateSimilarity(std::map<unsigned, unsigned>&,
		std::map<unsigned, unsigned>&);

	//SEQAN Library for sequence alignment
	using namespace seqan;
	typedef String<char> TSequence;
	typedef Align<TSequence, ArrayGaps> TAlign;
	typedef Row<TAlign>::Type TRow;
	typedef Iterator<TRow>::Type TRowIterator;
	static TAlign s_Align;
	
	void initAlignment();
	double align(std::list<std::string>&, std::list<std::string>&);
	double alignScore();
	void printAlignment();
}


#endif
