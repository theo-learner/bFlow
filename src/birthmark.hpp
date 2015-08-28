/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  birthmark.hpp
	@    Datastructure for holding  birthmark
	@  
	@  @AUTHOR:Kevin Zeng
	  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/


#ifndef BIRTHMARK_GUARD
#define BIRTHMARK_GUARD 

#include <stdlib.h> 
#include <stdio.h>
#include <string>
#include <vector>
#include <list>
#include <map>
#include <set>

#include "error.hpp"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"
#include "strtk/strtk.hpp"

struct sGram{
	std::string next;
	std::vector<std::vector<int> > linenum;
};


class Birthmark{
	private: 
		static const unsigned m_NumBin = 94;
		
		std::map<std::string, sGram> m_ktable;    //Used primarily for db
		std::list<std::string> m_EndGrams;          //End grams (Used primarily for ref)

		int m_ID;                                 //ID of the circuit
		std::string m_Name;                       //Name of the circuit
		std::string m_TopFile;                       //Name of the circuit

		//FUNCTIONAL
		std::list<std::string> m_MaxSequence;     //Maximun datapath sequences
		std::list<std::string> m_MinSequence;     //Minimum datapath sequences
		std::list<std::string> m_AlphaSequence;   //Sequences with most unique ops

		//CONSTANT
		std::set<int> m_Constants;                //Constants in the circuit
		std::vector<unsigned> m_BinnedConstants;

		//STAT
		std::string m_Statstr;
		std::vector<int> m_StatstrV;

		//STRUCTURAL
		//Name of feature, map of the size of feature : Num of occurance
		std::map<std::string, unsigned> m_Fingerprint; //Fingerprint of circuit

		//KGRAM
		//std::vector<std::set<std::string> >m_kgramset;
		//std::vector<int> m_kgramsetc;
		std::map<std::string, int> m_kgramset;
		std::map<std::string, int> m_kgramlist;
		std::map<std::string, std::vector<std::vector<int> > >m_kgramline;

		std::vector<std::map<std::string, int> > m_kgramcount;
		std::map<std::map<std::string, int>, int > m_kgramfreq;
		//std::set<std::map<std::string, int> > m_kgramfreq;



	public:
		Birthmark();
		Birthmark(rapidxml::xml_node<>*);
		~Birthmark();

		void getMaxSequence(std::list<std::string>&);
		void getMinSequence(std::list<std::string>&);
		void getAlphaSequence(std::list<std::string>&);
		void getConstants(std::set<int>&);
		void getKGramSet(std::map<std::string, int>&);
		void getKGramList(std::map<std::string, int>&);
		void getKGramCounter(std::vector<std::map<std::string, int> > &);
		void getKGramFreq(std::map<std::map<std::string, int>, int > &);
		int getKGramFreq();
		int getKGramSetSize();
		int getKGramListSize();
		int getKGramCounterSize();
		void getStat(std::vector<int>&);
		void getBinnedConstants(std::vector<unsigned>&);         //Bins the constants into a histogram
		void getBinnedConstants2(std::vector<unsigned>&);         //Bins the constants into a histogram
		void getFingerprint(std::map<std::string, unsigned> &);
		double getAvgSequenceLength();                           //Gets AVG SEQ LEN of all SEQ
		std::string getName();
		std::string getFileName();
		int getID();
		unsigned getNumFPSubcomponents();
		std::string getStatstr();
		void getEndGrams(std::list<std::string> &);
		void getEndGrams(std::list<std::string> &, int); //Given a line number
		std::string getFuture(std::string, std::set<int>&);

		void setMaxSequence(std::list<std::string>&);
		void setMinSequence(std::list<std::string>&);
		void setAlphaSequence(std::list<std::string>&);
		void setConstants(std::set<int>&);
		void setFingerprint(std::map<std::string, unsigned> &);
		void setName(std::string);
		void setID(int);
		void setStatstr(std::string);
		
		void addMaxSequence(std::string);
		void addMinSequence(std::string);
		void addAlphaSequence(std::string);
		void addConstant(int);
		void addConstant(int, int);
		void addFingerprint(std::string, unsigned);
		void addFingerprint(std::string, unsigned , unsigned);
		void addKTable(std::string, std::vector<std::vector<int> >& );
		
		bool importXML(rapidxml::xml_node<>*);
		
		void print();
};




#endif
