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
Database::Database(SearchType st){	
  SIMILARITY::initAlignment();
  t_CurLine = -1;

  m_Settings = new s_db_setting;
  m_Settings->searchType = st;
  m_Settings->suppressOutput = false;
  m_Settings->allsim = false;
  m_Settings->kgramSimilarity = st;
  m_Settings->show_all_result = false;
  m_Settings->partialMatch= false;
  m_Settings->countMatch= false;
  m_Settings->backEndProductivity= false;
}

/**
 * Constructor
 *  Imports an existing database XML file
 *  Initializes alignment function for pairwise alignment
 */
Database::Database(std::string file, SearchType st){	
  SIMILARITY::initAlignment();
  importDatabase(file);
  t_CurLine = -1;

  m_Settings = new s_db_setting;
  m_Settings->searchType = st;
  m_Settings->suppressOutput = false;
  m_Settings->allsim = false;
  m_Settings->kgramSimilarity = "KLR";
  m_Settings->show_all_result = false;
  m_Settings->partialMatch= false;
  m_Settings->countMatch= false;
  m_Settings->backEndProductivity= false;
}

/**
 * Constructor
 *  Initializes alignment function for pairwise alignment
 */
Database::Database(){	
  SIMILARITY::initAlignment();
  t_CurLine = -1;

  m_Settings = new s_db_setting;
  m_Settings->searchType = eSimilarity;
  m_Settings->suppressOutput = false;
  m_Settings->allsim = false;
  m_Settings->kgramSimilarity = "KLR";
  m_Settings->show_all_result = false;
  m_Settings->partialMatch= false;
  m_Settings->countMatch= false;
  m_Settings->backEndProductivity= false;
}

/**
 * Constructor
 *  Imports an existing database XML file
 *  Initializes alignment function for pairwise alignment
 */
Database::Database(std::string file){	
  SIMILARITY::initAlignment();
  importDatabase(file);
  t_CurLine = -1;

  m_Settings = new s_db_setting;
  m_Settings->searchType = eSimilarity;
  m_Settings->suppressOutput = false;
  m_Settings->allsim = false;
  m_Settings->kgramSimilarity = "KLR";
  m_Settings->show_all_result = false;
  m_Settings->partialMatch= false;
  m_Settings->countMatch= false;
  m_Settings->backEndProductivity= false;
}

/**
 * Destructor 
 */
Database::~Database(){
  delete m_Settings;
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
  printf("[DATABASE] -- XML File imported. Parsing...\n");


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


  m_KInt = s2i::string2int(m_KVal.c_str());

  printf("COMPLETE!\n\n");
  return true;
}




bool Database::invertDatabase(){
  std::string operation = m_Settings->kgramSimilarity;
  if(operation != "FUNC"){
    printf("[DB] -- Creating Inverted Index...");

    for(unsigned int i = 0; i < m_Database.size(); i++) {
      std::map<std::string, int > kgram;  //KGram
      std::map<std::string, int >::iterator iMap;  //KGram
      if(operation == "KFC" || operation == "KFR")
        m_Database[i]->getKGramFreq(kgram);
      else if(operation == "KLC" || operation == "KLR")
        m_Database[i]->getKGramList(kgram);

      for(iMap = kgram.begin(); iMap != kgram.end(); iMap++) 
        m_IDatabase[iMap->first].push_back(i);
    }
  }
  return true;

}





void Database::compareBirthmark(Birthmark* bm1, Birthmark* bm2){
  printf("Comparing birthmarks\n\n");

  //Get the components of the Reference circuit
  std::list<std::string> max1, min1, alpha1;  //Functional
  std::list<std::string> max2, min2, alpha2;  //Functional
  bm1->getMaxSequence(max1);
  bm1->getMinSequence(min1);
  bm1->getAlphaSequence(alpha1);
  bm2->getMaxSequence(max2);
  bm2->getMinSequence(min2);
  bm2->getAlphaSequence(alpha2);

  std::map<std::string, unsigned> feature1;       //Structural
  std::map<std::string, unsigned> feature2;       //Structural
  bm1->getFingerprint(feature1);
  bm2->getFingerprint(feature2);

  std::vector<unsigned> constant1;                //Constant
  std::vector<unsigned> constant2;                //Constant
  bm1->getBinnedConstants(constant1);
  bm2->getBinnedConstants(constant2);

  std::vector<int> stat1;				          			  //Stat
  std::vector<int> stat2;				          			  //Stat
  bm1->getStat(stat1);
  bm2->getStat(stat2);

  std::map<std::string, int > kgramSet1, kgramList1;  //KGram
  std::map<std::string, int > kgramFreq1;  //KGram
  std::map<std::string, int > kgramSet2, kgramList2;  //KGram
  std::map<std::string, int > kgramFreq2;  //KGram
  bm1->getKGramSet(kgramSet1);
  bm1->getKGramList(kgramList1);
  bm1->getKGramFreq(kgramFreq1);
  bm1->print();
  bm2->getKGramSet(kgramSet2);
  bm2->getKGramList(kgramList2);
  bm2->getKGramFreq(kgramFreq2);
  bm2->print();


  /////////////////////////////////////////////////////////////////////////////
  //   FUNCTIONAL SEQUENCE COMARPISON
  //     Score returned by alignment is all the alignemnt scores among the list
  //     Average to take into account different number os sequences
  //     Final functional score is the sum of all the scores
  /////////////////////////////////////////////////////////////////////////////
  double fScore = 0.0;
     int maxScore = SIMILARITY::alignList(max1, max2);
     fScore += (double(maxScore) / ((double)max1.size() * (double)max2.size()));

     int minScore = SIMILARITY::alignList(min1, min2);
     fScore += double(minScore) / ((double)min1.size() * (double)min2.size()) ;

     int alphaScore = SIMILARITY::alignList(alpha1, alpha2);
     fScore += (double(alphaScore) / ((double)alpha1.size() * (double)alpha2.size()));




  /////////////////////////////////////////////////////////////////////////////
  //   STRUCTURAL SEQUENCE COMARPISON
  //     Score is the total euclidean distance of all the features 
  /////////////////////////////////////////////////////////////////////////////
  double sScore= SIMILARITY::euclidean(feature1, feature2);




  /////////////////////////////////////////////////////////////////////////////
  //   CONSTANT SEQUENCE COMARPISON
  //     Score is the total euclidean distance of binned constant vector 
  /////////////////////////////////////////////////////////////////////////////
  //printf(" -- Comparing Constant Components....\n");
  double cScore = SIMILARITY::euclidean(constant1, constant2);
  double stScore = SIMILARITY::euclidean(stat1, stat2);



  /////////////////////////////////////////////////////////////////////////////
  //   KGRAM COMARPISON
  //     Score is the total euclidean distance of binned constant vector 
  /////////////////////////////////////////////////////////////////////////////
  //double kScores = SIMILARITY::containment(kgramSet1, kgramSet2);
  //double kScoresr = SIMILARITY::resemblance(kgramSet1, kgramSet2);

  double kScorel = SIMILARITY::containment(kgramList1, kgramList2, m_Settings->countMatch);
  double kScoref = SIMILARITY::containment(kgramFreq1, kgramFreq2, m_Settings->countMatch);
  double kScorefr = SIMILARITY::resemblance(kgramFreq1, kgramFreq2, m_Settings->partialMatch, m_Settings->countMatch);

  double kScorelr;
  bool isRefSmaller = true; 
  if(kgramList1.size() > kgramList2.size())
    isRefSmaller = false;
  else if(kgramList1.size() == kgramList2.size()){
    for(unsigned int i = 0; i < stat1.size(); i++){
      if(stat1[i] ==  stat2[i])	continue;
      if(stat1[i] <  stat2[i]) isRefSmaller = true; 
      else isRefSmaller = false;
    }
  }

  if(isRefSmaller)
    kScorelr = SIMILARITY::resemblance(kgramList1, kgramList2, m_Settings->partialMatch, m_Settings->countMatch);
  else
    kScorelr = SIMILARITY::resemblance(kgramList2, kgramList1, m_Settings->partialMatch, m_Settings->countMatch);

  printf("###############################################################\n");
  printf("###                    SEARCH COMPLETE                      ###\n");
  printf("###############################################################\n");


  printf("NF:%5.2f  ", fScore);
  printf("NS:%5.2f  ", sScore);
  printf("NC:%5.2f  ", cScore);
  printf("ST:%5.2f  ", stScore);
  //printf("SC:%5.2f  ", kScores);
  //printf("SR:%5.2f  ", kScoresr);
  printf("LC:%5.2f  ", kScorel);
  printf("LR:%5.2f  ", kScorelr);
  printf("FC:%5.2f  ", kScoref);
  printf("FR:%5.2f\n", kScorefr);

  printf("==============================================================\n");
  printSettings();
}









/**
 * searchDatabase 
 *  Searches the database for a circuit similar to the reference 
 *  Outputs results in ranked order with circuits similar to reference
 */
sResult* Database::searchDatabase(Birthmark* reference){
  std::string operation = m_Settings->kgramSimilarity;

  //Get the components of the Reference circuit
  std::list<std::string> maxRef, minRef, alphaRef;  //Functional
  std::list<std::string> maxDB, minDB, alphaDB;
  reference->getMaxSequence(maxRef);
  reference->getMinSequence(minRef);
  reference->getAlphaSequence(alphaRef);

  std::map<std::string, unsigned> featureRef;       //Structural
  std::map<std::string, unsigned> featureDB;
  reference->getFingerprint(featureRef);

  std::vector<unsigned> constantRef;                //Constant
  std::vector<unsigned> constantDB;
  reference->getBinnedConstants(constantRef);

  std::vector<int> statRef;				          			  //Stat
  std::vector<int> statDB;						  //Stat
  reference->getStat(statRef);

  std::map<std::string, int > kgramSetRef, kgramListRef;  //KGram
  std::map<std::string, int> kgramSetDB, kgramListDB;  //KGram
  reference->getKGramSet(kgramSetRef);
  reference->getKGramList(kgramListRef);

  std::map<std::string, int > kgramFreqRef;  //KGram
  std::map<std::string, int > kgramFreqDB;  //KGram
  reference->getKGramFreq(kgramFreqRef);

  std::vector<Score> scoreList;
  scoreList.reserve(m_Database.size());

  double maxf = 0.0;
  double minf = 1000000.0;
  double maxs = 0.0;
  double mins = 1000000.0;
  double maxc = 0.0;
  double minc = 1000000.0;
  double maxst = 0.0;
  double minst = 1000000.0;

  for(unsigned int i = 0; i < m_Database.size(); i++) {
    //printf("###################################################################################################\n");
    //if(!m_SuppressOutput)
    //printf("[DB] -- Comparing reference to %30s : KGRAMS: %d\n", m_Database[i]->getName().c_str(), m_Database[i]->getKGramListSize());
    //printf("##################################################################################################\n");
    //If it's the same circuit, skip
    if(m_Database[i]->getFileName() == reference->getFileName())
      continue;

    /////////////////////////////////////////////////////////////////////////////
    //   FUNCTIONAL SEQUENCE COMARPISON
    //     Score returned by alignment is all the alignemnt scores among the list
    //     Average to take into account different number os sequences
    //     Final functional score is the sum of all the scores
    /////////////////////////////////////////////////////////////////////////////
    double fScore = 0.0;

    if(operation == "FUNC"){
      m_Database[i]->getMaxSequence(maxDB);
      if(maxRef.size() > 0 && maxDB.size() > 0){
        int maxScore = SIMILARITY::alignList(maxRef, maxDB);
        fScore = (double(maxScore) / ((double)maxRef.size() * (double)maxDB.size()));
      }

      m_Database[i]->getMinSequence(minDB);
      if(minRef.size() > 0 && minDB.size() > 0){
        int minScore = SIMILARITY::alignList(minRef, minDB);
        fScore += double(minScore) / ((double)minRef.size() * (double)minDB.size()) ;
      }

      m_Database[i]->getAlphaSequence(alphaDB);
      if(alphaRef.size() > 0 && alphaDB.size() > 0){
        int alphaScore = SIMILARITY::alignList(alphaRef, alphaDB);
        fScore += (double(alphaScore) / ((double)alphaRef.size() * (double)alphaDB.size()));
      }

    }

    if(fScore > maxf)  maxf = fScore;
    if(fScore < minf)  minf = fScore;

    //printf("  * FSCORE: %f\n", fScore);





    /////////////////////////////////////////////////////////////////////////////
    //   STRUCTURAL SEQUENCE COMARPISON
    //     Score is the total euclidean distance of all the features 
    /////////////////////////////////////////////////////////////////////////////
    m_Database[i]->getFingerprint(featureDB);

    double sScore= SIMILARITY::euclidean(featureRef, featureDB);

    //Note: Don't care are features not accounted for in both since distance is 0
    //printf("  * SSCORE: %f\n", sScore);
    if(sScore> maxs)    maxs = sScore;
    if(sScore< mins)    mins = sScore;





    /////////////////////////////////////////////////////////////////////////////
    //   CONSTANT SEQUENCE COMARPISON
    //     Score is the total euclidean distance of binned constant vector 
    /////////////////////////////////////////////////////////////////////////////
    //printf(" -- Comparing Constant Components....\n");
    m_Database[i]->getBinnedConstants(constantDB);
    double cScore = SIMILARITY::euclidean(constantRef, constantDB);
    //printf("  * CSCORE: %f\n", cScore);
    if(cScore > maxc)    maxc = cScore;
    if(cScore < minc)    minc = cScore;

    m_Database[i]->getStat(statDB);
    double stScore = SIMILARITY::euclidean(statDB, statRef);

    //printf("  * stCORE: %f\n", stScore);
    if(stScore > maxst)    maxst = stScore;
    if(stScore < minst)    minst = stScore;



    /////////////////////////////////////////////////////////////////////////////
    //   KGRAM COMARPISON
    //     Score is the total euclidean distance of binned constant vector 
    /////////////////////////////////////////////////////////////////////////////
    m_Database[i]->getKGramSet(kgramSetDB);
    m_Database[i]->getKGramList(kgramListDB);
    m_Database[i]->getKGramFreq(kgramFreqDB);
    //std::vector<std::map<std::string, int> > kgramMapDB;  //KGram
    //m_Database[i]->getKGramCounter(kgramMapDB);

    //double kScore = SIMILARITY::resemblance(kgramSetDB, kgramSetRef);
    //double kScores = SIMILARITY::containment(kgramSetDB, kgramSetRef);
    //double kScoresr = SIMILARITY::resemblance(kgramSetDB, kgramSetRef);
    double kScorel = 0.0;
    double kScorell = 0.0;
    double kScoref = 0.0;
    double kScorelr = 0.0;
    double kScorefr = 0.0;
    bool isRefSmaller = true; 

    if(operation != "FUNC"){
      if(kgramListRef.size() > kgramListDB.size())
        isRefSmaller = false;
      else if(kgramListRef.size() == kgramListDB.size()){
        for(unsigned int i = 0; i < statRef.size(); i++){
          if(statRef[i] ==  statDB[i])	continue;
          if(statRef[i] <  statDB[i]) isRefSmaller = true; 
          else isRefSmaller = false;
        }
      }

      if (m_Settings->allsim){
        kScoref = SIMILARITY::containment(kgramFreqRef, kgramFreqDB, m_Settings->countMatch);
        kScorefr= SIMILARITY::resemblance(kgramFreqRef, kgramFreqDB, m_Settings->partialMatch, m_Settings->countMatch);

        kScorel = SIMILARITY::containment(kgramListRef, kgramListDB, m_Settings->countMatch);
        kScorell = SIMILARITY::containment(kgramListDB, kgramListRef, m_Settings->countMatch);

        if(isRefSmaller){
          kScorelr = SIMILARITY::resemblance(kgramListRef, kgramListDB, m_Settings->partialMatch, m_Settings->countMatch);
        }
        else{
          kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef, m_Settings->partialMatch, m_Settings->countMatch);
        }

      }
      else if(m_Settings->searchType == ePredict){
        if(operation[1] == 'L'){
          kScorel = SIMILARITY::containment(kgramListRef, kgramListDB, m_Settings->countMatch);

          if(isRefSmaller)
            kScorelr = SIMILARITY::resemblance(kgramListRef, kgramListDB, m_Settings->partialMatch, m_Settings->countMatch);
          else
            kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef, m_Settings->partialMatch, m_Settings->countMatch);

        }
        if(operation[1] == 'F'){
          kScoref = SIMILARITY::containment(kgramFreqRef, kgramFreqDB, m_Settings->countMatch);

          if(isRefSmaller)
            kScorefr = SIMILARITY::resemblance(kgramFreqRef, kgramFreqDB, m_Settings->partialMatch, m_Settings->countMatch );
          else
            kScorefr = SIMILARITY::resemblance(kgramFreqDB, kgramFreqRef, m_Settings->partialMatch, m_Settings->countMatch);

        }
      }
      else if(operation == "KLC"){
        kScorel = SIMILARITY::containment(kgramListRef, kgramListDB, m_Settings->countMatch);
        kScorell = SIMILARITY::containment(kgramListDB, kgramListRef, m_Settings->countMatch);

      }
      else if(operation == "KFC")
        kScoref = SIMILARITY::containment(kgramFreqRef, kgramFreqDB, m_Settings->countMatch);
      else if(operation == "KLR"){
        if(isRefSmaller)
          kScorelr = SIMILARITY::resemblance(kgramListRef, kgramListDB, m_Settings->partialMatch, m_Settings->countMatch);
        else
          kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef, m_Settings->partialMatch, m_Settings->countMatch);
      }
      else if(operation == "KFR")
        kScorefr= SIMILARITY::resemblance(kgramFreqRef, kgramFreqDB, m_Settings->partialMatch, m_Settings->countMatch);
      else 
        throw cException("Operation not supported for searchType: TRUST: " + operation);
    }


    /*
    //For trust applications, make sure containment goes both ways and get the highest
    if(m_SearchType == eTrust){
    double kScores2 = SIMILARITY::containment(kgramSetRef, kgramSetDB);
    double kScorel2 = SIMILARITY::containment(kgramListRef, kgramListDB);
    double kScoref2 = SIMILARITY::containment(kgramFreqRef, kgramFreqDB);
    if(kScores2 > kScores) kScores = kScores2;
    if(kScorel2 > kScorel) kScorel = kScorel2;
    if(kScoref2 > kScoref) kScoref = kScoref2;

    }
     */

    //Store the score results for this circuit
    Score score;
    score.id = m_Database[i]->getID();
    score.name = m_Database[i]->getFileName();
    score.fScore= fScore;
    score.tScore= stScore;
    score.sScore= sScore;
    score.cScore= cScore;
    //score.ksc= kScores;
    //score.ksr= kScoresr;
    score.klc= kScorel;
    score.klc2= kScorell;
    score.klr= kScorelr;
    score.kfc= kScoref;
    score.kfr= kScorefr;

    score.bm = m_Database[i];
    if(isRefSmaller)
      score.direction = ">";
    else
      score.direction = "<";

    //Need to store for normalization later. Data is in different scales
    scoreList.push_back(score);
  }

  if(!m_Settings->suppressOutput){
    printf("###############################################################\n");
    printf("###                    SEARCH COMPLETE                      ###\n");
    printf("###############################################################\n");
  }

  //Weights
  /*
     weights for date paper
   */

  /*
     86.8852
     double fweight = 0.90;  //If datapath birthmark, subtract .1
     double sweight = 0.05;
     double tweight = 0.00;
     double cweight = 0.05;
   */

  //Need to normalize data
  std::set<Score, setCompare> normalizedFinalScore_r; //ordered based on resemblance
  std::set<Score, setCompare> normalizedFinalScore_c; //ordered based on containment

  //Combine and sort the scores in ranking order
  for(unsigned int i = 0; i < scoreList.size(); i++){
    //Normalization of the scores to the range of 0-1
    //double newScoref = (double)(scoreList[i].fScore- minf) / (double)(maxf-minf);  

    double newScore = 0.0;
    double fweight = 1.0; 
    double sweight = 0.0;
    double tweight = 0.0;
    double cweight = 0.0;
    double newScoreC = 0.0;
    double newScoreR = 0.0;

    if(m_Settings->searchType== eSimilarity){
      double newScores = (double)(log(scoreList[i].sScore+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
      double newScoret = (double)(log(scoreList[i].tScore+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  
      double newScorec = (double)(log(scoreList[i].cScore+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

      if(operation == "FUNC"){
        double newScoref = (double)(log(scoreList[i].fScore+1) - log(minf+1)) / (double)(log(maxf+1)-log(minf+1));
        //printf("SCORE: %f\n " , newScoref);
        newScore += (newScoref * fweight * 100.0);
      }
      else if(operation == "KLC") newScore += (scoreList[i].klc * fweight * 100.0);
      else if(operation == "KLR") newScore += (scoreList[i].klr * fweight * 100.0);
      else if(operation == "KFC") newScore += (scoreList[i].kfc * fweight * 100.0);
      else if(operation == "KFR") newScore += (scoreList[i].kfr * fweight * 100.0);
      else
        throw cException("Operation not supported for searchType: SIM: " + operation);

      newScore += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
      newScoreC = newScore;
      newScoreR = newScore;
    }

    else if (m_Settings->searchType== eTrust){
      if(operation == "KFR")
        newScore += (scoreList[i].kfr * 100.0);
      else if(operation == "KLR")
        newScore += (scoreList[i].klr * 100.0);
      else if(operation == "KLC")
        newScore += (scoreList[i].klc * 100.0);
      else
        throw cException("Operation not supported for searchType: TRUST: " + operation);
      newScoreC = newScore;
      newScoreR = newScore;
    }

    else if(m_Settings->searchType == ePredict){
      double newScores = (double)(log(scoreList[i].sScore+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
      double newScoret = (double)(log(scoreList[i].tScore+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  
      double newScorec = (double)(log(scoreList[i].cScore+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

      if(operation == "FUNC"){
        double newScoref = (double)(log(scoreList[i].fScore+1) - log(minf+1)) / (double)(log(maxf+1)-log(minf+1));

        newScoref = (newScoref * fweight);

        newScoreC =  newScoref* fweight * 100.0;
        newScoreR =  newScoref* fweight * 100.0;
        printf("FSCORE: %8.4f  SCORE: %8.4f FINAL: %8.4f " , scoreList[i].fScore, newScoref, newScoreC);
      }
      else if(operation[1] == 'F'){
        newScoreC = (scoreList[i].kfc * fweight * 100.0);
        newScoreR = (scoreList[i].kfr * fweight * 100.0);
      }
      else if(operation[1] == 'L'){
        newScoreC = (scoreList[i].klc * fweight * 100.0);
        newScoreR = (scoreList[i].klr * fweight * 100.0);
      }
      else
        throw cException("Operation not supported for searchType: PREDICT: " + operation);



      newScoreC += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
      newScoreR += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
        //printf("NEW: %8.4f \n" , newScoreC);
    }
    else{
      throw cException("Unknown Search Type");
    }

    Score simc;
    simc.id = scoreList[i].id;
    simc.name = scoreList[i].name;
    simc.score = newScoreC;
    simc.fScore = scoreList[i].fScore;
    simc.klr = scoreList[i].klr;
    simc.klc = scoreList[i].klc;
    simc.klc2 = scoreList[i].klc2;
    simc.kfc = scoreList[i].kfc;
    simc.kfr = scoreList[i].kfr;
    simc.bm = scoreList[i].bm;
    normalizedFinalScore_c.insert(simc);

    Score simr;
    simr.id = scoreList[i].id;
    simr.name = scoreList[i].name;
    simr.score = newScoreR;
    simr.fScore = scoreList[i].fScore;
    simr.klr = scoreList[i].klr;
    simr.klc = scoreList[i].klc;
    simr.klc2 = scoreList[i].klc2;
    simr.kfc = scoreList[i].kfc;
    simr.kfr = scoreList[i].kfr;
    simr.bm = scoreList[i].bm;
    normalizedFinalScore_r.insert(simr);

  }


  // Print the scores
  int count = 1;
  std::set<Score, setCompare>::iterator iSet;
  std::string resultStr_c = ""; 
  std::string resultStr_r = ""; 
  sResult* result = NULL;
    if(result == NULL)
      result = new sResult;

    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      char buffer[100];
      sprintf(buffer, "R: %2d ", count);
      resultStr_r += buffer;
      sprintf(buffer, "SC:%7.4f  ", iSet->score);
      resultStr_r += buffer;
      sprintf(buffer, "F :%7.4f  ", iSet->fScore);
      resultStr_r += buffer;
      sprintf(buffer, "LC:%5.2f  ", iSet->klc);
      resultStr_r += buffer;
      sprintf(buffer, "LC2:%5.2f  ", iSet->klc2);
      resultStr_r += buffer;
      sprintf(buffer, "LR:%5.2f  ", iSet->klr);
      resultStr_r += buffer;
      sprintf(buffer, "FC:%5.2f  ", iSet->kfc);
      resultStr_r += buffer;
      sprintf(buffer, "FR:%5.2f  \t", iSet->kfr);
      resultStr_r += buffer;
      sprintf(buffer, "%s", iSet->name.c_str());
      resultStr_r += buffer;
      resultStr_r += "\n";

      result->topMatch.push_back(buffer);

      if(!m_Settings->show_all_result && count == 10)
        break;
      count++;
    }

    count = 1;
    for(iSet = normalizedFinalScore_c.begin(); iSet != normalizedFinalScore_c.end(); iSet++){
      /*
         printf("R: %2d ", count);
         printf("SC:%7.4f  ", iSet->score);
      //printf("NF:%5.2f  ", iSet->nf);
      printf("NS:%5.4f  ", 1.0-iSet->ns);
      printf("NC:%5.4f  ", 1.0-iSet->nc);
      printf("ST:%5.2f  ", 1.0-iSet->stat);
      //printf("SC:%5.2f  ", iSet->ksc);
      //printf("SR:%5.2f  ", iSet->ksr);
      printf("LC:%5.2f  ", iSet->klc);
      printf("LC2:%5.2f  ", iSet->klc2);
      printf("LR:%5.2f  ", iSet->klr);
      printf("FC:%5.2f  ", iSet->kfc);
      printf("FR:%5.2f  ", iSet->kfr);
      printf("\tC:%s\n", iSet->name.c_str());
       */

      char buffer[100];
      sprintf(buffer, "R: %2d ", count);
      resultStr_c += buffer;

      sprintf(buffer, "SC:%7.4f  ", iSet->score);
      resultStr_c += buffer;
      sprintf(buffer, "LC:%5.2f  ", iSet->klc);
      resultStr_c += buffer;
      sprintf(buffer, "LC2:%5.2f  ", iSet->klc2);
      resultStr_c += buffer;
      sprintf(buffer, "LR:%5.2f  ", iSet->klr);
      resultStr_c += buffer;
      sprintf(buffer, "FC:%5.2f  ", iSet->kfc);
      resultStr_c += buffer;
      sprintf(buffer, "FR:%5.2f  \t", iSet->kfr);
      resultStr_c += buffer;
      sprintf(buffer, "%s", iSet->name.c_str());
      resultStr_c += buffer;
      resultStr_c += "\n";
      result->topContain.push_back(buffer);

      //printf(" %2d & %6.2f & %s\n", count, iSet->score, iSet->name.c_str()); //latex table
      if(!m_Settings->show_all_result && count == 10)
        break;
      count++;
    }


    result->ranked_result_c = resultStr_c;
    result->ranked_result_r = resultStr_r;
    //if(m_Settings->backEndProductivity == false){

    if(!m_Settings->suppressOutput){
      printf("Resemblance:\n%s\n\nContainment:\n%s\n", resultStr_r.c_str(), resultStr_c.c_str());
      //}
    }






  count = 1;
  std::list<std::string> endgrams;
  std::list<std::string>::iterator iList;
  std::string currentEndGram = "";

  if(t_CurLine == -1){
    if(!m_Settings->suppressOutput){
      reference->getEndGrams(endgrams);
      printf("Number of n-grams in reference circuit: %d\n", (int)endgrams.size());
      printf("No line number of current design given...skipping code prediction...\n");
    }
  }
  else{
    printf("Predicting future code based on existing hardware database...\n");
    //Get the endgrams with the current line as an end node
    reference->getEndGrams(endgrams, t_CurLine);
    printf("ENDGRAM: ");
    for(iList = endgrams.begin(); iList != endgrams.end(); iList++)
      printf(" %s, ", iList->c_str());
    printf("\n");

    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      printf("----------------------------------------------------------------\n");
      printf("CKT: %s count: %d\n", iSet->name.c_str(), count);

      std::set<int> lines;
      for(iList = endgrams.begin(); iList != endgrams.end(); iList++){
        std::string nextOp = iSet->bm->getFuture(*iList, lines);
        if(nextOp == "NONE") continue;
        printf("\tENDGRAM: %s  ", iList->c_str());
        printf("NEXT: %s\n", nextOp.c_str());
      }

      std::set<int>::iterator iSet2;
      if(lines.size() != 0){
        printf("  LINE:");
        for(iSet2 = lines.begin(); iSet2 != lines.end(); iSet2++)
          printf("%d ", *iSet2);
        printf("\n");

        getFutureLines(iSet->bm->getFileName(), lines);
      }


      if(count == 10)
        break;
      count++;
    }

  }

  if(!m_Settings->suppressOutput){
    printf("Database Size: %d\n", (int)m_Database.size());
    printf("KVAL         : %s\n", m_KVal.c_str());
    printf("Operation    : %s\n", operation.c_str());
    if(eTrust == m_Settings->searchType)
      printf("Search mode  : %s\n", "Trust");
    else if(eSimilarity == m_Settings->searchType)
      printf("Search mode  : %s\n", "Similarity");
    else if(ePredict== m_Settings->searchType)
      printf("Search mode  : %s\n", "Predict");
  }

  //HOST -- Statistics/results
  if (m_Settings->searchType== eTrust){
    if(result == NULL)
      result = new sResult;

    double topNext = 0.0;
    std::string topNextCircuit = "";
    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      if(operation == "KFR"){
        double scoreR = iSet->kfr;

        if(scoreR > 0.70){
          result->topMatch.push_back(iSet->name);
          result->topScore.push_back(scoreR);
        }
        else if(scoreR > 0.55){
          result->okayMatch.push_back(iSet->name);
          result->okayScore.push_back(scoreR);
        }
        else if(scoreR > topNext){
          topNext = scoreR;
          topNextCircuit = iSet->name;
        }

      }
      else{
        double scoreR = iSet->klr;
        double scoreMaxC = iSet->klc > iSet->klc2 ? iSet->klc : iSet->klc2;
        double scoreC = (iSet->klc + iSet->klc2) * scoreMaxC;

        if(scoreR > 0.70){
          result->topMatch.push_back(iSet->name);
          result->topScore.push_back(scoreR);
        }
        else if(scoreR > 0.55){
          result->okayMatch.push_back(iSet->name);
          result->okayScore.push_back(scoreR);
        }
        //Check to see there could be a possibility of containment
        //TODO: Need to adjust if we have a very large design, a decent sized design may take
        //      20% or less than the entire design. (Probably take size into account somehow)
        else if(scoreC > 1.1){
          result->topContain.push_back(iSet->name);
          result->conDir.push_back(iSet->direction);

          result->conRScore.push_back(scoreR);
          result->conCScore.push_back(scoreC);
          result->conCScore1.push_back(iSet->klc);
          result->conCScore2.push_back(iSet->klc2);
        }
        else if(scoreR > topNext){
          topNext = scoreR;
          topNextCircuit = iSet->name;
        }

      }
    }
    result->topNext = topNext;
    result->topNextCircuit = topNextCircuit;
  }

  if(!m_Settings->suppressOutput)
    printf("COMPLETE\n");
  return result;
}






/**
 * searchDatabase 
 *  Searches the database for a circuit similar to the reference 
 *  Outputs results in ranked order with circuits similar to reference
 */
sResult* Database::searchIDatabase(Birthmark* reference){
  std::string operation = m_Settings->kgramSimilarity;

  //Get the components of the Reference circuit
  std::list<std::string> maxRef, minRef, alphaRef;  //Functional
  std::list<std::string> maxDB, minDB, alphaDB;
  reference->getMaxSequence(maxRef);
  reference->getMinSequence(minRef);
  reference->getAlphaSequence(alphaRef);

  std::map<std::string, unsigned> featureRef;       //Structural
  std::map<std::string, unsigned> featureDB;
  reference->getFingerprint(featureRef);

  std::vector<unsigned> constantRef;                //Constant
  std::vector<unsigned> constantDB;
  reference->getBinnedConstants(constantRef);

  std::vector<int> statRef;				          			  //Stat
  std::vector<int> statDB;						  //Stat
  reference->getStat(statRef);

  std::vector<Score> scoreList;
  scoreList.reserve(m_Database.size());


  std::vector<int> foundToken(m_Database.size(), 0);

  std::map<std::string, int > kgram;  //KGram
  std::map<std::string, int >::iterator iMap;  //KGram
  std::map<std::string, std::vector<int> >::iterator iData;
  if(operation == "KFC" || operation == "KFR")
    reference->getKGramFreq(kgram);
  else if(operation == "KLC" || operation == "KLR")
    reference->getKGramList(kgram);

  int total = 0;
  for(iMap = kgram.begin(); iMap != kgram.end(); iMap++){
    iData = m_IDatabase.find(iMap->first);
    total += iMap->first.size();
    if(iData != m_IDatabase.end()){
      for(unsigned int i = 0; i < iData->second.size(); i++)
        foundToken[iData->second[i]]+=iData->first.size();
    }
  }



  double maxs = 0.0;
  double mins = 1000000.0;
  double maxc = 0.0;
  double minc = 1000000.0;
  double maxst = 0.0;
  double minst = 1000000.0;

  for(unsigned int i = 0; i < m_Database.size(); i++) {
    //printf("###################################################################################################\n");
    //if(!m_SuppressOutput)
    //printf("[DB] -- Comparing reference to %30s : KGRAMS: %d\n", m_Database[i]->getName().c_str(), m_Database[i]->getKGramListSize());
    //printf("##################################################################################################\n");
    //If it's the same circuit, skip
    if(m_Database[i]->getFileName() == reference->getFileName())
      continue;

    /////////////////////////////////////////////////////////////////////////////
    //   STRUCTURAL SEQUENCE COMARPISON
    //     Score is the total euclidean distance of all the features 
    /////////////////////////////////////////////////////////////////////////////
    m_Database[i]->getFingerprint(featureDB);

    double sScore= SIMILARITY::euclidean(featureRef, featureDB);

    //Note: Don't care are features not accounted for in both since distance is 0
    //printf("  * SSCORE: %f\n", sScore);
    if(sScore> maxs)    maxs = sScore;
    if(sScore< mins)    mins = sScore;





    /////////////////////////////////////////////////////////////////////////////
    //   CONSTANT SEQUENCE COMARPISON
    //     Score is the total euclidean distance of binned constant vector 
    /////////////////////////////////////////////////////////////////////////////
    //printf(" -- Comparing Constant Components....\n");
    m_Database[i]->getBinnedConstants(constantDB);
    double cScore = SIMILARITY::euclidean(constantRef, constantDB);
    //printf("  * CSCORE: %f\n", cScore);
    if(cScore > maxc)    maxc = cScore;
    if(cScore < minc)    minc = cScore;

    m_Database[i]->getStat(statDB);
    double stScore = SIMILARITY::euclidean(statDB, statRef);

    //printf("  * stCORE: %f\n", stScore);
    if(stScore > maxst)    maxst = stScore;
    if(stScore < minst)    minst = stScore;


    double intersection = (double) foundToken[i];

    std::map<std::string, int> kgramDB;
    if(operation == "KFC" || operation == "KFR")
      m_Database[i]->getKGramFreq(kgramDB);
    else if(operation == "KLC" || operation == "KLR")
      m_Database[i]->getKGramList(kgramDB);
    double total2 = 0.0;
    for(iMap = kgramDB.begin(); iMap != kgramDB.end(); iMap++){
      total2 += (double) iMap->first.size();
    }

    double unionVal = (double) total + total2 - intersection;
    double kScore;
    if(unionVal == 0.0){
      kScore = 0.0;
    }
    else{
      kScore = intersection / unionVal;
    }


    //Store the score results for this circuit
    Score score;
    score.id = m_Database[i]->getID();
    score.name = m_Database[i]->getFileName();
    score.tScore= stScore;
    score.sScore= sScore;
    score.cScore= cScore;
    score.klc= kScore;
    score.klc2= kScore;
    score.klr= kScore;
    score.kfc= kScore;
    score.kfr= kScore;

    score.bm = m_Database[i];
    score.direction = "<";

    //Need to store for normalization later. Data is in different scales
    scoreList.push_back(score);
  }

  if(!m_Settings->suppressOutput){
    printf("###############################################################\n");
    printf("###                    SEARCH COMPLETE                      ###\n");
    printf("###############################################################\n");
  }

  //Weights
  /*
     weights for date paper
   */

  /*
     86.8852
     double fweight = 0.90;  //If datapath birthmark, subtract .1
     double sweight = 0.05;
     double tweight = 0.00;
     double cweight = 0.05;
   */

  //Need to normalize data
  std::set<Score, setCompare> normalizedFinalScore_r; //ordered based on resemblance
  std::set<Score, setCompare> normalizedFinalScore_c; //ordered based on containment

  //Combine and sort the scores in ranking order
  for(unsigned int i = 0; i < scoreList.size(); i++){
    //Normalization of the scores to the range of 0-1
    //double newScoref = (double)(scoreList[i].fScore- minf) / (double)(maxf-minf);  

    double newScore = 0.0;
    double fweight = 1.0; 
    double sweight = 0.0;
    double tweight = 0.0;
    double cweight = 0.0;
    double newScoreC = 0.0;
    double newScoreR = 0.0;

    if(m_Settings->searchType== eSimilarity){
      double newScores = (double)(log(scoreList[i].sScore+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
      double newScoret = (double)(log(scoreList[i].tScore+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  
      double newScorec = (double)(log(scoreList[i].cScore+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

      if(operation == "KLC") newScore += (scoreList[i].klc * fweight * 100.0);
      else if(operation == "KLR") newScore += (scoreList[i].klr * fweight * 100.0);
      else if(operation == "KFC") newScore += (scoreList[i].kfc * fweight * 100.0);
      else if(operation == "KFR") newScore += (scoreList[i].kfr * fweight * 100.0);
      else
        throw cException("Operation not supported for searchType: SIM: " + operation);

      newScore += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
      newScoreC = newScore;
      newScoreR = newScore;
    }

    else if (m_Settings->searchType== eTrust){
      if(operation == "KFR")
        newScore += (scoreList[i].kfr * 100.0);
      else if(operation == "KLR")
        newScore += (scoreList[i].klr * 100.0);
      else if(operation == "KLC")
        newScore += (scoreList[i].klc * 100.0);
      else
        throw cException("Operation not supported for searchType: TRUST: " + operation);
      newScoreC = newScore;
      newScoreR = newScore;
    }

    else if(m_Settings->searchType == ePredict){
      double newScores = (double)(log(scoreList[i].sScore+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
      double newScoret = (double)(log(scoreList[i].tScore+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  
      double newScorec = (double)(log(scoreList[i].cScore+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

      if(operation[1] == 'F'){
        newScoreC = (scoreList[i].kfc * fweight * 100.0);
        newScoreR = (scoreList[i].kfr * fweight * 100.0);
      }
      else if(operation[1] == 'L'){
        newScoreC = (scoreList[i].klc * fweight * 100.0);
        newScoreR = (scoreList[i].klr * fweight * 100.0);
      }
      else
        throw cException("Operation not supported for searchType: PREDICT: " + operation);



      newScoreC += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
      newScoreR += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
        (1 - newScoret) * tweight * 100.0 +
        (1 - newScorec) * cweight * 100.0;
        //printf("NEW: %8.4f \n" , newScoreC);
    }
    else{
      throw cException("Unknown Search Type");
    }

    Score simc;
    simc.id = scoreList[i].id;
    simc.name = scoreList[i].name;
    simc.score = newScoreC;
    simc.fScore = scoreList[i].fScore;
    simc.klr = scoreList[i].klr;
    simc.klc = scoreList[i].klc;
    simc.klc2 = scoreList[i].klc2;
    simc.kfc = scoreList[i].kfc;
    simc.kfr = scoreList[i].kfr;
    simc.bm = scoreList[i].bm;
    normalizedFinalScore_c.insert(simc);

    Score simr;
    simr.id = scoreList[i].id;
    simr.name = scoreList[i].name;
    simr.score = newScoreR;
    simr.fScore = scoreList[i].fScore;
    simr.klr = scoreList[i].klr;
    simr.klc = scoreList[i].klc;
    simr.klc2 = scoreList[i].klc2;
    simr.kfc = scoreList[i].kfc;
    simr.kfr = scoreList[i].kfr;
    simr.bm = scoreList[i].bm;
    normalizedFinalScore_r.insert(simr);

  }


  // Print the scores
  int count = 1;
  std::set<Score, setCompare>::iterator iSet;
  std::string resultStr_c = ""; 
  std::string resultStr_r = ""; 
  sResult* result = NULL;
  if(!m_Settings->suppressOutput){
    if(result == NULL)
      result = new sResult;

    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      char buffer[100];
      sprintf(buffer, "R: %2d ", count);
      resultStr_r += buffer;
      sprintf(buffer, "SC:%7.4f  ", iSet->score);
      resultStr_r += buffer;
      sprintf(buffer, "LC:%5.2f  ", iSet->klc);
      resultStr_r += buffer;
      sprintf(buffer, "LC2:%5.2f  ", iSet->klc2);
      resultStr_r += buffer;
      sprintf(buffer, "LR:%5.2f  ", iSet->klr);
      resultStr_r += buffer;
      sprintf(buffer, "FC:%5.2f  ", iSet->kfc);
      resultStr_r += buffer;
      sprintf(buffer, "FR:%5.2f  \t", iSet->kfr);
      resultStr_r += buffer;
      sprintf(buffer, "%s", iSet->name.c_str());
      resultStr_r += buffer;
      resultStr_r += "\n";

      result->topMatch.push_back(buffer);

      if(!m_Settings->show_all_result && count == 10)
        break;
      count++;
    }

    count = 1;
    for(iSet = normalizedFinalScore_c.begin(); iSet != normalizedFinalScore_c.end(); iSet++){
      /*
         printf("R: %2d ", count);
         printf("SC:%7.4f  ", iSet->score);
      //printf("NF:%5.2f  ", iSet->nf);
      printf("NS:%5.4f  ", 1.0-iSet->ns);
      printf("NC:%5.4f  ", 1.0-iSet->nc);
      printf("ST:%5.2f  ", 1.0-iSet->stat);
      //printf("SC:%5.2f  ", iSet->ksc);
      //printf("SR:%5.2f  ", iSet->ksr);
      printf("LC:%5.2f  ", iSet->klc);
      printf("LC2:%5.2f  ", iSet->klc2);
      printf("LR:%5.2f  ", iSet->klr);
      printf("FC:%5.2f  ", iSet->kfc);
      printf("FR:%5.2f  ", iSet->kfr);
      printf("\tC:%s\n", iSet->name.c_str());
       */

      char buffer[100];
      sprintf(buffer, "R: %2d ", count);
      resultStr_c += buffer;

      sprintf(buffer, "SC:%7.4f  ", iSet->score);
      resultStr_c += buffer;
      sprintf(buffer, "LC:%5.2f  ", iSet->klc);
      resultStr_c += buffer;
      sprintf(buffer, "LC2:%5.2f  ", iSet->klc2);
      resultStr_c += buffer;
      sprintf(buffer, "LR:%5.2f  ", iSet->klr);
      resultStr_c += buffer;
      sprintf(buffer, "FC:%5.2f  ", iSet->kfc);
      resultStr_c += buffer;
      sprintf(buffer, "FR:%5.2f  \t", iSet->kfr);
      resultStr_c += buffer;
      sprintf(buffer, "%s", iSet->name.c_str());
      resultStr_c += buffer;
      resultStr_c += "\n";
      result->topContain.push_back(buffer);

      //printf(" %2d & %6.2f & %s\n", count, iSet->score, iSet->name.c_str()); //latex table
      if(!m_Settings->show_all_result && count == 10)
        break;
      count++;
    }


    result->ranked_result_c = resultStr_c;
    result->ranked_result_r = resultStr_r;
    //if(m_Settings->backEndProductivity == false){
    printf("Resemblance:\n%s\n\nContainment:\n%s\n", resultStr_r.c_str(), resultStr_c.c_str());
    //}
  }






  count = 1;
  std::list<std::string> endgrams;
  std::list<std::string>::iterator iList;
  std::string currentEndGram = "";

  if(t_CurLine == -1){
    if(!m_Settings->suppressOutput){
      reference->getEndGrams(endgrams);
      printf("Number of n-grams in reference circuit: %d\n", (int)endgrams.size());
      printf("No line number of current design given...skipping code prediction...\n");
    }
  }
  else{
    printf("Predicting future code based on existing hardware database...\n");
    //Get the endgrams with the current line as an end node
    reference->getEndGrams(endgrams, t_CurLine);
    printf("ENDGRAM: ");
    for(iList = endgrams.begin(); iList != endgrams.end(); iList++)
      printf(" %s, ", iList->c_str());
    printf("\n");

    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      printf("----------------------------------------------------------------\n");
      printf("CKT: %s count: %d\n", iSet->name.c_str(), count);

      std::set<int> lines;
      for(iList = endgrams.begin(); iList != endgrams.end(); iList++){
        std::string nextOp = iSet->bm->getFuture(*iList, lines);
        if(nextOp == "NONE") continue;
        printf("\tENDGRAM: %s  ", iList->c_str());
        printf("NEXT: %s\n", nextOp.c_str());
      }

      std::set<int>::iterator iSet2;
      if(lines.size() != 0){
        printf("  LINE:");
        for(iSet2 = lines.begin(); iSet2 != lines.end(); iSet2++)
          printf("%d ", *iSet2);
        printf("\n");

        getFutureLines(iSet->bm->getFileName(), lines);
      }


      if(count == 10)
        break;
      count++;
    }

  }

  if(!m_Settings->suppressOutput){
    printf("Database Size: %d\n", (int)m_Database.size());
    printf("KVAL         : %s\n", m_KVal.c_str());
    printf("Operation    : %s\n", operation.c_str());
    if(eTrust == m_Settings->searchType)
      printf("Search mode  : %s\n", "Trust");
    else if(eSimilarity == m_Settings->searchType)
      printf("Search mode  : %s\n", "Similarity");
    else if(ePredict== m_Settings->searchType)
      printf("Search mode  : %s\n", "Predict");
  }

  //HOST -- Statistics/results
  if (m_Settings->searchType== eTrust){
    if(result == NULL)
      result = new sResult;

    double topNext = 0.0;
    std::string topNextCircuit = "";
    for(iSet = normalizedFinalScore_r.begin(); iSet != normalizedFinalScore_r.end(); iSet++){
      if(operation == "KFR"){
        double scoreR = iSet->kfr;

        if(scoreR > 0.70){
          result->topMatch.push_back(iSet->name);
          result->topScore.push_back(scoreR);
        }
        else if(scoreR > 0.55){
          result->okayMatch.push_back(iSet->name);
          result->okayScore.push_back(scoreR);
        }
        else if(scoreR > topNext){
          topNext = scoreR;
          topNextCircuit = iSet->name;
        }

      }
      else{
        double scoreR = iSet->klr;
        double scoreMaxC = iSet->klc > iSet->klc2 ? iSet->klc : iSet->klc2;
        double scoreC = (iSet->klc + iSet->klc2) * scoreMaxC;

        if(scoreR > 0.70){
          result->topMatch.push_back(iSet->name);
          result->topScore.push_back(scoreR);
        }
        else if(scoreR > 0.55){
          result->okayMatch.push_back(iSet->name);
          result->okayScore.push_back(scoreR);
        }
        //Check to see there could be a possibility of containment
        //TODO: Need to adjust if we have a very large design, a decent sized design may take
        //      20% or less than the entire design. (Probably take size into account somehow)
        else if(scoreC > 1.1){
          result->topContain.push_back(iSet->name);
          result->conDir.push_back(iSet->direction);

          result->conRScore.push_back(scoreR);
          result->conCScore.push_back(scoreC);
          result->conCScore1.push_back(iSet->klc);
          result->conCScore2.push_back(iSet->klc2);
        }
        else if(scoreR > topNext){
          topNext = scoreR;
          topNextCircuit = iSet->name;
        }

      }
    }
    result->topNext = topNext;
    result->topNextCircuit = topNextCircuit;
  }

  printf("COMPLETE\n");
  return result;
}


//Given a set of line numbers, print out the lines of the design file
void Database::getFutureLines(std::string file, std::set<int>& linenums ){
  if(linenums.size() == 0) return;

  //for(unsigned int i = 0; i < linenums.size(); i++){
  std::ifstream ifs;
  ifs.open(file.c_str());
  if (!ifs.is_open()) throw cException("(Birthmark::getFuture:t1) Cannot open File: " + file);

  std::string line;
  int futureStep = 3;
  int curlinenum = 1;
  int start = *(linenums.begin())-1;
  int end = *(linenums.begin())+futureStep;

  while(getline(ifs, line)){
    //CHeck if the line is the one we want
    if(curlinenum >=start ) {
      printf("\t%3d: %s\n", curlinenum, line.c_str());
      curlinenum++;

      //Print the next few lines
      while(curlinenum <= end ){
        if(getline(ifs,line))
          printf("\t%3d: %s\n", curlinenum, line.c_str());
        else{
          printf("END OF FILE\n");
          return;
        }
        curlinenum++;
      }

      //Makes sure the next line to print isn't already printed
      linenums.erase(linenums.begin());
      if(linenums.size() == 0) {
        printf("\n");
        return;
        //break;
      }
      start = *(linenums.begin())-1 ;

      bool empty = false;
      while(start < curlinenum-1 ){
        linenums.erase(linenums.begin());
        if(linenums.size() == 0){
          printf("\n");
          return;
          //empty = true;
          //break;
        }
        start = *(linenums.begin())-1 ;
      }
      if(empty) break;

      end = *(linenums.begin())+futureStep;

      curlinenum--;  //Adjust for the additional increment
    }
    curlinenum++;
  }

  printf("\n");

}

/**
 * getFutureOp 
 *  Gets the future operation 
 */
void Database::getFutureOp(Birthmark* reference){
  std::list<std::string> endgrams;
  std::list<std::string>::iterator iList;
  reference->getEndGrams(endgrams, t_CurLine);

  for(iList = endgrams.begin(); iList != endgrams.end(); iList++)
    printf("\tENDGRAM: %s  \n", iList->c_str());

  if(endgrams.size() == 0){
    printf("[DB] -- No end gram found with current line number\n");
    return;
  }

  for(iList = endgrams.begin(); iList != endgrams.end(); iList++){
    std::string currentEndGram = *iList;
    printf("\n[DB] -- Checking n-gram: %s\n", iList->c_str());
    std::map<std::string, sGram2>::iterator iGram;
    iGram = m_KGramList.find(currentEndGram);
    if(iGram == m_KGramList.end()){
      printf("[DB] -- Previous n-gram not seen at all before...Decomposing the currentEndGram\n");

      //std::string prevEndGram = currentEndGram;

      do{
        currentEndGram = currentEndGram.substr(1, currentEndGram.length()-1);
        iGram = m_KGramList.find(currentEndGram);

      }while(iGram == m_KGramList.end() && currentEndGram.size() > 1);

      //if(prevEndGram == currentEndGram)
      if(currentEndGram.length() <= 1){
        printf("[DB] -- No future prediction found...\n");
        continue;
      }

      printf("New EndGram: %s\n", currentEndGram.c_str() );
    }

    std::map<std::string, int>::iterator iNext;
    for(iNext = iGram->second.next.begin(); iNext != iGram->second.next.end(); iNext++){
      printf(" * FUTURE: %s  ", iNext->first.c_str());
      printf("FREQ: %d\n", iNext->second);
      for(unsigned int k = 0; k < iGram->second.files[iNext->first].size(); k++){
        printf(" F: %s\n", iGram->second.files[iNext->first][k].c_str());

      }
    }
  }

}

/**
 * processKGramDatabase 
 *  Processes all the kgrams in the database
 *  Tries to set to predict the next possible node/line
 */
void Database::processKGramDatabase(){
  std::map<std::string, int> mkgramset;
  std::map<std::string, int> mkgramlist;
  std::map<std::string,int>::iterator iMap;

  for(unsigned int k = 0; k < m_Database.size(); k++) {

    std::map<std::string,int> kgramlist;
    std::map<std::string,int> kgramset;
    std::vector<std::map<std::string,int> > kgramcounter;

    m_Database[k]->getKGramList(kgramlist);
    m_Database[k]->getKGramSet(kgramset);

    for(iMap = kgramset.begin(); iMap != kgramset.end(); iMap++){
      mkgramset[iMap->first] = iMap->second;
    }

    for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
      mkgramlist[iMap->first] = iMap->second;
      std::string kstr = iMap->first;
      std::string km1 = kstr.substr(0, kstr.length()-1);
      std::string kmlast = kstr.substr(kstr.length()-1, kstr.length());

      std::map<std::string, sGram2>::iterator iGram;
      iGram = m_KGramList.find(km1);
      if(iGram  == m_KGramList.end()){
        sGram2 sgram;
        sgram.next[kmlast] = iMap->second;
        sgram.files[kmlast].push_back(m_Database[k]->getName());
        m_KGramList[km1] = sgram;
      }
      else{
        std::map<std::string, int>::iterator iNext;
        iNext = iGram->second.next.find(kmlast);
        if(iNext != iGram->second.next.end())
          iNext->second += iMap->second;
        else{
          iGram->second.next[kmlast] = iMap->second;
          iGram->second.files[kmlast].push_back(m_Database[k]->getName());
        }
      }
    }
  }

  int toplist = 0;
  int topset= 0;
  int totalset = 0;
  int totallist= 0;
  std::string topliststr = "";
  for(iMap = mkgramset.begin(); iMap != mkgramset.end(); iMap++){
    if(iMap->second > topset)
      topset = iMap->second;
    totalset+=iMap->second;
  }
  for(iMap = mkgramlist.begin(); iMap != mkgramlist.end(); iMap++){
    if(iMap->second > toplist){
      toplist = iMap->second;
      topliststr = iMap->first;

    }
    totallist+=iMap->second;
  }

  //printf ("UNIQUE: LIST: %lu SET: %lu FREQ: %lu\n", mkgramlist.size(), mkgramset.size(), mkgramcount.size());
  printf ("UNIQUE: TOPLIST: %d TOPSET: %d \n", toplist, topset);
  printf ("UNIQUE: TottalLIST: %d TotalSET: %d \n", totallist, totalset);
  printf ("UNIQUE: Topliststr: %s \n", topliststr.c_str());
}

/**
 * crossValidation 
 *  Performs cross validation
 */
void Database::crossValidation(){
  m_KGramList.clear();
  std::map<std::string,int>::iterator iMap;
  const int k_fold = 10;
  int testSize = m_Database.size()/k_fold;
  //printf("TEST SIZE: %d\n", (int)testSize);

  std::vector<unsigned> randomv;
  randomv.reserve(m_Database.size());
  for(unsigned i = 0; i < m_Database.size(); i++) randomv.push_back(i);
  std::random_shuffle(randomv.begin(), randomv.end());

  //Perform the validation k times moving the test set around
  unsigned int k = 0;
  double final_precision = 0.0;
  double final_applicability = 0.0;
  for(; k < k_fold; k++){
    int testStart = k*testSize;
    int testEnd= k*testSize + testSize;

    //Create the q-gram model with the specific training data train-test-train 

    int stop= testStart;
    int start = 0;
    int numprocessed = 0;
    std::set<int> indicesSearched;
    for(unsigned int ttt = 0; ttt < 2; ttt++){

      //printf("START: %d\tSTOP: %d\n", start, stop);
      for(; start < stop; start++) {
        std::map<std::string,int> kgramlist;
        m_Database[randomv[start]]->getKGramList(kgramlist);
        //printf("%4d:%4d ", start, randomv[start] );
        if(indicesSearched.find(randomv[start]) != indicesSearched.end()) exit(1);
        indicesSearched.insert(randomv[start]);
        numprocessed++;

        for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
          std::string kstr = iMap->first;
          std::string km1 = kstr.substr(0, kstr.length()-1);
          std::string kmlast = kstr.substr(kstr.length()-1, kstr.length());

          std::map<std::string, sGram2>::iterator iGram;
          iGram = m_KGramList.find(km1);
          if(iGram  == m_KGramList.end()){
            sGram2 sgram;
            sgram.next[kmlast] = iMap->second;
            sgram.files[kmlast].push_back(m_Database[randomv[start]]->getName());
            m_KGramList[km1] = sgram;
          }
          else{
            std::map<std::string, int>::iterator iNext;
            iNext = iGram->second.next.find(kmlast);
            if(iNext != iGram->second.next.end())
              iNext->second += iMap->second;
            else{
              iGram->second.next[kmlast] = iMap->second;
              iGram->second.files[kmlast].push_back(m_Database[randomv[start]]->getName());
            }
          }
        }
      }

      start+=testSize;
      stop = m_Database.size();

    }
    //printf("______________________________________________________________\n");
    //printf("Number of circuits processed for K = %d: %d\n", k, numprocessed);
    //printf("\nQ GRAM has been trained with training data!\n");
    numprocessed = 0;

    double numPositivePrediction = 0.0;
    double numNegativePrediction = 0.0;
    double totalPrediction = 0.0;
    double totalSearch = 0.0;

    //printf("START INDEX: %d\t\tEND INDEX: %d\n", testStart, testEnd);
    for(start = testStart; start < testEnd; start++) {
      std::map<std::string,int> kgramlist;
      //printf("%4d ", randomv[start] );
      m_Database[randomv[start]]->getKGramList(kgramlist);
      if(indicesSearched.find(randomv[start]) != indicesSearched.end()) exit(1);
      indicesSearched.insert(randomv[start]);
      numprocessed++;

      for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
        std::string kstr = iMap->first;

        std::string km1 = kstr.substr(0, kstr.length()-1);
        std::string kmlast = kstr.substr(kstr.length()-1, kstr.length());



        std::map<std::string, sGram2>::iterator iGram;
        iGram = m_KGramList.find(km1);
        if(iGram != m_KGramList.end()){
          totalPrediction += 1.0;
          std::map<std::string, int>::iterator iNext;
          std::string future = "";
          for(iNext = iGram->second.next.begin(); iNext != iGram->second.next.end(); iNext++){
            if(iNext->second > 0)
              future = iNext->first;
          }
          if(future == kmlast){  //Matching prediction
            numPositivePrediction += 1.0;
          }
          else{   //Mismatch in prediction
            numNegativePrediction = numNegativePrediction + 1.0;

          }
        }

        totalSearch += 1.0;


      }

    }
    //printf("numpos: %f, numneg: %f, totalpred: %f, totalsearch: %f\n", numPositivePrediction, numNegativePrediction, totalPrediction, totalSearch);

    double precision = numPositivePrediction / (totalPrediction);
    double applicability = totalPrediction/ totalSearch;
    //printf("PRECISION: %f\t\tAPPLICABILITY: %f\n", precision, applicability);
    //printf("Number of circuits processed for test set K = %d: %d\n", k, numprocessed);
    final_precision += precision;
    final_applicability += applicability;
  }


  printf("FINAL   PRECISION: %f\t\tAPPLICABILITY: %f\n", final_precision/(double)k_fold, final_applicability/(double)k_fold);

}


/**
 * autoCorrelate2
 *  Searches each circuit in the database against itself
 *  Outputs a table to read into excel to view the color mapping
 */
void Database::autoCorrelate2(){
  std::string operation = m_Settings->kgramSimilarity;
  //Initialize autocorrelation table
  std::vector<std::vector<double> > acTable;
  acTable.reserve(m_Database.size());	
  for(unsigned int i = 0; i < m_Database.size(); i++){
    std::vector<double> line(m_Database.size(), 0.0);
    acTable.push_back(line);
  }


  for(unsigned int k = 0; k < m_Database.size(); k++) {
    printf("[DB] -- Comparing %s to database\n", m_Database[k]->getName().c_str());
    /*
       std::list<std::string> maxRef, minRef, alphaRef;  //Functional
       m_Database[k]->getMaxSequence(maxRef);
       m_Database[k]->getMinSequence(minRef);
       m_Database[k]->getAlphaSequence(alphaRef);
     */

    std::map<std::string, unsigned> featureRef;       //Structural
    m_Database[k]->getFingerprint(featureRef);

    std::vector<unsigned> constantRef;                //Constant
    m_Database[k]->getBinnedConstants(constantRef);

    std::vector<int> statRef;						  //Stat
    m_Database[k]->getStat(statRef);

    std::map<std::string, int> kgramSetRef;  //KGram
    m_Database[k]->getKGramSet(kgramSetRef);
    std::map<std::string, int> kgramListRef;  //KGram
    m_Database[k]->getKGramList(kgramListRef);
    std::map<std::string, int > kgramFreqRef;  //KGram
    m_Database[k]->getKGramFreq(kgramFreqRef);

    std::vector<Score> scoreList;
    scoreList.reserve(m_Database.size());

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
      double fScore = 0.0;
      /*
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

       */
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


      /////////////////////////////////////////////////////////////////////////////
      //   KGRAM COMARPISON
      //     Score is the total euclidean distance of binned constant vector 
      /////////////////////////////////////////////////////////////////////////////
      std::map<std::string, int> kgramSetDB;  //KGram
      m_Database[i]->getKGramSet(kgramSetDB);
      std::map<std::string, int> kgramListDB;  //KGram
      m_Database[i]->getKGramList(kgramListDB);
      std::map<std::string, int> kgramFreqDB;  //KGram
      m_Database[i]->getKGramFreq(kgramFreqDB);
      //std::vector<std::map<std::string, int> > kgramMapDB;  //KGram
      //m_Database[i]->getKGramCounter(kgramMapDB);

      //double kScore = SIMILARITY::resemblance(kgramSetDB, kgramSetRef);
      double kScorel = 0.0;
      double kScorell = 0.0;
      double kScoref = 0.0;
      double kScorelr = 0.0;
      double kScorefr = 0.0;

      bool isRefSmaller = true; 
      if(kgramListRef.size() > kgramListDB.size())
        isRefSmaller = false;
      else if(kgramListRef.size() == kgramListDB.size()){
        for(unsigned int i = 0; i < statRef.size(); i++){
          if(statRef[i] ==  statDB[i])	continue;
          if(statRef[i] <  statDB[i]) isRefSmaller = true; 
          else isRefSmaller = false;
        }
      }

      if (m_Settings->allsim){
        kScoref = SIMILARITY::containment(kgramFreqRef, kgramFreqDB, m_Settings->countMatch);
        kScorefr= SIMILARITY::resemblance(kgramFreqRef, kgramFreqDB, m_Settings->partialMatch, m_Settings->countMatch);

        kScorel = SIMILARITY::containment(kgramListRef, kgramListDB, m_Settings->countMatch);
        kScorell = SIMILARITY::containment(kgramListDB, kgramListRef, m_Settings->countMatch);

        if(isRefSmaller){
          kScorelr = SIMILARITY::resemblance(kgramListRef, kgramListDB, m_Settings->partialMatch, m_Settings->countMatch);
        }
        else{
          kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef, m_Settings->partialMatch, m_Settings->countMatch);
        }

      }
      else if(operation == "KLC"){
        kScorel = SIMILARITY::containment(kgramListRef, kgramListDB, m_Settings->countMatch);
        kScorell = SIMILARITY::containment(kgramListDB, kgramListRef, m_Settings->countMatch);

      }
      else if(operation == "KFC")
        kScoref = SIMILARITY::containment(kgramFreqRef, kgramFreqDB, m_Settings->countMatch);
      else if(operation == "KLR"){
        if(isRefSmaller)
          kScorelr = SIMILARITY::resemblance(kgramListRef, kgramListDB, m_Settings->partialMatch, m_Settings->countMatch);
        else
          kScorelr = SIMILARITY::resemblance(kgramListDB, kgramListRef, m_Settings->partialMatch, m_Settings->countMatch);
      }
      else if(operation == "KFR")
        kScorefr= SIMILARITY::resemblance(kgramFreqRef, kgramFreqDB, m_Settings->partialMatch, m_Settings->countMatch);
      else 
        throw cException("Operation not supported for searchType: TRUST: $" + operation+"$");
      //printf("  * KSCORE: %f\n", kScore);

      Score score;
      score.id = m_Database[i]->getID();
      score.name = m_Database[i]->getFileName();
      score.fScore = fScore;
      score.tScore= stScore;
      score.sScore = sScore;
      score.cScore = cScore;
      score.klc= kScorel;
      score.klc2= kScorell;
      score.klr= kScorelr;
      score.kfc= kScoref;
      score.kfr= kScorefr;

      //Need to store for normalization later. Data is in different scales
      scoreList.push_back(score);
    }

    //Need to normalize data
    for(unsigned int i = 0; i < scoreList.size(); i++){
      double newScore = 0.0;
      double newScores= 0.0;
      double newScoret= 0.0;
      double newScorec= 0.0;

      if(m_Settings->searchType== eSimilarity){
        double fweight = 0.50;  //If datapath birthmark, subtract .1
        double sweight = 0.30;
        double tweight = 0.10;
        double cweight = 0.10;

        newScores = (double)(log(scoreList[i].sScore+1) - log(mins+1)) / (double)(log(maxs+1)-log(mins+1));
        newScoret = (double)(log(scoreList[i].tScore+1)- log(minst+1)) / (double)(log(maxst+1)-log(minst+1));  
        newScorec = (double)(log(scoreList[i].cScore+1) - log(minc+1)) / (double)(log(maxc+1)-log(minc+1));

        //if(operation == "BIRTHMARK") newScore +=newScoref * (fweight-0.1) * 100.0;
        if(operation == "KLC") newScore += (scoreList[i].klc * fweight * 100.0);
        else if(operation == "KLR") newScore += (scoreList[i].klr * fweight * 100.0);
        //else if(operation == "KSC") newScore += (scoreList[i].ksc * fweight * 100.0);
        //else if(operation == "KSR") newScore += (scoreList[i].ksr * fweight * 100.0);
        else if(operation == "KFC") newScore += (scoreList[i].kfc * fweight * 100.0);
        else if(operation == "KFR"){
          newScore += (scoreList[i].kfr * fweight * 100.0);
          printf("KFR\n");
        }
        else
          throw cException("Operation not supported for searchType: TRUST: $" + operation+"$");

        newScore += (1 - newScores) * sweight * 100.0 +      //1 is dissimilar. Need to switch
          (1 - newScoret) * tweight * 100.0 +
          (1 - newScorec) * cweight * 100.0;
      }
      else if (m_Settings->searchType== eTrust){
        if(operation == "KFR")
          newScore += (scoreList[i].kfr * 100.0);
        else if(operation == "KLR")
          newScore += (scoreList[i].klr * 100.0);
        else if(operation == "KLC")
          newScore += (scoreList[i].klc * 100.0);

        double scoreR = scoreList[i].klr;
        double scoreMaxC = scoreList[i].klc > scoreList[i].klc2 ? scoreList[i].klc : scoreList[i].klc2;
        double scoreC = (scoreList[i].klc + scoreList[i].klc2) * scoreMaxC;

        if(scoreR <= 0.55){
          //Check to see there could be a possibility of containment
          //TODO: Need to adjust if we have a very large design, a decent sized design may take
          //      20% or less than the entire design. (Probably take size into account somehow)
          if(scoreC > 1.1){
            newScore = 200.0;
          }
        }	
      }


      acTable[k][i] = newScore;
    }
  }

  std::ofstream ofs; 
  ofs.open("data/heatmap.csv");
  if(!m_Settings->suppressOutput){
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
      double fScore = 0.0;
      /*
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
       */

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
  if(!m_Settings->suppressOutput){
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

std::string Database::findLargestGram(std::string currentEndGram){
  std::map<std::string, sGram2>::iterator iGram;
  iGram = m_KGramList.find(currentEndGram);
  if(iGram == m_KGramList.end()){
    printf("[DB] -- Previous n-gram not seen at all before...Decomposing the currentEndGram\n");

    do{
      currentEndGram = currentEndGram.substr(1, currentEndGram.length()-1);
      iGram = m_KGramList.find(currentEndGram);

    }while(iGram == m_KGramList.end() && currentEndGram.size() > 1);

    //if(prevEndGram == currentEndGram)
    if(currentEndGram.length() <= 1){
      printf("[DB] -- No future prediction found...\n");
      return "";
    }

    printf("New EndGram: %s\n", currentEndGram.c_str() );
  }

  return currentEndGram;
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
  m_Settings->suppressOutput = !m_Settings->suppressOutput;
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


/**
 * printStats
 *  Prints some statistics about the database that was extracted
 */
void Database::printStats(){
  printf("\n[DB] -- STATISTICS\n");
  printf("----------------------------------------------------------------------\n");
  printf(" - %30s: %d\n", "K", m_KInt);
  printf(" - %30s: %lu\n", "Number of Circuits", m_Database.size());
  printf("----------------------------------------------------------------------\n");

  unsigned int kl_size_total_u = 0;
  unsigned int kl_size_total = 0;
  std::map<std::string, int> mkgramlist;
  std::map<std::string, int>::iterator iMap;

  for(unsigned int i = 0; i < m_Database.size(); i++) {
    kl_size_total_u += m_Database[i]->getKGramListSize();

    //process all the kgrams
    std::map<std::string,int> kgramlist;
    m_Database[i]->getKGramList(kgramlist);
    if(kgramlist.find("BMF^^^=") != kgramlist.end()){
      printf("BMFCircuit: %50s\t\n", m_Database[i]->getFileName().c_str() );
    }
    for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
      if(iMap->first.length() > 2)
        kl_size_total+= iMap->second;

      if(mkgramlist.find(iMap->first) == mkgramlist.end())
        mkgramlist[iMap->first] = 1;
      else
        mkgramlist[iMap->first] ++;
    }
  }

  std::map<int, std::vector<std::string> > count;
  std::map<int, std::vector<std::string> >::iterator iCount; 

  for(iMap = mkgramlist.begin(); iMap != mkgramlist.end(); iMap++){
    if(iMap->first.length() > 2)
      count[iMap->second].push_back(iMap->first);
  }

  int cunique = 0;
  int scunique = 0;
  double punique = 0.0;
  for(unsigned int i = 0; i < m_Database.size(); i++) {
    //process all the kgrams
    std::map<std::string,int> kgramlist;
    m_Database[i]->getKGramList(kgramlist);
    m_Database[i]->getKGramList(kgramlist);
    int unique = 0;
    for(iMap = kgramlist.begin(); iMap != kgramlist.end(); iMap++){
      if(mkgramlist[iMap->first] == 1) {
        unique++;
      }
    }

    scunique+=unique;
    punique += (double)unique / (double) kgramlist.size();

    printf("Circuit: %50s\tNumber unique: %d\n", m_Database[i]->getFileName().c_str(), unique);
    if(unique > 0)
      cunique++;
  }

  printf(" - %30s: %u\n", "Number of circuits with unique", cunique);
  printf(" - %30s: %f\n", "Avg number of unique per ckt", (float)scunique/(float)m_Database.size());
  printf(" - %30s: %f\n", "percent unique per ckt", (float)punique/(float)m_Database.size());
  printf(" - %30s: %u\n", "Total KGRAMs", kl_size_total);
  printf(" - %30s: %u\n", "Total unique KGRAMs", (int)mkgramlist.size());
  int counter = 0;
  printf("Number of KGRAMS\tTotal Number of kGRAM that exist\n");
  for(iCount = count.begin(); iCount != count.end(); iCount++){
    printf("%u\t%d\n", iCount->first, (int)iCount->second.size());
    /*
       for(unsigned int i = 0; i < iCount->second.size(); i++)
       printf("   - %30s:\n", iCount->second[i].c_str());
     */
    if(counter == 10) break;
    counter++;

  }
}

/**
 * printSettings
 *  Prints the settings  
 */
void Database::printSettings(){
  printf("[DB] -- Settings:\n");
  printf(" - All Similarity Match: %d\n", m_Settings->allsim);
  printf(" - KGram Similarity    : %s\n", m_Settings->kgramSimilarity.c_str());
  printf(" - Partial Kgram Match : %d\n", m_Settings->partialMatch);
  printf(" - Partial Kgram Match : %d\n", m_Settings->countMatch);
  if(eTrust == m_Settings->searchType)
    printf(" - Search mode         : %s\n", "Trust");
  else
    printf(" - Search mode         : %s\n", "Similarity");
}



