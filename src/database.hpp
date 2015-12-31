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
	double klc2;
	double klr;
	double kfc;
	double kfr;
	double nf;
	double ns;
	double nc;
	double stat;
	unsigned id;
	std::string name;
	std::string direction;
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


struct sResult{
	std::vector<std::string> topMatch;
	std::vector<double> topScore;

	std::vector<std::string> okayMatch;
	std::vector<double> okayScore;

	std::vector<std::string> topContain;
	std::vector<std::string> conDir;
	std::vector<double> conRScore;
	std::vector<double> conCScore;
	std::vector<double> conCScore1;
	std::vector<double> conCScore2;
	double topNext;
	std::string topNextCircuit;

	std::string ranked_result_r; //resemblance rank
	std::string ranked_result_c; //containment rank
};



enum SearchType {
	eSimilarity,
	ePredict,
	eTrust
};

struct s_db_setting{
	bool allsim;                  //Performs all the Similarity matching to compare
	bool show_all_result;         //Shows the entire ranking instead of just 10
	bool suppressOutput;          //Suppresses the output
	bool partialMatch;            //Performs partial q-gram matching with KLR
	bool countMatch;              //Takes the count of the q-grams into account
	bool backEndProductivity;     //This is set for running the actual backend
	SearchType searchType;        //Search type: ePredict, eTrust, eSimilarity
	std::string kgramSimilarity;  //The type of q-gram scheme to use: KLR, KLC, KFR, KFC
};


class Database{
	private:
		rapidxml::xml_document<> m_XML;
		std::vector<Birthmark*> m_Database;
    std::map<std::string, std::vector<int> > m_IDatabase;
		bool m_SuppressOutput;
		std::string m_KVal;
		int m_KInt;
		SearchType m_SearchType;


		//k-1 string....map of the count, and the last letter (last letter is the suggestion)
		std::map<std::string, sGram2> m_KGramList;
		//std::map<std::string, int> m_KGramSet;

	public:
		Database();
		Database(SearchType);

		Database(std::string);
		Database(std::string, SearchType);
		~Database();


		int t_CurLine;
		s_db_setting* m_Settings;

		bool importDatabase(std::string);   //PARAM: File Name
		bool invertDatabase();   //PARAM: File Name
	  sResult* searchDatabase(Birthmark*);  
	  sResult* searchIDatabase(Birthmark*);  
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

		void printStats();
		void printSettings();
};


#endif
