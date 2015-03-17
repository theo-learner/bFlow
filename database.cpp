/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@      database.cpp
	@      
	@      @AUTHOR:Kevin Zeng
	@      Copyright 2012 – 2013 
	@      Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "database.hpp"
using namespace rapidxml;

Database::Database(){	
	SIMILARITY::initAlignment();
}

Database::Database(std::string file){	
	SIMILARITY::initAlignment();
	importDatabase(file);
}

Database::~Database(){
	/*
	std::list<Birthmark*>::iterator it;
	for(it = m_Database.begin(); it != m_Database.end(); it++)
		*/
	for(unsigned int i = 0; i < m_Database.size(); i++) 
		delete m_Database[i];
}

bool Database::importDatabase(std::string path){
	printf("[DATABASE] -- Importing database from XML file: %s\n", path.c_str());
	m_XML.clear();

	//Open XML File for parsing
	std::ifstream xmlfile;
	xmlfile.open(path.c_str());
	if (!xmlfile.is_open())	{
		fprintf(stderr, "[ERROR] -- Cannot open the xml file for import...exiting\n");
		fprintf(stderr, "\n***************************************************\n\n");
		exit(-1);
	}


	//Read in contents in the XML File
	std::string xmlstring = "";
	std::string xmlline;
	while(getline(xmlfile, xmlline))
		xmlstring += xmlline + "\n";

	xml_document<> xmldoc;
	char* cstr = new char[xmlstring.size() + 1];
	strcpy(cstr, xmlstring.c_str());


	//Parse the XML Data
	m_XML.parse<0>(cstr);
	//printXML();
	printf("[DATABASE] -- XML File imported. Parsing...");

	enum Error {
		eDatabaseNotEmpty,
		eNodeNull,
		eNoAttr, 
		eDATABASE_FE,
		eCIRCUIT_FE,
		eCNAME_FE, 
		eSC_FE,
		eFeature_FE,
		eCIRCUIT_ATTR_FE,
		eNoAttrSC
	};

	try{
		if(m_Database.size() != 0) throw eDatabaseNotEmpty;
		xml_node<>* rootNode= m_XML.first_node();
		if(rootNode == NULL) throw eNodeNull;

		//Make sure first node is DATABASE
		std::string rootNodeName = rootNode->name();
		if(rootNodeName != "DATABASE") throw eDATABASE_FE;
		xml_node<>* cktNode= rootNode->first_node();

		//Look through the circuits in the Database
		while (cktNode!= NULL){
			Birthmark* bm = new Birthmark();
			if(!bm->importXML(cktNode)) throw eCIRCUIT_FE;

			//Store the fingerprintlist of the circuit 
			m_Database.push_back(bm);
			cktNode = cktNode->next_sibling(); 
		}

	}

	catch (Error error){
		printf("\n");
		if(error == eNodeNull) printf("[ERROR] -- XML root node is empty\n");
		else if(error == eNodeNull) printf("[ERROR] -- Database is not empty. Aborting import\n");
		else if(error == eNoAttrSC) printf("[ERROR] -- XML node expected a size or count attribute \n");
		else if(error == eNoAttr) printf("[ERROR] -- XML node expected an attribute\n");
		else if(error == eDATABASE_FE) printf("[ERROR] -- XML File has a different format then expected (DATABASE)\n");
		else if(error == eCIRCUIT_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT)\n");
		else if(error == eCIRCUIT_ATTR_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT name or id attribute is missing)\n");
		else if(error == eFeature_FE) printf("[ERROR] -- XML File has a different format then expected (ATTR size or count attribute is missing)\n");
		else if(error == eCNAME_FE) printf("[ERROR] -- XML File has a different format then expected (Size Count has a value that is unknown)\n");

		printf("\n");
		return false;
	}


	printf("COMPLETE!\n\n");
	return true;

}

void Database::searchDatabase(Birthmark* reference, std::vector<double>& fsim){
	//Get FComponent
	std::list<std::string> maxRef, minRef, alphaRef;
	reference->getMaxSequence(maxRef);
	reference->getMinSequence(minRef);
	reference->getAlphaSequence(alphaRef);

/*
	std::list<Birthmark*>::iterator iList;
	for(iList = m_Database.begin(); iList != m_Database.end(); iList++){
		*/
	fsim.reserve(m_Database.size());
	std::set<Score, setCompare> avgscores;
	std::set<Score, setCompare> scores;
	std::set<Score, setCompare> sims;
	for(unsigned int i = 0; i < m_Database.size(); i++) {
		//printf("-------------------------------------------------------\n");
		printf("[DB] -- Comparing reference to %s\n", m_Database[i]->getName().c_str());
		//printf("-------------------------------------------------------\n");
		//Align the max sequences
		//printf("     -- Comparing functional components...\n");
		printf("MAX\n");
		std::list<std::string> maxDB;
		m_Database[i]->getMaxSequence(maxDB);
		int sc;
		double maxScore = SIMILARITY::align(maxRef, maxDB, sc);
		printf("TOTAL SCORE: %4d\tAVG: %f\n", sc, double(sc) / ((double)maxRef.size() * (double)maxDB.size()));;
		int totalScore = sc;
		double totalAvg = (double(sc) / ((double)maxRef.size() * (double)maxDB.size())) * 0.75;

		//Align the min sequences
		printf("MIN\n");
		std::list<std::string> minDB;
		m_Database[i]->getMinSequence(minDB);
		double minScore = SIMILARITY::align(minRef, minDB, sc);
		totalAvg += double(sc) / ((double)minRef.size() * (double)minDB.size());
		printf("TOTAL SCORE: %4d\tAVG: %f\n", sc, double(sc) / ((double)minRef.size() * (double)minDB.size()));
		totalScore += sc;

		//Align the min sequences
		printf("ALPHA\n");
		std::list<std::string> alphaDB;
		m_Database[i]->getAlphaSequence(alphaDB);
		double alphaScore = SIMILARITY::align(alphaRef, alphaDB, sc);
		totalAvg += (double(sc) / ((double)alphaRef.size() * (double)alphaDB.size())) * 3;
		printf("TOTAL SCORE: %4d\tAVG: %f\n", sc, double(sc) / ((double)alphaRef.size() * (double)alphaDB.size()));
		totalScore += sc;

		double axW = 0.3;
		double inW = 0.1;
		double alW = 0.6;

		double fScore = (maxScore*axW + minScore* inW + alphaScore * alW);
		//printf("        * FSCORE: %f\n\n",fScore);
		printf("\n\n");

		Score score;
		score.id = m_Database[i]->getID();
		score.name = m_Database[i]->getName();
		score.score = totalScore;
		printf("TOTAL SCORE: %d\n", totalScore);
		
		Score score2;
		score2.id = m_Database[i]->getID();
		score2.name = m_Database[i]->getName();
		score2.score = totalAvg;
		printf("TOTAL AVG: %f\n", totalAvg);
		
		Score sim;
		sim.id = m_Database[i]->getID();
		sim.name = m_Database[i]->getName();
		sim.score = fScore;

		avgscores.insert(score2);
		scores.insert(score);
		sims.insert(sim);
	}
	printf("###############################################################\n");
	printf("###                    SEARCH COMPLETE                      ###\n");
	printf("###############################################################\n");
	int count = 1;
	std::set<Score, setCompare>::iterator iSet;
	printf("\n\n###############################################################\n\n");
	for(iSet = avgscores.begin(); iSet != avgscores.end(); iSet++){
		printf("RANK: %2d   ID: %2d   SCR: %6.2f   CKT:%s\n", count, iSet->id, iSet->score, iSet->name.c_str());
		count++;
	}
	printf("\n");
	count = 1;
	for(iSet = scores.begin(); iSet != scores.end(); iSet++){
		printf("RANK: %2d   ID: %2d   SCR: %6.2f   CKT:%s\n", count, iSet->id, iSet->score, iSet->name.c_str());
		count++;
	}
	printf("\n\n###############################################################\n\n");
	count = 1;
	for(iSet = sims.begin(); iSet != sims.end(); iSet++){
		printf("RANK: %2d   ID: %2d   SCR: %6.2f   CKT:%s\n", count, iSet->id, iSet->score, iSet->name.c_str());
		count++;
	}
	printf("\n");
}

void Database::searchDatabase(Birthmark* reference){
	//Get FComponent
	std::list<std::string> maxRef, minRef;
	reference->getMaxSequence(maxRef);
	reference->getMinSequence(minRef);
	
	//Get SComponent
	std::map<std::string, Feature*> featureRef;
	reference->getFingerprint(featureRef);
	
	//Get CComponent
	std::set<int> constantRef;
	reference->getConstants(constantRef);

	std::set<Score, setCompare> results;

/*
	std::list<Birthmark*>::iterator iList;
	for(iList = m_Database.begin(); iList != m_Database.end(); iList++){
		*/
	for(unsigned int i = 0; i < m_Database.size(); i++) {
		printf("[DB] -- Comparing reference to %s\n", m_Database[i]->getName().c_str());
		//Align the max sequences
		printf("       -- Comparing functional components...\n");
		printf("MAx\n");
		std::list<std::string> maxDB;
		m_Database[i]->getMaxSequence(maxDB);
		double maxScore = SIMILARITY::align(maxRef, maxDB);

		//Align the min sequences
		printf("Min\n");
		std::list<std::string> minDB;
		m_Database[i]->getMinSequence(minDB);
		double minScore = SIMILARITY::align(minRef, minDB);

		double fScore = (maxScore*0.650 + minScore* 0.350);
		printf(" * FSCORE: %f\n",fScore);
		


		printf(" -- Comparing Structural Components...\n");
		std::map<std::string, Feature*> featureDB;
		std::map<std::string, Feature*>::iterator iFeat;
		std::map<std::string, Feature*>::iterator iFeatRef;
		m_Database[i]->getFingerprint(featureDB);

		double sScore= 0.0;
		double tsim;
		for(iFeat = featureDB.begin(); iFeat != featureDB.end(); iFeat++){
			std::string type = iFeat->first;
			iFeatRef = featureRef.find(type);

			if(iFeatRef == featureRef.end()) {
				printf("[WARNING] -- searchDatabase: Feature Type (%s) not found\n", type.c_str());
				continue;
			}
			
			std::map<unsigned, unsigned> featRef;
			featureRef[type]->getFeature(featRef);

			std::map<unsigned, unsigned> featDB;
			iFeat->second->getFeature(featDB);

			tsim = SIMILARITY::calculateSimilarity(featRef, featDB);
			if(tsim >= 0)
				sScore += tsim;
			else
				sScore += (-1.0 * tsim);
		}

		sScore /= featureDB.size(); 
		printf("  * SSCORE: %f\n", sScore);








		printf(" -- Comparing Constant Components....\n");
		std::set<int> constantDB;
		m_Database[i]->getConstants(constantDB);

		double cScore;
		if(constantRef.size() == 0 && constantDB.size() == 0) cScore = 1.0;
		else cScore = SIMILARITY::tanimoto(constantRef, constantDB);
		printf("  * CSCORE: %f\n", cScore);



		Score result;
		result.id = m_Database[i]->getID();
		result.name = m_Database[i]->getName();
		result.score = fScore*100.0*0.67 +
		               sScore*100.0*0.21 + 
     				   cScore*100.0*0.12;

		results.insert(result);
		printf(" ## OVERALL SCORE: %f\n\n", result.score);
	}
	printf("###############################################################\n");
	printf("###                    SEARCH COMPLETE                      ###\n");
	printf("###############################################################\n");
	int count = 1;
	std::set<Score, setCompare>::iterator iSet;
	for(iSet = results.begin(); iSet != results.end(); iSet++){
		printf("RANK: %2d   ID: %2d   SCR: %6.2f   CKT:%s\n", count, iSet->id, iSet->score, iSet->name.c_str());
		count++;
	}

}
		
Birthmark* Database::getBirthmark(unsigned index){
	return m_Database[index];
}


void Database::printXML(){
	std::cout << m_XML << "\n";
}


void Database::print(){
	/*
	std::list<Birthmark*>::iterator iList;
	for(iList = m_Database.begin(); iList != m_Database.end(); iList++){
		*/
	for(unsigned int i = 0; i < m_Database.size(); i++) 
		m_Database[i]->print();
}
