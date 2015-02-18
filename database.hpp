/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@      database.hpp
	@      
	@      @AUTHOR:Kevin Zeng
	@      Copyright 2012 – 2013 
	@      Virginia Polytechnic Institute and State University
	@
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

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"

//Used to sort the id and name by the score
struct Score{
	double score;
	unsigned id;
	std::string name;
};

//Used to compare the cScore so that it is sorted by the score
struct setCompare{
	bool operator()(const Score& lhs, const Score& rhs) const{
		return lhs.score >= rhs.score;
	}
};


class Database{
	private:
		rapidxml::xml_document<> m_XML;
		//rapidxml::xml_node<>* m_Root;
		
		std::list<Birthmark*> m_Database;

	public:
		Database();
		Database(std::string);
		~Database();
		bool importDatabase(std::string);   //PARAM: File Name
	  void searchDatabase(Birthmark*);

		void printXML();
		void print();
};


#endif
