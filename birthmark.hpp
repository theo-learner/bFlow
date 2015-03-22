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

#include "feature.hpp"
#include "error.hpp"

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"

class Birthmark{
	private: 
		static const unsigned m_NumBin = 94;

		int m_ID;                                 //ID of the circuit
		std::string m_Name;                       //Name of the circuit

		//FUNCTIONAL
		std::list<std::string> m_MaxSequence;     //Maximun datapath sequences
		std::list<std::string> m_MinSequence;     //Minimum datapath sequences
		std::list<std::string> m_AlphaSequence;   //Sequences with most unique ops

		//CONSTANT
		std::set<int> m_Constants;                //Constants in the circuit

		//STAT
		std::string m_Statstr;

		//STRUCTURAL
		//Name of feature, map of the size of feature : Num of occurance
		std::map<std::string, Feature*> m_Fingerprint; //Fingerprint of circuit

	public:
		Birthmark();
		Birthmark(rapidxml::xml_node<>*);
		~Birthmark();

		void getMaxSequence(std::list<std::string>&);
		void getMinSequence(std::list<std::string>&);
		void getAlphaSequence(std::list<std::string>&);
		void getConstants(std::set<int>&);
		void getBinnedConstants(std::vector<unsigned>&);         //Bins the constants into a histogram
		void getFingerprint(std::map<std::string, Feature*> &);
		double getAvgSequenceLength();                           //Gets AVG SEQ LEN of all SEQ
		std::string getName();
		int getID();
		unsigned getNumFPSubcomponents();
		std::string getStatstr();
		
		void setMaxSequence(std::list<std::string>&);
		void setMinSequence(std::list<std::string>&);
		void setAlphaSequence(std::list<std::string>&);
		void setConstants(std::set<int>&);
		void setFingerprint(std::map<std::string, Feature*> &);
		void setName(std::string);
		void setID(int);
		void setStatstr(std::string);
		
		void addMaxSequence(std::string);
		void addMinSequence(std::string);
		void addAlphaSequence(std::string);
		void addConstant(int);
		void addFingerprint(std::string, Feature*);
		void addFingerprint(std::string, unsigned , unsigned);
		
		bool importXML(rapidxml::xml_node<>*);
		
		void print();
};




#endif
