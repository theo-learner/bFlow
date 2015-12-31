#include "seqan/align.h"
#include "seqan/basic.h"
#include "seqan/score.h"
#include "seqan/stream.h"

#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <map>
#include <vector>
#include <set>
#include <list>
#include <math.h>
	
  using namespace seqan;
	typedef String<char> TSequence;
	typedef Align<TSequence, ArrayGaps> TAlign;
	typedef Row<TAlign>::Type TRow;
	typedef Iterator<TRow>::Type TRowIterator;

	static TAlign s_Align;
	
  //Custom Scoring Matrix
	typedef Score<int, ScoreMatrix<Circuit_Alpha, CircuitScoringMatrix> > TScoreMatrix;
	static TScoreMatrix s_Score(-3, -1); //-5 for gap penalty...-1 for extended gap penalty

void printAlignment(){
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
}



int main(){
	resize(rows(s_Align), 2);
	setDefaultScoreMatrix(s_Score, CircuitScoringMatrix());
	
  std::string str1 = "-MB*+{}/SML=CFRN!H~^)()PD|!T";
  std::string str2 = "-MB*+{}/SML=CFRN!H~^)(PD|!T";
  TSequence seq1 = str1;
	TSequence seq2 = str2;
  printf(" %10s -- %10s\n", str1.c_str(), str2.c_str());
	assignSource(row(s_Align, 0), seq1);
	assignSource(row(s_Align, 1), seq2);
	
	//Alignment of the sequence
	int score = localAlignment(s_Align, s_Score);
  printAlignment();
  printf("SCORE: %d\n", score);



  return 0;
}
