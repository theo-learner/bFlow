/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  database.cpp
	@      
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "database.hpp"
using namespace rapidxml;

/**
 * Constructor
 *  Initializes alignment function for pairwise alignment
 */
Database::Database(){	
	SIMILARITY::initAlignment();
	m_SuppressOutput = false;
}

/**
 * Constructor
 *  Imports an existing database XML file
 *  Initializes alignment function for pairwise alignment
 */
Database::Database(std::string file){	
	SIMILARITY::initAlignment();
	importDatabase(file);
	m_SuppressOutput = false;
}

/**
 * Destructor 
 */
Database::~Database(){
	for(unsigned int i = 0; i < m_Database.size(); i++) 
		delete m_Database[i];
}










/**
 * importDatabase 
 *  Imports a database XML file into memory
 */
bool Database::importDatabase(std::string path){
	printf("[DATABASE] -- Importing database from XML file: %s\n", path.c_str());
	m_XML.clear();

	//Open XML File for parsing
	std::ifstream xmlfile;
	xmlfile.open(path.c_str());
	if (!xmlfile.is_open()) 
		throw cException("Database::importDatabase LINE: 54. Cannot open file");

	//Read in contents in the XML File
	std::string xmlstring = "";
	std::string xmlline;
	while(getline(xmlfile, xmlline))
		xmlstring += xmlline + "\n";

	xml_document<> xmldoc;
	char* cstr = new char[xmlstring.size() + 1];
	strcpy(cstr, xmlstring.c_str());

	m_XML.parse<0>(cstr);
	printf("[DATABASE] -- XML File imported. Parsing...");


	//Make sure Database doesn't have content TODO: Append database	
	if(m_Database.size() != 0) 
		throw cException("(Database::importDatabase:T1) Attempting to overwrite an existing database");

	xml_node<>* rootNode= m_XML.first_node();
	if(rootNode == NULL)
		throw cException("(Database::importDatabase:T2) Root node of XML is NULL");

	//Make sure first node is DATABASE
	std::string rootNodeName = rootNode->name();
	if(rootNodeName != "DATABASE")
		throw cException("(Database::importDatabase:T3) No Database Node found");

	xml_node<>* cktNode= rootNode->first_node();
	//Look through the circuits in the Database
	while (cktNode!= NULL){
		Birthmark* bm = new Birthmark();
		bm->importXML(cktNode);

		//Store the fingerprintlist of the circuit 
		m_Database.push_back(bm);
		cktNode = cktNode->next_sibling(); 
	}



	//Integrity check to make sure all components in the database have the same subcomponent types
	printf("[DB] -- Checking Database Integrity...");
	std::map<std::string, unsigned> fp;
	m_Database[0]->getFingerprint(fp);

	for(unsigned int i = 1; i < m_Database.size(); i++){
		std::map<std::string, unsigned> fp2;
		m_Database[i]->getFingerprint(fp2);

		std::map<std::string, unsigned>::iterator iFP1;
		std::map<std::string, unsigned>::iterator iFP2;
		iFP2 = fp2.begin();
		for(iFP1 = fp.begin(); iFP1 != fp.end(); iFP1++){
			assert(iFP1->first == iFP2->first);
			iFP2++;
		}
	}

	printf("COMPLETE!\n\n");
	return true;
}






void Database::compareBirthmark(Birthmark* bm1, Birthmark* bm2){
	std::list<std::string> max1, min1, alpha1;  //Functional
	std::list<std::string> max2, min2, alpha2;  //Functional
	bm1->getMaxSequence(max1);
	bm1->getMinSequence(min1);
	bm1->getAlphaSequence(alpha1);
	bm2->getMaxSequence(max2);
	bm2->getMinSequence(min2);
	bm2->getAlphaSequence(alpha2);
	
	
	std::map<std::string, unsigned> feature1, feature2;       //Structural
	bm1->getFingerprint(feature1);
	bm2->getFingerprint(feature2);

	
	std::vector<unsigned> constant1, constant2;                //Constant
	bm1->getBinnedConstants(constant1);
	bm2->getBinnedConstants(constant2);
		
		/////////////////////////////////////////////////////////////////////////////
		//   FUNCTIONAL SEQUENCE COMARPISON
		//     Score returned by alignment is all the alignemnt scores among the list
		//     Average to take into account different number os sequences
		//     Final functional score is the sum of all the scores
		/////////////////////////////////////////////////////////////////////////////
		printf("########################################################################\n");
		int maxScore = SIMILARITY::align(max1, max2, true);
		double fScore = (double(maxScore) / ((double)max1.size() * (double)max2.size())) * 0.75;
		printf("########################################################################\n\n\n");

		int minScore = SIMILARITY::align(min1, min2, true);
		fScore += double(minScore) / ((double)min1.size() * (double)min2.size()) * 2;
		printf("########################################################################\n\n\n");

		int alphaScore = SIMILARITY::align(alpha1, alpha2, true);
		fScore += (double(alphaScore) / ((double)alpha1.size() * (double)alpha2.size())) * 3;
		printf("########################################################################\n");
		printf("MAXSCORE: %4d\tAVG: %f\n", maxScore, double(maxScore) / ((double)max1.size() * (double)max2.size()));
		printf("MINSCORE: %4d\tAVG: %f\n", minScore, double(minScore) / ((double)min1.size() * (double)min2.size()));
		printf("ALPSCORE: %4d\tAVG: %f\n", alphaScore, double(alphaScore) / ((double)alpha1.size() * (double)alpha2.size()));
		printf("  * FSCORE: %f\n", fScore);





		/////////////////////////////////////////////////////////////////////////////
		//   STRUCTURAL SEQUENCE COMARPISON
		//     Score is the total euclidean distance of all the features 
		/////////////////////////////////////////////////////////////////////////////

		double sScore= 0.0;


			double tsim = SIMILARITY::euclidean(feature1, feature2);
			sScore += tsim;
		
		printf("  * SSCORE: %f\n", sScore);




		/////////////////////////////////////////////////////////////////////////////
		//   CONSTANT SEQUENCE COMARPISON
		//     Score is the total euclidean distance of binned constant vector 
		/////////////////////////////////////////////////////////////////////////////
		//printf(" -- Comparing Constant Components....\n");
		double cScore = SIMILARITY::euclidean(constant1, constant2);
		printf("  * CSCORE: %f\n", cScore);
		//bm1->print();
		//bm2->print();
}




/**
 * searchDatabase 
 *  Searches the database for a circuit similar to the reference 
 *  Outputs results in ranked order with circuits similar to reference
 */
void Database::searchDatabase(Birthmark* reference){
	//Get the components of the Reference circuit
	std::list<std::string> maxRef, minRef, alphaRef;  //Functional
	reference->getMaxSequence(maxRef);
	reference->getMinSequence(minRef);
	reference->getAlphaSequence(alphaRef);

	std::map<std::string, unsigned> featureRef;       //Structural
	reference->getFingerprint(featureRef);

	std::vector<unsigned> constantRef;                //Constant
	reference->getBinnedConstants(constantRef);

	std::vector<Score> fs;
	std::vector<Score> ss;
	std::vector<Score> cs;
	fs.reserve(m_Database.size());
	cs.reserve(m_Database.size());
	ss.reserve(m_Database.size());

	double maxf = 0.0;
	double minf = 10000000000.0;
	double maxs = 0.0;
	double mins = 10000000000.0;
	double maxc = 0.0;
	double minc = 10000000000.0;

	for(unsigned int i = 0; i < m_Database.size(); i++) {
		//printf("###########################################################################################################\n");
		if(!m_SuppressOutput)
			printf("[DB] -- Comparing reference to %s\n", m_Database[i]->getName().c_str());
		//printf("###########################################################################################################\n");

		/////////////////////////////////////////////////////////////////////////////
		//   FUNCTIONAL SEQUENCE COMARPISON
		//     Score returned by alignment is all the alignemnt scores among the list
		//     Average to take into account different number os sequences
		//     Final functional score is the sum of all the scores
		/////////////////////////////////////////////////////////////////////////////
		std::list<std::string> maxDB;
		m_Database[i]->getMaxSequence(maxDB);
		int maxScore = SIMILARITY::align(maxRef, maxDB);
		double fScore = (double(maxScore) / ((double)maxRef.size() * (double)maxDB.size())) * 0.75;
		//printf("MAXSCORE: %4d\tAVG: %f\n", maxScore, double(maxScore) / ((double)maxRef.size() * (double)maxDB.size()));;

		std::list<std::string> minDB;
		m_Database[i]->getMinSequence(minDB);
		int minScore = SIMILARITY::align(minRef, minDB);
		fScore += double(minScore) / ((double)minRef.size() * (double)minDB.size()) * 2;
		//printf("MINSCORE: %4d\tAVG: %f\n", minScore, double(minScore) / ((double)minRef.size() * (double)minDB.size()));

		std::list<std::string> alphaDB;
		m_Database[i]->getAlphaSequence(alphaDB);
		int alphaScore = SIMILARITY::align(alphaRef, alphaDB);
		fScore += (double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size())) * 3;
		//printf("ALPHA SCORE: %4d\tAVG: %f\n", alphaScore, double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size()));

		if(fScore > maxf)  maxf = fScore;
		if(fScore < minf)  minf = fScore;
		//printf("  * FSCORE: %f\n", fScore);





		/////////////////////////////////////////////////////////////////////////////
		//   STRUCTURAL SEQUENCE COMARPISON
		//     Score is the total euclidean distance of all the features 
		/////////////////////////////////////////////////////////////////////////////
		//printf(" -- Comparing Structural Components...\n");
		std::map<std::string, unsigned> featureDB;
		m_Database[i]->getFingerprint(featureDB);

		double sScore= 0.0;
			double tsim = SIMILARITY::euclidean(featureRef, featureDB);
			sScore += tsim;

		//Note: Don't care are features not accounted for in both since distance is 0
		//printf("  * SSCORE: %f\n", sScore);
		if(sScore> maxs)    maxs = sScore;
		if(sScore< mins)    mins = sScore;





		/////////////////////////////////////////////////////////////////////////////
		//   CONSTANT SEQUENCE COMARPISON
		//     Score is the total euclidean distance of binned constant vector 
		/////////////////////////////////////////////////////////////////////////////
		//printf(" -- Comparing Constant Components....\n");
		std::vector<unsigned> constantDB;
		m_Database[i]->getBinnedConstants(constantDB);
		double cScore = SIMILARITY::euclidean(constantRef, constantDB);

		//printf("  * CSCORE: %f\n", cScore);
		if(cScore > maxc)    maxc = cScore;
		if(cScore < minc)    minc = cScore;


		Score scoref;
		scoref.id = m_Database[i]->getID();
		scoref.name = m_Database[i]->getName();
		scoref.score = fScore;

		Score scores;
		scores.id = m_Database[i]->getID();
		scores.name = m_Database[i]->getName();
		scores.score = sScore;

		Score scorec;
		scorec.id = m_Database[i]->getID();
		scorec.name = m_Database[i]->getName();
		scorec.score = cScore;

		//Need to store for normalization later. Data is in different scales
		fs.push_back(scoref);
		ss.push_back(scores);
		cs.push_back(scorec);
	}

	if(!m_SuppressOutput){
		printf("###############################################################\n");
		printf("###                    SEARCH COMPLETE                      ###\n");
		printf("###############################################################\n");

		//Weights
		double fweight = 0.49;
		double sweight = 0.38;
		double cweight = 0.13;
		//Need to normalize data
		std::set<Score, setCompare> normalizedFinalScore;

		for(unsigned int i = 0; i < fs.size(); i++){
			//Normalization of the scores to the range of 0-1
			double newScoref = (double)(fs[i].score - minf) / (double)(maxf-minf);  
			//double newScores = (double)(ss[i].score - mins) / (double)(maxs-mins);
			//double newScorec = (double)(cs[i].score - minc) / (double)(maxc-minc);
			double newScores = (double)(log(ss[i].score+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
			double newScorec = (double)(log(cs[i].score+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));


			double newScore = newScoref * fweight * 100.0 + 
				(1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
				(1 - newScorec) * cweight * 100.0;

			Score sim;
			sim.id = fs[i].id;
			sim.name = fs[i].name;
			sim.score = newScore;
			sim.f = fs[i].score;
			sim.c = cs[i].score;
			sim.s = ss[i].score;
			sim.nf = newScoref;
			sim.nc = newScorec;
			sim.ns = newScores;
			normalizedFinalScore.insert(sim);
		}


		int count = 1;
		std::set<Score, setCompare>::iterator iSet;
		for(iSet = normalizedFinalScore.begin(); iSet != normalizedFinalScore.end(); iSet++){
			printf("R: %2d  S: %6.2f   F: %6.2f   S: %6.2f C: %6.2f NF:%6.2f NS:%6.2f NC:%6.2f\t\tCKT:%s\n", count, iSet->score,  iSet->f, iSet->s, iSet->c, iSet->nf, 1-iSet->ns, 1-iSet->nc, iSet->name.c_str());
			//printf(" %2d & %6.2f & %s\n", count, iSet->score, iSet->name.c_str()); //latex table
			if(count == 20) break;
			count++;
		}


		printf("MAXF: %f\n", maxf);
		printf("MINF: %f\n", minf);
		printf("MAXS: %f\n", maxs);
		printf("MINS: %f\n", mins);
		printf("MAXC: %f\n", maxc);
		printf("MINC: %f\n", minc);
	}
}



/**
 * autoCorrelate 
 *  Searches each circuit in the database against itself
 *  Outputs a table to read into excel to view the color mapping
 */
void Database::autoCorrelate(){
	//Initialize autocorrelation table
	std::vector<std::vector<double> > acTable;
	acTable.reserve(m_Database.size());	
	for(unsigned int i = 0; i < m_Database.size(); i++){
		std::vector<double> line(m_Database.size(), 0.0);
		acTable.push_back(line);
	}


	for(unsigned int k = 0; k < m_Database.size(); k++) {
		//Get the components of the reference circuit
		std::list<std::string> maxRef, minRef, alphaRef;  //Functional
		m_Database[k]->getMaxSequence(maxRef);
		m_Database[k]->getMinSequence(minRef);
		m_Database[k]->getAlphaSequence(alphaRef);

		std::map<std::string, unsigned> featureRef;       //Structural
		m_Database[k]->getFingerprint(featureRef);

		std::vector<unsigned> constantRef;                //Constant
		m_Database[k]->getBinnedConstants(constantRef);

		std::vector<Score> fs;
		std::vector<Score> ss;
		std::vector<Score> cs;
		fs.reserve(m_Database.size());
		cs.reserve(m_Database.size());
		ss.reserve(m_Database.size());

		double maxf = 0.0;
		double minf = 10000000000.0;
		double maxs = 0.0;
		double mins = 10000000000.0;
		double maxc = 0.0;
		double minc = 10000000000.0;

		for(unsigned int i = 0; i < m_Database.size(); i++) {
			//printf("###########################################################################################################\n");
			if(!m_SuppressOutput)
				printf("[DB] -- Comparing reference to %s\n", m_Database[i]->getName().c_str());
			//printf("###########################################################################################################\n");

			/////////////////////////////////////////////////////////////////////////////
			//   FUNCTIONAL SEQUENCE COMARPISON
			//     Score returned by alignment is all the alignemnt scores among the list
			//     Average to take into account different number os sequences
			//     Final functional score is the sum of all the scores
			/////////////////////////////////////////////////////////////////////////////
			std::list<std::string> maxDB;
			m_Database[i]->getMaxSequence(maxDB);
			int maxScore = SIMILARITY::align(maxRef, maxDB);
			double fScore = (double(maxScore) / ((double)maxRef.size() * (double)maxDB.size())) * 0.75;
			//printf("MAXSCORE: %4d\tAVG: %f\n", maxScore, double(maxScore) / ((double)maxRef.size() * (double)maxDB.size()));;

			std::list<std::string> minDB;
			m_Database[i]->getMinSequence(minDB);
			int minScore = SIMILARITY::align(minRef, minDB);
			fScore += double(minScore) / ((double)minRef.size() * (double)minDB.size()) * 2;
			//printf("MINSCORE: %4d\tAVG: %f\n", minScore, double(minScore) / ((double)minRef.size() * (double)minDB.size()));

			std::list<std::string> alphaDB;
			m_Database[i]->getAlphaSequence(alphaDB);
			int alphaScore = SIMILARITY::align(alphaRef, alphaDB);
			fScore += (double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size())) * 4;
			//printf("ALPHA SCORE: %4d\tAVG: %f\n", alphaScore, double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size()));

			if(fScore > maxf)  maxf = fScore;
			if(fScore < minf)  minf = fScore;
			//printf("  * FSCORE: %f\n", fScore);





			/////////////////////////////////////////////////////////////////////////////
			//   STRUCTURAL SEQUENCE COMARPISON
			//     Score is the total euclidean distance of all the features 
			/////////////////////////////////////////////////////////////////////////////
			//printf(" -- Comparing Structural Components...\n");
			std::map<std::string, unsigned> featureDB;
			m_Database[i]->getFingerprint(featureDB);

			double sScore= 0.0;

				double tsim = SIMILARITY::euclidean(featureRef, featureDB);
				sScore += tsim;
				//printf("  TYPE: %s\t SSCORE: %f\n", type.c_str(), tsim);


			//Note: Don't care are features not accounted for in both since distance is 0
			//printf("  * SSCORE: %f\n", sScore);
			if(sScore> maxs)    maxs = sScore;
			if(sScore< mins)    mins = sScore;





			/////////////////////////////////////////////////////////////////////////////
			//   CONSTANT SEQUENCE COMARPISON
			//     Score is the total euclidean distance of binned constant vector 
			/////////////////////////////////////////////////////////////////////////////
			//printf(" -- Comparing Constant Components....\n");
			std::vector<unsigned> constantDB;
			m_Database[i]->getBinnedConstants(constantDB);
			double cScore = SIMILARITY::euclidean(constantRef, constantDB);

			//printf("  * CSCORE: %f\n", cScore);
			if(cScore > maxc)    maxc = cScore;
			if(cScore < minc)    minc = cScore;


			Score scoref;
			scoref.id = m_Database[i]->getID();
			scoref.name = m_Database[i]->getName();
			scoref.score = fScore;

			Score scores;
			scores.id = m_Database[i]->getID();
			scores.name = m_Database[i]->getName();
			scores.score = sScore;

			Score scorec;
			scorec.id = m_Database[i]->getID();
			scorec.name = m_Database[i]->getName();
			scorec.score = cScore;

			//Need to store for normalization later. Data is in different scales
			fs.push_back(scoref);
			ss.push_back(scores);
			cs.push_back(scorec);
		}
		//Weights
		double fweight = 0.44;
		double sweight = 0.33;
		double cweight = 0.23;

		//Need to normalize data
		for(unsigned int i = 0; i < fs.size(); i++){
			//Normalization of the scores to the range of 0-1
			double newScoref = (double)(fs[i].score - minf) / (double)(maxf-minf);  
			double newScores = (double)(ss[i].score - mins) / (double)(maxs-mins);
			double newScorec = (double)(cs[i].score - minc) / (double)(maxc-minc);

			double newScore = newScoref * fweight * 100.0 + 
				(1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
				(1 - newScorec) * cweight * 100.0;

			acTable[k][i] = newScore;
		}
	}

	if(!m_SuppressOutput){
		printf("###############################################################\n");
		printf("###                    SEARCH COMPLETE                      ###\n");
		printf("###############################################################\n");

		for(unsigned int i = 0; i < acTable.size(); i++){
			for(unsigned int k = 0; k < acTable[i].size(); k++){
				printf("%.2f ", acTable[i][k]);
			}
			printf("\n");
		}

	}
}










/**
 * getBirthmark 
 *  Returns birthmark at the given index
 */
Birthmark* Database::getBirthmark(unsigned index){
	return m_Database[index];
}

/**
 * getSize
 *  Returns the database size 
 */
unsigned Database::getSize(){
	return m_Database.size();
}

/**
 * suppressOutput 
 *  Prevents result output 
 */
void Database::suppressOutput(){
	m_SuppressOutput = !m_SuppressOutput;
}

/**
 * printXML
 *  Prints the XML 
 */
void Database::printXML(){
	std::cout << m_XML << "\n";
}


/**
 * print
 *  Prints the contents of all the birthmarks in the database
 */
void Database::print(){
	for(unsigned int i = 0; i < m_Database.size(); i++) 
		m_Database[i]->print();
}





