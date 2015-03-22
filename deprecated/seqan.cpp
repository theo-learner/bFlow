#include "libs/seqan/align.h"
#include <iostream>
using namespace seqan;
	typedef String<char> TSequence;
	typedef Align<TSequence, ArrayGaps> TAlign;
	typedef Row<TAlign>::Type TRow;
	typedef Iterator<TRow>::Type TRowIterator;

void printAlignment(TAlign align){
    TRowIterator it1 = begin(row(align,0));
    TRowIterator it2 = begin(row(align,1));
    TRowIterator it1End = end(row(align,0));
    TRowIterator it2End = end(row(align,1));
		for (; it1 != it1End; ++it1){
        if (isGap(it1))    std::cout << gapValue<char>();
        else              std::cout << *it1;
    }
    std::cout << std::endl;
		
    it1 = begin(row(align,0));
    it2 = begin(row(align,1));
		for (; it1 != it1End; ++it1){
        if (isGap(it1))         std::cout << "*" ;
        else if(isGap(it2))     std::cout << "*" ;
        else if(*it2 != *it1)  	std::cout << "X";
				else                    std::cout << "|";
				++it2;
    }
    std::cout << std::endl;
    
		it1 = begin(row(align,0));
    it2 = begin(row(align,1));
    for (; it2 != it2End; ++it2){
        if (isGap(it2))   std::cout << gapValue<char>();
        else              std::cout << *it2;
    }
    std::cout << std::endl;
    std::cout << std::endl;
}

int main(){



	TSequence seq1 = "CDFGHC";
	TSequence seq2 = "CDEFGAHC";

	TSequence seq3 = "FNNMNNMNNMNFMMMMMMMFMMMMMMNFMMMMEFMMMFMMMMMMEFMMEFMMAFNNMMMMEN";
	TSequence seq4 = "NFMNMLMAFMNEMFNNLNENLFMNMFMNMLMAFMNEMFNNLNLEN";
	TSequence seq5 = "LLNFMMMFMMEFMMLFMMLLLNFMMMFMMEFMMLFMML";
	TSequence seq6 = "NMNMFMMLMMENFMMFMMFMMFMMLEFMMLMENFMMFMMFMMFMMFMMLFMMMENFMMFMMFMMFMMFMMLEFMMLMENFMMFMMFMMFMMFMMLFMMMENFMMFMMFMMFMMFMMLEFMMLMENFMMFMMFMMFMMFMMLEFMLFMMFMMFMMFMMFMMLFMMMMMENEFMLFMMFMMFMMFMMFMMLEFMMLMMMMMMENEFMLFMMLEFMMLMENFMM";


	TAlign align;
	resize(rows(align), 2);
	assignSource(row(align, 0), seq5);
	assignSource(row(align, 1), seq6);

	int score = localAlignment(align, Score<int, Simple>(10, -10, -8, -1));
	std::cout<< "LOW SCORE: " << score << std::endl;
	std::cout<<value(stringSet(align), 1)<<std::endl;
	printAlignment(align);

	score = globalAlignment(align, Score<int, Simple>(10, -10, -8, -1));
	std::cout<< "LOW SCORE: " << score << std::endl;
	printAlignment(align);
	
	assignSource(row(align, 0), seq4);
	assignSource(row(align, 1), seq5);

	score = localAlignment(align, Score<int, Simple>(10, -10, -8, -1));
	std::cout<< "HI SCORE: " << score << std::endl;
	printAlignment(align);
	
	score = globalAlignment(align, Score<int, Simple>(10, -10, -8, -1));
	std::cout<< "HI SCORE: " << score << std::endl;
	printAlignment(align);
	
	return 0;

}
