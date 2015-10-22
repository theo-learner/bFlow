/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  birthmark.cpp
	@    Datastructure for holding  birthmark
	@	
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "birthmark.hpp"
using namespace rapidxml;

/**
 * Constructor
 *  Default Constructor
 */
Birthmark::Birthmark(){
	m_BinnedConstants.resize(m_NumBin+2, 0); //Add 2 for z,x constants
	m_MaxSequence.push_back("a");
	m_MinSequence.push_back("a");
	m_AlphaSequence.push_back("a");
}

/**
 * Constructor
 *  Loads birthmark from XML 
 */
Birthmark::Birthmark(xml_node<>* cktNode){
	m_MaxSequence.push_back("a");
	m_MinSequence.push_back("a");
	m_AlphaSequence.push_back("a");
	m_BinnedConstants.resize(m_NumBin+2, 0); //Add 2 for z,x constants
	importXML(cktNode);
}

/**
 * Destructor 
 */
Birthmark::~Birthmark(){
}










/**
 * importXML 
 *  Loads data from the XML file into the birthmark 
 */
bool Birthmark::importXML(xml_node<>* cktNode){
	if(cktNode== NULL)
		throw cException("(Birthmark::importXML:T15) cktNode is NULL") ;
	std::string cktNodeName = cktNode->name();
	if(cktNodeName != "ckt"){
		printf("TAG: %s\n", cktNodeName.c_str());
		throw cException("(Birthmark::importXML:T1) Tag not found") ;
	}

	std::string cktName = "===";  
	std::string fileName= "===";  
	int id = -2;


	//Get the name and ID of the circuit (Variable Order) 
	xml_attribute<>* cktAttr = cktNode->first_attribute();
	while(cktAttr != NULL){
		std::string cktAttrName = cktAttr->name();
		if(cktAttrName == "name") cktName = cktAttr->value(); 
		else if(cktAttrName == "id") id = s2i::string2int(cktAttr->value()); 
		else if(cktAttrName == "file") fileName = cktAttr->value(); 
		else throw cException("(Birthmark::importXML:T3) Unexpected Attribute Tag Found: "+ cktAttrName + "\n");
		cktAttr = cktAttr->next_attribute();
	}

	//if(id < -1 || cktName == "===") throw cException("(Birthmark::importXML:T6) Attribute Error") ;

	//Set the ID and Name of the circuit
	setID(id);
	setName(cktName);
	m_TopFile = fileName;
	//printf("[BM] -- Importing Circuit: %s\n", cktName.c_str());

	std::map<unsigned, unsigned> fingerprint;
	std::list<std::string> maxseq;
	std::list<std::string> minseq;
	std::set<int> constants;

	//Read in data of the XML File
	xml_node<>* featureNode = cktNode->first_node();
	while (featureNode!= NULL){
		std::string featureNodeName = featureNode->name();
		if(featureNodeName == "max")
			addMaxSequence(featureNode->value());
		else if(featureNodeName == "min")
			addMinSequence(featureNode->value());
		else if(featureNodeName == "alph")
			addAlphaSequence(featureNode->value());
		else if(featureNodeName == "cnst"){
			std::string constStr = featureNode->value();
			int separator = constStr.find_first_of(":");
			std::string constant = constStr.substr(0, separator);
			std::string count = constStr.substr(separator+1, constStr.length()-separator);
			addConstant(s2i::string2int(constant.c_str()), 
					s2i::string2int(count.c_str()));
		}
		else if(featureNodeName == "stat"){
			std::string statstr = featureNode->value();
			setStatstr(statstr);
			if(m_StatstrV.size() != 0) throw cException("(Birthmark::importXML:T8) Stat vector size is not empty") ;
			strtk::parse(statstr, ",", m_StatstrV);
		}
		else if(featureNodeName == "fp"){

			//Get the name and ID of the circuit 
			xml_attribute<>* fpAttr = featureNode->first_attribute();
			if(fpAttr == NULL) throw cException("(Birthmark::importXML:T7) No FP attribute found") ;
			std::string fAttrName= fpAttr->name();
			std::string featureName;
			if(fAttrName == "type") {
				featureName = fpAttr->value(); 
				//Store the attribute into the fingerprint;
				addFingerprint(featureName, (unsigned)s2i::string2int(featureNode->value()));
			}
			//########################################################

		}
		else if(featureNodeName == "kl"){
			//CNT Attribute
			xml_attribute<>* kAttr = featureNode->first_attribute();
			if(kAttr == NULL) throw cException("(Birthmark::importXML:T10) No CNT attribute found") ;
			std::string kAttrName= kAttr->name();

			if(kAttrName != "cnt") throw cException("(Birthmark::importXML:T10) Unknown attr found for kgram: " + kAttrName) ;
			int count = s2i::string2int(kAttr->value()); 

			xml_node<>* lNode = featureNode->first_node();
			std::string kstr = "";
			std::vector<std::vector<int> > lineVector;
			while(lNode != NULL){
				std::string lNodeName = lNode->name();
				if(lNodeName == "dp")
					kstr = lNode->value();
				else if(lNodeName == "ln"){
					std::string linenumstring= lNode->value();
					std::vector<int> linenum;
					strtk::parse(linenumstring, ",", linenum);
					lineVector.push_back(linenum);
				}
				else throw cException("(Birthmark::importXML:T12) Unknown LNode: " + lNodeName);

				lNode= lNode->next_sibling(); 
			}

			m_kgramlist[kstr] = count;
			m_kgramline[kstr] = lineVector;
			addKTable(kstr, lineVector);

			//Calculate the frequency and set count:
			std::string kstr_sorted = kstr;
			std::sort(kstr_sorted.begin(), kstr_sorted.end());
			std::string kset;
			std::map<char, int> kfreq;
			std::map<char, int>::iterator iFreq;
			char prev = '#';

			for(unsigned int i = 0; i < kstr_sorted.length(); i++){

				if(kstr_sorted[i] != prev){
					//Set
					kset += kstr_sorted[i];

					//Freq
					std::pair<std::map<char, int>::iterator, bool> ret;
					ret = kfreq.insert(std::pair<char, int> (kstr_sorted[i], 1));
					iFreq = ret.first;
					prev = kstr_sorted[i];
				}
				else{
					iFreq->second++;
				}
			}

		 	m_kgramset[kset]++;
			m_kgramfreq[kfreq]++;


		}
		/*
			 else if(featureNodeName == "KSET"){
			 std::string kstr = featureNode->value();

			 xml_attribute<>* kAttr = featureNode->first_attribute();
			 if(kAttr == NULL) throw cException("(Birthmark::importXML:T10) No CNT attribute found") ;
			 std::string kAttrName= kAttr->name();

			 if(kAttrName != "CNT") throw cException("(Birthmark::importXML:T10) Unknown attr found for kgram: " + kAttrName) ;
			 int count = s2i::string2int(kAttr->value()); 

			 m_kgramset[kstr] = count;
			 }
			 else if(featureNodeName == "KCOUNT"){
			 xml_attribute<>* kAttr = featureNode->first_attribute();
			 if(kAttr == NULL) throw cException("(Birthmark::importXML:T11) No CNT attribute found") ;
			 std::string kAttrName= kAttr->name();

			 if(kAttrName != "CNT") throw cException("(Birthmark::importXML:T11) Unknown attr found for kgram: " + kAttrName) ;
			 int count = s2i::string2int(kAttr->value()); 

			 xml_node<>* fncNode = featureNode->first_node();
			 std::map<std::string, int> kgramc;

			 while (fncNode != NULL){
			 xml_attribute<>* kfAttr = fncNode->first_attribute();
			 if(kfAttr == NULL) throw cException("(Birthmark::importXML:T12) No CNT attribute found") ;
			 std::string kfAttrName= kfAttr->name();

			 if(kfAttrName != "CNT") throw cException("(Birthmark::importXML:T12) Unknown attr found for kgram: " + kfAttrName) ;
			 int fnccount = s2i::string2int(kfAttr->value()); 
			 kgramc[fncNode->value()] = fnccount;

			 fncNode= fncNode->next_sibling(); 
			 }

			 m_kgramcount.push_back(kgramc);
		//m_kgramfreq.insert(kgramc);
		m_kgramfreq[kgramc] = count;
		//m_kgramcountc.push_back(count);
		}
		 */
		else if(featureNodeName == "endkl"){
			xml_node<>* lNode = featureNode->first_node();
			std::string kstr = "";

			std::vector<std::vector<int> > lineVector;
			while(lNode != NULL){
				std::string lNodeName = lNode->name();
				//TODO: If don't need line numbe associated with the reference, remove
				if(lNodeName == "ln"){
					/*
						 std::string linenumstring= lNode->value();
						 std::vector<int> linenum;
						 strtk::parse(linenumstring, ",", linenum);
						 lineVector.push_back(linenum);
					 */
				}
				else if(lNodeName == "dp")
					kstr = lNode->value();
				else throw cException("(Birthmark::importXML:T12) Unknown LNode: " + lNodeName);

				lNode= lNode->next_sibling(); 
			}

			m_EndGrams.push_back(kstr);
		}
		else throw cException("(Birthmark::importXML:T12) Unknown tag found in XML: " + featureNodeName);


		featureNode= featureNode->next_sibling(); 
	}

	return true;
}



int Birthmark::getKGramSetSize(){
	return m_kgramset.size(); 
}
int Birthmark::getKGramListSize(){
	return m_kgramlist.size(); 
}
int Birthmark::getKGramCounterSize(){
	return m_kgramcount.size(); 
}
int Birthmark::getKGramFreq(){
	return m_kgramfreq.size(); 
}







/**
 * getMaxSequence
 *  Returns maximum sequence list
 */
void Birthmark::getMaxSequence(std::list<std::string>& rVal){
	rVal = m_MaxSequence;
}

/**
 * getMinSequence
 *  Returns minimum sequence list
 */
void Birthmark::getMinSequence(std::list<std::string>& rVal){
	rVal = m_MinSequence;
}

/**
 * getAlphaSequence
 *  Returns max alpha sequence list
 */
void Birthmark::getAlphaSequence(std::list<std::string>& rVal){
	rVal = m_AlphaSequence;
}

/**
 * getConstants
 *  Returns constants  
 */
void Birthmark::getConstants(std::set<int>& rVal){
	rVal = m_Constants;
}

/**
 * getFingerprint
 *  Returns fingerprint 
 */
void Birthmark::getFingerprint(std::map<std::string, unsigned>& rVal){
	rVal = m_Fingerprint;
}

/**
 * getKGramList
 *  Returns Kgram set version 
 */
void Birthmark::getKGramList(std::map<std::string, int >& rVal){
	rVal = m_kgramlist;
}

/**
 * getKGramSet
 *  Returns Kgram set version 
 */
void Birthmark::getKGramSet(std::map<std::string, int >& rVal){
	rVal = m_kgramset;
}

/**
 * getKGramCounter
 *  Returns Kgram counter version 
 */
void Birthmark::getKGramFreq(std::map<std::map<char, int>, int >& rVal){
	//void Birthmark::getKGramFreq(std::set<std::map<std::string, int> >& rVal){
	rVal = m_kgramfreq;
}


/**
 * getKGramCounter
 *  Returns Kgram counter version 
 */
void Birthmark::getKGramCounter(std::vector<std::map<std::string, int> >& rVal){
	rVal = m_kgramcount;
}

/**
 * getEndGrams
 *  Returns EndGrams 
 */
void Birthmark::getEndGrams(std::list<std::string>& rVal){
	rVal = m_EndGrams;
}

/**
 * getEndGrams
 *  Returns the longest endGrams of a given line number
 */
void  Birthmark::getEndGrams(std::list<std::string>& endGrams, int line){
	std::map<std::string, std::vector<std::vector<int> > >::iterator iMap;
	std::set<std::string> currentEndGram;
	std::set<std::string> currentEndGram2; //The grams with line numbers not at the end

	int maxLineIndex = 0;
	int maxGramLength= 0;
	for(iMap = m_kgramline.begin(); iMap != m_kgramline.end(); iMap++){
		for(unsigned int i = 0; i < iMap->second.size(); i++){
			int lineIndex = iMap->second[i].size()-1;
			int endLine = iMap->second[i][lineIndex] ;
			if(endLine == line){
				if(maxGramLength <= (int)iMap->first.length()){
					//printf("ENDGRAM FOUND: %s\n", iMap->first.c_str());
					if(maxGramLength < (int)iMap->first.length()){
						currentEndGram.clear();
						maxGramLength = iMap->first.length();
					}
					currentEndGram.insert(iMap->first);

				}

				continue;
			}

			while(endLine == -1 && lineIndex >= 0){
				lineIndex--;	
				endLine = iMap->second[i][lineIndex];
				if(endLine == line && lineIndex >= maxLineIndex){
					//Reset the list if there is an index higher
					if(lineIndex > maxLineIndex){
						currentEndGram2.clear();
						maxLineIndex = lineIndex;
					}

					currentEndGram2.insert(iMap->first);
				}
			}

		}
	}



	std::set<std::string>::iterator iSet;
	if(currentEndGram.size() > 0){
		if(currentEndGram.size() > 1)
			printf("[WARNING] -- Multiple possible Q-Gram for current reference position found\n");

		for(iSet = currentEndGram.begin(); iSet != currentEndGram.end(); iSet++)
			endGrams.push_back(*iSet);
	}
	else if(currentEndGram2.size() >0){
		if(currentEndGram2.size() > 1)
			printf("[WARNING] -- Multiple possible Q-Gram for current reference position found\n");
		for(iSet = currentEndGram2.begin(); iSet != currentEndGram2.end(); iSet++)
			endGrams.push_back(*iSet);
	}

}

/**
 * getFuture
 *  Searches for possible future lines in the code 
 */
std::string Birthmark::getFuture(std::string gram, std::set<int>& linenums){
	std::map<std::string, sGram>::iterator iMap;
	iMap = m_ktable.find(gram);
	if(iMap == m_ktable.end()){
		//printf("NO ENDGRAM: %s\n", gram.c_str());
		return "NONE";
	}

	for(unsigned int i = 0; i < iMap->second.linenum.size(); i++){
		int size = iMap->second.linenum[i].size()-1;
		int linenum = iMap->second.linenum[i][size];
		while(linenum == -1 && size >= 0){
			size--;
			linenum = iMap->second.linenum[i][size];
		}


		//ss<<linenum<<",";
		linenums.insert(linenum);
		if(size > 0){
			linenum = iMap->second.linenum[i][size-1];
			linenums.insert(linenum);
		}
	}



	return iMap->second.next;
}

/**
 * getName
 *  Returns circuit name 
 */
std::string Birthmark::getName(){
	return m_Name;
}

/**
 * getFileName
 *  Returns circuit name 
 */
std::string Birthmark::getFileName(){
	return m_TopFile;
}

/**
 * getMaxSequence
 *  Returns maximum sequence list
 */
int Birthmark::getID(){
	return m_ID;
}

/**
 * getNumFPSubcomponents
 *  Returns the number of subcomponents the fingerprint represents
 */
unsigned Birthmark::getNumFPSubcomponents(){
	return m_Fingerprint.size();
}

/**
 * getStatstr
 *  Returns the statistics string 
 */
std::string Birthmark::getStatstr(){
	return m_Statstr;
}

/**
 * getStat
 *  Returns the statistics vector 
 */
void Birthmark::getStat(std::vector<int>& rVal){
	rVal = m_StatstrV;
}

/**
 * getAvgSequenceLength
 *  Returns average sequence length of all the sequences in the functional 
 *  component
 */
double Birthmark::getAvgSequenceLength(){
	std::list<std::string>::iterator it;
	int totalLength = 0;
	for(it = m_MaxSequence.begin(); it != m_MaxSequence.end(); it++)
		totalLength += it->length();	
	for(it = m_MinSequence.begin(); it != m_MinSequence.end(); it++)
		totalLength += it->length();	
	for(it = m_AlphaSequence.begin(); it != m_AlphaSequence.end(); it++)
		totalLength += it->length();	

	int numSequence = m_MaxSequence.size() + m_MinSequence.size() + m_AlphaSequence.size();

	return (double) totalLength / (double) numSequence;

}

/**
 * getBinnedConstants
 *  Returns a vector of bins counting the number of constants
 *  0, 1, 2, 3....64, 65-127, 128, 129-255, 256....2^20, >2^20, x, z
 */
void Birthmark::getBinnedConstants(std::vector<unsigned>& rval){
	rval = m_BinnedConstants;
}

/**
 * getBinnedConstants
 *  Returns a vector of bins counting the number of constants
 *  0, 1, 2, 3....64, 65-127, 128, 129-255, 256....2^20, >2^20, x, z
 */
void Birthmark::getBinnedConstants2(std::vector<unsigned>& rval){
	rval.clear();
	rval.resize(m_NumBin+2, 0); //Add 2 for z,x constants

	std::set<int>::iterator iSet;
	for(iSet = m_Constants.begin(); iSet != m_Constants.end(); iSet++){
		//printf("CONST: %d\n", *iSet);

		//If -2, constant is a don't care 
		if((*iSet) == -2)        rval[m_NumBin]++;

		//If -3, constant is high impedance
		else if((*iSet) == -3)   rval[m_NumBin+1]++;

		//If number is higher than the highest bin, place in highest bin
		else if((*iSet) < 0)     rval[m_NumBin-1]++;

		//If number is less than 64 place in their respective bin
		else if((*iSet) <= 64)   rval[*iSet]++;

		//If numbers are higher than 64
		else{
			//printf("SEARING...\n");
			unsigned binIndex = 65;
			unsigned base = 128;
			bool binned = false;

			//TODO: Could calculate index of bin...
			for(;binIndex < (m_NumBin-1); binIndex++){
				//Odd bins hold the rangles between 2^k and 2^(k+1) -1
				if(binIndex % 2 == 1){
					if((unsigned) *iSet  < base ){
						rval[binIndex]++;
						binned = true;
						break;
					}
				}
				else{
					if((unsigned)*iSet == base ){
						binned = true;
						rval[binIndex]++;
						break;
					}
					base = base<<1;
				}
			}

			//If not within the planned range, constant is too large
			if(!binned)  rval[m_NumBin-1]++;

		}
	}
}












/**
 * getMaxSequence
 *  Sets the max sequence of the birthmark 
 */
void Birthmark::setMaxSequence(std::list<std::string>& val){
	m_MaxSequence = val;
}

/**
 * getMinSequence
 *  Sets the min sequence of the birthmark 
 */
void Birthmark::setMinSequence(std::list<std::string>& val){
	m_MinSequence = val;
}

/**
 * getAlphaSequence
 *  Sets the max alpha sequence of the birthmark 
 */
void Birthmark::setAlphaSequence(std::list<std::string>& val){
	m_AlphaSequence = val;
}

/**
 * setConstants
 *  Sets the constants of the birthmark
 */
void Birthmark::setConstants(std::set<int>& val){
	m_Constants = val;
}

/**
 * setFingerprint 
 *  Sets the structural fingerprint of the birthmark
 */
void Birthmark::setFingerprint(std::map<std::string , unsigned >& val){
	m_Fingerprint = val;
}

/**
 * setName 
 *  Sets the circuit name
 */
void Birthmark::setName(std::string name){
	m_Name = name;
}

/**
 * setID 
 *  Sets the ID of the circuit
 */
void Birthmark::setID(int id){
	m_ID = id;
}

/**
 * setStatstr
 *  Sets the statistics str
 */
void Birthmark::setStatstr(std::string stat){
	m_Statstr= stat;
}








/**
 * addKTable
 *  Adds an entry into the kgram table for lookup 
 */
void Birthmark::addKTable(std::string kstr, std::vector<std::vector<int> >& line){
	std::string km1 = kstr.substr(0, kstr.length()-1);
	std::string kmlast = kstr.substr(kstr.length()-1, kstr.length());

	std::map<std::string, sGram>::iterator iGram;
	iGram = m_ktable.find(km1);

	if(iGram == m_ktable.end()){
		sGram sgram;
		sgram.next = kmlast;
		sgram.linenum.insert(sgram.linenum.end(), line.begin(), line.end());
		m_ktable[km1] = sgram;
	}
	else{
		iGram->second.next = kmlast;
		iGram->second.linenum.insert(iGram->second.linenum.end(), 
				line.begin(), line.end());
	}
}



/**
 * addMaxSequence 
 *  Adds a sequence to the max sequence list 
 */
void Birthmark::addMaxSequence(std::string seq){
	m_MaxSequence.push_back(seq);
}

/**
 * addMinSequence 
 *  Adds a sequence to the min sequence list 
 */
void Birthmark::addMinSequence(std::string seq){
	m_MinSequence.push_back(seq);
}

/**
 * addAlphaSequence 
 *  Adds a sequence to the max alpha sequence list 
 */
void Birthmark::addAlphaSequence(std::string seq){
	m_AlphaSequence.push_back(seq);
}

/**
 * addConstant
 *  Adds a constant to the constant list 
 */
void Birthmark::addConstant(int constant, int count){
	count += 1000;
	//If -2, constant is a don't care 
	if(constant == -2)        m_BinnedConstants[m_NumBin] += count;

	//If -3, constant is high impedance
	else if(constant == -3)   m_BinnedConstants[m_NumBin+1] += count;

	//If number is higher than the highest bin, place in highest bin
	else if(constant < 0)     m_BinnedConstants[m_NumBin-1] += count;

	//If number is less than 64 place in their respective bin
	else if(constant <= 64)   m_BinnedConstants[constant]+= count;

	//If numbers are higher than 64
	else{
		//printf("SEARING...\n");
		unsigned binIndex = 65;
		unsigned base = 128;
		bool binned = false;

		//TODO: Could calculate index of bin...
		for(;binIndex < (m_NumBin-1); binIndex++){
			//Odd bins hold the rangles between 2^k and 2^(k+1) -1
			if(binIndex % 2 == 1){
				if((unsigned) constant< base ){
					m_BinnedConstants[binIndex] += count;
					binned = true;
					break;
				}
			}
			else{
				if((unsigned)constant == base ){
					binned = true;
					m_BinnedConstants[binIndex] += count;
					break;
				}
				base = base<<1;
			}
		}

		if(!binned)  m_BinnedConstants[m_NumBin-1]+=count;
	}

	//If not within the planned range, constant is too large
}

/**
 * addConstant
 *  Adds a constant to the constant list 
 */
void Birthmark::addConstant(int constant){
	m_Constants.insert(constant);
}


/**
 * addFingerprint
 *  Adds a feature into the fingerprint 
 */
void Birthmark::addFingerprint(std::string featureName, unsigned feature){
	//This emphasizes the distance between zero and 1. 
	//We want a 4-3 match to be closer than a 0-1 match
	if(feature != 0)
		feature += 1000;
	m_Fingerprint[featureName] = feature;
}

/**
 * addFingerprint
 *  Constructs a new feature and adds it into the fingerprint list 
 */
void Birthmark::addFingerprint(std::string featureName, unsigned size, unsigned count){
}










/**
 * print
 *  Prints the contents of the birthmark 
 */
void Birthmark::print(){
	printf("---------------------------------------------------------------\n"); 
	printf(" Birthmark: CKT: %s ID: %d\n", m_Name.c_str(), m_ID);
	printf("---------------------------------------------------------------\n"); 

	//Print the functional
	std::list<std::string>::iterator it;
	for(it = m_MaxSequence.begin(); it != m_MaxSequence.end(); it++)
		printf("Max Sequence: %s\n", it->c_str());

	for(it = m_MinSequence.begin(); it != m_MinSequence.end(); it++)
		printf("Min Sequence: %s\n", it->c_str());

	for(it = m_AlphaSequence.begin(); it != m_AlphaSequence.end(); it++)
		printf("Alpha Sequence: %s\n", it->c_str());

	//Print the constant
	printf("Constants: ");	
	/*std::set<int>::iterator iSet;
		for(iSet = m_Constants.begin(); iSet != m_Constants.end(); iSet++)
		printf("%d ", *iSet);*/

	for(unsigned int i = 0; i < m_BinnedConstants.size(); i++)
		printf("%d ", m_BinnedConstants[i]);

	printf("Statistics: ");	
	for(unsigned int i = 0; i < m_StatstrV.size(); i++)
		printf("%d ", m_StatstrV[i]);


	//Print the structural
	std::map<std::string, unsigned>::iterator iFP;
	printf("\nFingerprint:\n");
	for(iFP = m_Fingerprint.begin(); iFP != m_Fingerprint.end(); iFP++)
		printf("TYPE: %s\tVAL: %u\n", iFP->first.c_str(), iFP->second);

	printf("\nK-GRAM List:\n");
	std::map<std::string, int>::iterator iMap;
	for(iMap = m_kgramlist.begin(); iMap != m_kgramlist.end(); iMap++)
		printf("%10s  %d\n", iMap->first.c_str(), iMap->second);

	printf("\nK-GRAM Set:\n");
	for(iMap = m_kgramset.begin(); iMap != m_kgramset.end(); iMap++)
		printf("%10s  %d\n", iMap->first.c_str(), iMap->second);

	printf("\nK-GRAM Counter:\n");
	for(unsigned i = 0; i < m_kgramcount.size(); i++){
		for(iMap = m_kgramcount[i].begin(); iMap != m_kgramcount[i].end(); iMap++)
			printf("%s:%d ", iMap->first.c_str(), iMap->second);
		printf("\n");
	}

	printf("---------------------------------------------------------------\n"); 
}










Birthmark* extractBirthmark(std::string file, std::string kval, bool predictFlag,  bool  strictFlag, Optmode optFlag){
	//Get extension
	int lastDotIndex= file.find_last_of(".");
	std::string ext = file.substr(lastDotIndex+1, file.length()-lastDotIndex);


	//Optimization flag
	//Defined in scripts/yosys.py:24
	std::string optCmd = "";
	if(optFlag == eOpt)  optCmd= " -O 3";
	else if(optFlag == eOpt_No_Clean)  optCmd = " -O 2";
	else if(optFlag == eNoOpt_Clean)  optCmd = " -O 1";

	std::string predictCmd = "";
	if(predictFlag) predictCmd = " -p";
	
	std::string strictCmd = "";
	if(strictFlag) strictCmd = " -s";

	std::string cmd = "";
	struct stat statbuf;

	//Check for verilog extension or folder
	if(ext == "v"){
		//Extract the birthmark from the verilog
		printf(" -- Reading Reference Verilog Design\n");
		cmd = "python scripts/process_verilog.py " + file + " " + kval + " " +  optCmd + " " + predictCmd + " " + strictCmd; 
	}
	else if(stat(file.c_str(), &statbuf) != -1){
		if(S_ISDIR(statbuf.st_mode))
			cmd = "python scripts/process_verilog.py " + file + " " + kval + " " + optCmd + " " + predictCmd + " " + strictCmd; 
	}
	else throw cException("(extractBirthmark:T1) Unknown Extension: " + ext);

	//Run the command
	int status = system(cmd.c_str());

	//Read in the XML file
	std::string xmlREF = "data/reference.xml";
	std::string xmldata= "";
	std::string xmlline;
	std::ifstream refStream;
	refStream.open(xmlREF.c_str());
	if (!refStream.is_open()) throw cException("(extractBirthmark:T2) Cannot open file: " + xmlREF);

	while(getline(refStream, xmlline))
		xmldata+= xmlline + "\n";

	xml_document<> xmldoc;
	char* cstr = new char[xmldata.size() + 1];
	strcpy(cstr, xmldata.c_str());

	//Parse the XML Data
	printf("[*] -- Generating Reference Birthmark\n");
	xmldoc.parse<0>(cstr);
	xml_node<>* cktNode= xmldoc.first_node();
	Birthmark* birthmark = new Birthmark();
	birthmark->importXML(cktNode);
	delete cstr;

	return birthmark;
}
