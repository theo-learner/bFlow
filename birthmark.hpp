/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  birthmark.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
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

class Birthmark{
	private: 
		int m_ID;
		std::string m_Name;
		std::list<std::string> m_MaxSequence;
		std::list<std::string> m_MinSequence;
		std::set<int> m_Constants;

		//Name of feature, map of the size of the feature and how many there are
		std::map<std::string, Feature*> m_Fingerprint;

	public:
		Birthmark();
		~Birthmark();
		void getMaxSequence(std::list<std::string>&);
		void getMinSequence(std::list<std::string>&);
		void getConstants(std::set<int>&);
		void getFingerprint(std::map<std::string, Feature*> &);
		std::string getName();
		int getID();
		
		void setMaxSequence(std::list<std::string>&);
		void setMinSequence(std::list<std::string>&);
		void setConstants(std::set<int>&);
		void setFingerprint(std::map<std::string, Feature*> &);
		void setName(std::string);
		void setID(int);
		
		void addMaxSequence(std::string);
		void addMinSequence(std::string);
		void addConstant(int);
		void addFingerprint(std::string, Feature*);
		void addFingerprint(std::string, unsigned , unsigned);
		
		void print();
};




#endif
