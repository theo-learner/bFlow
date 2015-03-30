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
}
		
/**
 * Constructor
 *  Loads birthmark from XML 
 */
Birthmark::Birthmark(xml_node<>* cktNode){
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
		if(cktNodeName!= "CIRCUIT") throw cException("(Birthmark::importXML:T1) Tag not found") ;

		std::string cktName = "===";  
		int id = -2;

		//Get the name and ID of the circuit (Variable Order) 
		xml_attribute<>* cktAttr = cktNode->first_attribute();
		if(cktAttr == NULL) throw cException("(Birthmark::importXML:T2) No Attributes found") ;
		std::string cktAttrName = cktAttr->name();
		if(cktAttrName == "name") cktName = cktAttr->value(); 
		else if(cktAttrName == "id") id = s2i::string2int(cktAttr->value()); 
		else throw cException("(Birthmark::importXML:T3) Unexpected Attribute Tag Found") ;

		cktAttr = cktAttr->next_attribute();
		if(cktAttr == NULL) throw cException("(Birthmark::importXML:T4) No Attributes found") ;
		cktAttrName = cktAttr->name();
		if(cktAttrName == "name") cktName = cktAttr->value(); 
		else if(cktAttrName == "id") id = s2i::string2int(cktAttr->value()); 
		else throw cException("(Birthmark::importXML:T5) Unexpected Attribute Tag Found") ;

		if(id < -1 || cktName == "===") throw cException("(Birthmark::importXML:T6) Attribute Error") ;

		//Set the ID and Name of the circuit
		setID(id);
		setName(cktName);

		std::map<unsigned, unsigned> fingerprint;
		std::list<std::string> maxseq;
		std::list<std::string> minseq;
		std::set<int> constants;

		//Read in data of the XML File
		xml_node<>* featureNode = cktNode->first_node();
		while (featureNode!= NULL){
			std::string featureNodeName = featureNode->name();
			if(featureNodeName == "MAXSEQ")
				addMaxSequence(featureNode->value());
			else if(featureNodeName == "MINSEQ")
				addMinSequence(featureNode->value());
			else if(featureNodeName == "ALPHASEQ")
				addAlphaSequence(featureNode->value());
			else if(featureNodeName == "CONSTANT")
				addConstant(s2i::string2int(featureNode->value()));
			else if(featureNodeName == "STAT")
				setStatstr(featureNode->value());
			else if(featureNodeName == "FP"){

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
			else throw cException("(Birthmark::importXML:T12) Unknown tag found in XML: " + featureNodeName);


			featureNode= featureNode->next_sibling(); 
		}

	return true;
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
 * getName
 *  Returns circuit name 
 */
std::string Birthmark::getName(){
	return m_Name;
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
void Birthmark::addConstant(int constant){
	m_Constants.insert(constant);
}

/**
 * addFingerprint
 *  Adds a feature into the fingerprint 
 */
void Birthmark::addFingerprint(std::string featureName, unsigned feature){
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
	std::set<int>::iterator iSet;
	printf("Constants: ");	
	for(iSet = m_Constants.begin(); iSet != m_Constants.end(); iSet++)
		printf("%d ", *iSet);
	
	//Print the structural
	std::map<std::string, unsigned>::iterator iFP;
	printf("\nFingerprint:\n");
	for(iFP = m_Fingerprint.begin(); iFP != m_Fingerprint.end(); iFP++){
		printf("TYPE: %s\tVAL: %u\n", iFP->first.c_str(), iFP->second);

		printf("\n");
	}
	printf("---------------------------------------------------------------\n"); 
}





