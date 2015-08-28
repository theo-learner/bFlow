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
#include <algorithm>
#include <vector>
#include <list>
#include <map>
#include <set>
#include <fstream>
#include <iostream>

#include "birthmark.hpp"
#include "similarity.hpp"
#include "error.hpp"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_print.hpp"

/**
 * Score
 *  Used to sort the id and name by the score
 *  Primarily to ease the sorting process
 */
struct Score{
	double score;
	double fScore;
	double sScore;
	double cScore;
	double tScore;
	double ksc;
	double ksr;
	double klc;
	double klr;
	double kfc;
	double kfr;
	double nf;
	double ns;
	double nc;
	double stat;
	unsigned id;
	std::string name;
	Birthmark* bm;
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



struct sGram2{
	//Next operation/letter, frequency
	std::map<std::string, int> next;
	std::map<std::string, std::vector<std::string> > files;


	//File name,  list of line numbers
	//std::map<std::string, std::vector<int> > filelinemap;

};





class Database{
	private:
		rapidxml::xml_document<> m_XML;
		std::vector<Birthmark*> m_Database;
		bool m_SuppressOutput;
		std::string m_KVal;
		int m_KInt;


		//k-1 string....map of the count, and the last letter (last letter is the suggestion)
		std::map<std::string, sGram2> m_KGramList;
		//std::map<std::string, int> m_KGramSet;

	public:
		Database();
		Database(std::string);
		~Database();


		int t_CurLine;
		bool importDatabase(std::string);   //PARAM: File Name
	  void searchDatabase(Birthmark*, std::string, bool printall = false);  //String: KFLags
		void compareBirthmark(Birthmark*, Birthmark*);
		bool isBirthmarkEqual(Birthmark*, Birthmark*);
	  void autoCorrelate();
	  void autoCorrelate2();

		void processKGramDatabase();
		void crossValidation();

		std::string findLargestGram(std::string);

		Birthmark* getBirthmark(unsigned);
		//File to get lines from, Lines to get from the file
		void getFutureLines(std::string, std::set<int>& );
		void getFutureOp(Birthmark* );
		unsigned getSize();
		std::string getKVal();
		void suppressOutput();

		void printXML();
		void print();
		void printKTable();
};


#endif
