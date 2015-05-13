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

	//Get the k value used in the database	
	xml_attribute<>* kAttr = rootNode->first_attribute();
	if(kAttr == NULL) throw cException("(Database::importDatabase:T0) No K Attribute found in database") ;
	std::string kAttrName= kAttr->name();

	if(kAttrName== "K") m_KVal= kAttr->value(); 
	else throw cException("(Database::importDatabase:T0) Unexpected Attribute Tag Found") ;

	//Make sure first node is DATABASE
	std::string rootNodeName = rootNode->name();
	if(rootNodeName != "DATABASE")
		throw cException("(Database::importDatabase:T3) No Database Node found");

	xml_node<>* cktNode= rootNode->first_node();
	//Look through the circuits in the Database
	while (cktNode!= NULL){
		Birthmark* bm = new Birthmark();
		bm->importXML(cktNode);

/*
		bool same = false;
		for(unsigned int i = 0; i < m_Database.size(); i++){
			same = isBirthmarkEqual(bm, m_Database[i]);
			if(same){
				printf("MATCHING BIRTMARK: %s -- %s\n", bm->getName().c_str(), m_Database[i]->getName().c_str());
				bm->print();
				m_Database[i]->print();
				printf("\n\n");
				break;
			}
		}

		if(!same){
			*/
			//Store the fingerprintlist of the circuit 
			m_Database.push_back(bm);
		//}
		
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


	//bm1->print();
	//bm2->print();
}




/**
 * searchDatabase 
 *  Searches the database for a circuit similar to the reference 
 *  Outputs results in ranked order with circuits similar to reference
 */
void Database::searchDatabase(Birthmark* reference, std::string kFlags, bool printall){
	//Get the components of the Reference circuit
	std::list<std::string> maxRef, minRef, alphaRef;  //Functional
	reference->getMaxSequence(maxRef);
	reference->getMinSequence(minRef);
	reference->getAlphaSequence(alphaRef);

	std::map<std::string, unsigned> featureRef;       //Structural
	reference->getFingerprint(featureRef);

	std::vector<unsigned> constantRef;                //Constant
	reference->getBinnedConstants(constantRef);

	std::vector<int> statRef;				          			  //Stat
	reference->getStat(statRef);

	std::map<std::string, int > kgramSetRef;  //KGram
	reference->getKGramSet(kgramSetRef);
	//std::vector<std::map<std::string, int> > kgramMapRef;  //KGram
	//reference->getKGramCounter(kgramMapRef);
	std::map<std::string, int > kgramListRef;  //KGram
	reference->getKGramList(kgramListRef);

	std::vector<Score> fs;
	std::vector<Score> ss;
	std::vector<Score> cs;
	std::vector<Score> ks;
	fs.reserve(m_Database.size());
	cs.reserve(m_Database.size());
	ss.reserve(m_Database.size());
	ks.reserve(m_Database.size());

	double maxf = 0.0;
	double minf = 10000000000.0;
	double maxs = 0.0;
	double mins = 10000000000.0;
	double maxc = 0.0;
	double minc = 10000000000.0;
	double maxst = 0.0;
	double minst = 10000000000.0;

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

		std::vector<int> statDB;						  //Stat
		m_Database[i]->getStat(statDB);
		double stScore = SIMILARITY::euclidean(statDB, statRef);

		//printf("  * CSCORE: %f\n", cScore);
		if(stScore > maxst)    maxst = stScore;
		if(stScore < minst)    minst = stScore;
		
	
	
		/////////////////////////////////////////////////////////////////////////////
		//   KGRAM COMARPISON
		//     Score is the total euclidean distance of binned constant vector 
		/////////////////////////////////////////////////////////////////////////////
		std::map<std::string, int> kgramSetDB;  //KGram
		m_Database[i]->getKGramSet(kgramSetDB);
		std::map<std::string, int> kgramListDB;  //KGram
		m_Database[i]->getKGramList(kgramListDB);
		//std::vector<std::map<std::string, int> > kgramMapDB;  //KGram
		//m_Database[i]->getKGramCounter(kgramMapDB);

		//double kScore = SIMILARITY::resemblance(kgramSetDB, kgramSetRef);
		double kScores = SIMILARITY::containment(kgramSetDB, kgramSetRef);
		double kScoresr = SIMILARITY::resemblance(kgramSetDB, kgramSetRef);
		double kScorel = SIMILARITY::containment(kgramListDB, kgramListRef);
		double kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef);
		//printf("  * KSCORE: %f\n", kScore);

		Score scoref;
		scoref.id = m_Database[i]->getID();
		scoref.name = m_Database[i]->getName();
		scoref.score = fScore;
		scoref.stat = stScore;

		Score scores;
		scores.id = m_Database[i]->getID();
		scores.name = m_Database[i]->getName();
		scores.score = sScore;

		Score scorec;
		scorec.id = m_Database[i]->getID();
		scorec.name = m_Database[i]->getName();
		scorec.score = cScore;
		
		Score scorek;
		scorek.id = m_Database[i]->getID();
		scorek.name = m_Database[i]->getName();
		scorek.ksc= kScores;
		scorek.ksr= kScoresr;
		scorek.klc= kScorel;
		scorek.klr= kScorelr;

		//Need to store for normalization later. Data is in different scales
		fs.push_back(scoref);
		ss.push_back(scores);
		cs.push_back(scorec);
		ks.push_back(scorek);
	}

	if(!m_SuppressOutput){
		printf("###############################################################\n");
		printf("###                    SEARCH COMPLETE                      ###\n");
		printf("###############################################################\n");

		//Weights
		double fweight = 0.40;
		double sweight = 0.28;
		double stweight = 0.19;
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

			double newScorest = (double)(log(fs[i].stat+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  


			//double newScore = newScoref * fweight * 100.0 + 

			//double newScore = ks[i].klr* fweight * 100.0 + 

				double newScore = (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
				(1 - newScorec) * cweight * 100.0 +
				(1 - newScorest) * stweight * 100.0;

			if(kFlags == "klc") newScore += (ks[i].klc * fweight * 100.0);
			else if(kFlags == "klr") newScore += (ks[i].klr * fweight * 100.0);
			else if(kFlags == "ksc") newScore += (ks[i].ksc * fweight * 100.0);
			else if(kFlags == "ksr") newScore += (ks[i].ksr * fweight * 100.0);



			Score sim;
			sim.id = fs[i].id;
			sim.name = fs[i].name;
			//sim.score = newScore;
			sim.score = newScore;
			sim.f = fs[i].score;
			sim.c = cs[i].score;
			sim.s = ss[i].score;
			sim.ksr = ks[i].ksr;
			sim.ksc = ks[i].ksc;
			sim.klr = ks[i].klr;
			sim.klc = ks[i].klc;
			sim.nf = newScoref;
			sim.nc = newScorec;
			sim.ns = newScores;
			sim.stat = newScorest;
			normalizedFinalScore.insert(sim);
		}


		int count = 1;
		std::set<Score, setCompare>::iterator iSet;
		for(iSet = normalizedFinalScore.begin(); iSet != normalizedFinalScore.end(); iSet++){
			printf("R: %2d ", count);
			printf("SC:%6.2f  ", iSet->score);
			//printf("F:%7.2f  ", iSet->f);
			//printf("S:%7.2f  ", iSet->s);
			//printf("C:%7.2f  ", iSet->c);
			printf("NF:%5.2f  ", iSet->nf);
			printf("NS:%5.2f  ", 1.0-iSet->ns);
			printf("NC:%5.2f  ", 1.0-iSet->nc);
			printf("ST:%6.2f  ", 1.0-iSet->stat);
			printf("KSC: %5.2f  ", iSet->ksc);
			printf("KLC: %5.2f  ", iSet->klc);
			printf("KSR: %7.4f  ", iSet->ksr);
			printf("KLR: %7.4f  ", iSet->klr);
			printf("\t\tCKT:%s\n", iSet->name.c_str());

			//printf(" %2d & %6.2f & %s\n", count, iSet->score, iSet->name.c_str()); //latex table
			if(!printall && count == 20)
				break;
			count++;
		}
		printf("Database Size: %d\n", (int)m_Database.size());


		printf("MAXF: %f\n", maxf);
		printf("MINF: %f\n", minf);
		printf("MAXS: %f\n", maxs);
		printf("MINS: %f\n", mins);
		printf("MAXC: %f\n", maxc);
		printf("MINC: %f\n", minc);
		printf("KVAL: %s\n", m_KVal.c_str());
		printf("KFLG: %s\n", kFlags.c_str());
	}
}



/**
 * processKGramDatabase 
 *  Processes all the kgrams in the database
 *  Tries to set to predict the next possible node/line
void Database::processKGramDatabase(){
	for(unsigned int k = 0; k < m_Database.size(); k++) {
		printf("[DB] -- Comparing %s to database\n", m_Database[k]->getName().c_str());
		std::map<std::string,int> kgramlist;
		std::map<std::string,int>:iterator iMap;
		m_Database[k]->getKGramList(kgramlist);

		for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
			std::string kgramstring = iMap->first;
			std::string km1 = kgramstring.substr(0, kgramstring.length()-1)
			std::string kmlast = kgramstring[kgramstring.length()-1];

			std::map<std::string, sGram>::iterator iGram;
			iGram = m_KGramList.find(km1);
			if(iGram  == m_KGramList.end()){
				sGram sgram;
				sgram.next_letter.push_back(kmlast);

			}
			else{
				iGram->second.next_letter.push_back(kmlast);
				iGram->second.next_letter.push_back(kmlast);

			}

			
		}

	}
	
}
 */


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
		printf("[DB] -- Comparing %s to database\n", m_Database[k]->getName().c_str());
		//Get the components of the reference circuit
		std::list<std::string> maxRef, minRef, alphaRef;  //Functional
		m_Database[k]->getMaxSequence(maxRef);
		m_Database[k]->getMinSequence(minRef);
		m_Database[k]->getAlphaSequence(alphaRef);

		std::map<std::string, unsigned> featureRef;       //Structural
		m_Database[k]->getFingerprint(featureRef);

		std::vector<unsigned> constantRef;                //Constant
		m_Database[k]->getBinnedConstants(constantRef);

		std::vector<int> statRef;						  //Stat
		m_Database[k]->getStat(statRef);

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
		double maxst = 0.0;
		double minst = 10000000000.0;

		for(unsigned int i = 0; i < m_Database.size(); i++) {
			//printf("###########################################################################################################\n");
			//if(!m_SuppressOutput)
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
			//printf("MAXREF: %d  MAXDB: %d\n", (int)maxRef.size(), (int)maxDB.size());
			//printf("MAXSCORE: %4d\tAVG: %f\n", maxScore, double(maxScore) / ((double)maxRef.size() * (double)maxDB.size()));;

			std::list<std::string> minDB;
			m_Database[i]->getMinSequence(minDB);
			int minScore = SIMILARITY::align(minRef, minDB);
			fScore += double(minScore) / ((double)minRef.size() * (double)minDB.size()) * 2;
			//printf("MINREF: %d  MINDB: %d\n", (int)minRef.size(), (int)minDB.size());
			//printf("MINSCORE: %4d\tAVG: %f\n", minScore, double(minScore) / ((double)minRef.size() * (double)minDB.size()));

			std::list<std::string> alphaDB;
			m_Database[i]->getAlphaSequence(alphaDB);
			int alphaScore = SIMILARITY::align(alphaRef, alphaDB);
			fScore += (double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size())) * 3;
			//printf("ALPHAREF: %d  ALPHADB: %d\n\n", (int)alphaRef.size(), (int)alphaDB.size());
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


			std::vector<int> statDB;						  //Stat
			m_Database[i]->getStat(statDB);
			double stScore = SIMILARITY::euclidean(statDB, statRef);
			if(stScore > maxst)    maxst = stScore;
			if(stScore < minst)    minst = stScore;

			Score scoref;
			scoref.id = m_Database[i]->getID();
			scoref.name = m_Database[i]->getName();
			scoref.score = fScore;
			scoref.stat = stScore;

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
		double fweight = 0.40;
		double sweight = 0.28;
		double stweight = 0.19;
		double cweight = 0.13;

		//Need to normalize data
		for(unsigned int i = 0; i < fs.size(); i++){
			//printf("MAXS: %f MINS: %f\n", maxs, mins);
			//printf("MAXC: %f MINC: %f\n", maxc, minc);
			//printf("MAXST: %f MINST: %f\n", maxst, minst);

			//Normalization of the scores to the range of 0-1
			double newScoref = (double)(fs[i].score - minf) / (double)(maxf-minf);  
			//double newScores = (double)(ss[i].score - mins) / (double)(maxs-mins);
			//double newScorec = (double)(cs[i].score - minc) / (double)(maxc-minc);
			double newScores = (double)(log(ss[i].score+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
			double newScorec = (double)(log(cs[i].score+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

			double newScorest = (double)(log(fs[i].stat+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  

			double newScore = newScoref * fweight * 100.0 + 
				(1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
				(1 - newScorec) * cweight * 100.0 +
				(1 - newScorest) * stweight * 100.0;


			acTable[k][i] = newScore;
		}
	}

	std::ofstream ofs; 
	ofs.open("data/heatmap.csv");
	if(!m_SuppressOutput){
		printf("###############################################################\n");
		printf("###                    SEARCH COMPLETE                      ###\n");
		printf("###############################################################\n");

		for(unsigned int i = 0; i < acTable.size(); i++){
			ofs<<acTable[i][0];
			for(unsigned int k = 1; k < acTable[i].size(); k++)
				ofs<<","<<acTable[i][k];
			ofs<<"\n";
		}

	}
}



bool Database::isBirthmarkEqual(Birthmark* bm1, Birthmark* bm2){
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
	
	std::vector<int> stat1, stat2;						  //Stat
	bm1->getStat(stat1);
	bm2->getStat(stat2);




	double sScore = SIMILARITY::euclidean(feature1, feature2);
	double cScore = SIMILARITY::euclidean(constant1, constant2);
	double stScore = SIMILARITY::euclidean(stat1, stat2);

	if(sScore == 0 && cScore == 0 && stScore == 0){
		//MAX
		std::list<std::string>::iterator it1, it2;
		for(it1 = max1.begin(); it1 != max2.begin(); it1++){
			bool found = false;
			for(it2 = max2.begin(); it2 != max2.begin(); it2++)
				if(*it1 != *it2) found = true; break;
			if(!found) return false;
		}

		//MIN
		for(it1 = min1.begin(); it1 != min2.begin(); it1++){
			bool found = false;
			for(it2 = min2.begin(); it2 != min2.begin(); it2++)
				if(*it1 == *it2) found = true; break;

			if(!found) return false;
		}

		//ALPHA
		for(it1 = alpha1.begin(); it1 != alpha2.begin(); it1++){
			bool found = false;
			for(it2 = alpha2.begin(); it2 != alpha2.begin(); it2++)
				if(*it1 == *it2) found = true; break;

			if(!found) return false;
		}

		return true;
	}

	return false;

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
 * getKVal
 *  Returns the k value of the kgrams used in the database
 */
std::string Database::getKVal(){
	return m_KVal;
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





