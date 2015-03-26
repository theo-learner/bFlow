/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  database.hpp
	@      
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#ifndef DATABASE_GUARD
#define DATABASE_GUARD

#include <stdlib.h> 
#include <stdio.h>
#include <string>
#include <cstring>
#include <vector>
#include <list>
#include <map>
#include <set>
#include <fstream>
#include <iostream>

#include "birthmark.hpp"
#include "similarity.hpp"
#include "error.hpp"

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"

/**
 * Score
 *  Used to sort the id and name by the score
 *  Primarily to ease the sorting process
 */
struct Score{
	double score;
	unsigned id;
	std::string name;
};

/**
 * setCompare 
 *  Comparator for input to set templace 
 *  Used to compare the score of the Score object above
 */
struct setCompare{
	bool operator()(const Score& lhs, const Score& rhs) const{
		return lhs.score >= rhs.score;
	}
};




class Database{
	private:
		rapidxml::xml_document<> m_XML;
		std::vector<Birthmark*> m_Database;
		bool m_SuppressOutput;

	public:
		Database();
		Database(std::string);
		~Database();

		bool importDatabase(std::string);   //PARAM: File Name
	  void searchDatabase(Birthmark*);
		void compareBirthmark(Birthmark*, Birthmark*);
	  void autoCorrelate();

		Birthmark* getBirthmark(unsigned);
		unsigned getSize();
		void suppressOutput();

		void printXML();
		void print();
};


#endif
