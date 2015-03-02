/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  birthmark.cpp
	@  @  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "birthmark.hpp"
using namespace rapidxml;

	
Birthmark::Birthmark(){
}
		
Birthmark::Birthmark(xml_node<>* cktNode){
	importXML(cktNode);
}
		
bool Birthmark::importXML(xml_node<>* cktNode){
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
		std::string cktNodeName = cktNode->name();
		if(cktNodeName!= "CIRCUIT") throw eCIRCUIT_FE;

		std::string cktName = "===";  
		int id = -2;

		//Get the name and ID of the circuit 
		xml_attribute<>* cktAttr = cktNode->first_attribute();
		if(cktAttr == NULL) throw eNoAttr;

		std::string cktAttrName = cktAttr->name();
		if(cktAttrName == "name") cktName = cktAttr->value(); 
		else if(cktAttrName == "id") id = s2i::string2int(cktAttr->value()); 
		else throw eCIRCUIT_ATTR_FE ;

		cktAttr = cktAttr->next_attribute();
		if(cktAttr == NULL) throw eNoAttr;
			
		cktAttrName = cktAttr->name();
		if(cktAttrName == "name") cktName = cktAttr->value(); 
		else if(cktAttrName == "id") id = s2i::string2int(cktAttr->value()); 
		else throw eCIRCUIT_ATTR_FE ;

		if(id < -1 || cktName == "===") throw eCIRCUIT_ATTR_FE;

		setID(id);
		setName(cktName);
		printf("CKTNAME: %s\n", cktName.c_str());

		std::map<unsigned, unsigned> fingerprint;
		std::list<std::string> maxseq;
		std::list<std::string> minseq;
		std::set<int> constants;

		//Look through the fingerprint of each circuit
		xml_node<>* featureNode = cktNode->first_node();
		while (featureNode!= NULL){
			std::string featureNodeName = featureNode->name();
			if(featureNodeName == "MAXSEQ")
				addMaxSequence(featureNode->value());
			else if(featureNodeName == "MINSEQ")
				addMinSequence(featureNode->value());
			else if(featureNodeName == "CONSTANT")
				addConstant(s2i::string2int(featureNode->value()));
			else if(featureNodeName == "FP"){

				//Get the name and ID of the circuit 
				xml_attribute<>* fpAttr = featureNode->first_attribute();
				if(fpAttr == NULL) throw eNoAttr;

				std::string fAttrName= fpAttr->name();
				std::string featureName;
				if(fAttrName == "type") featureName = fpAttr->value(); 

				//########################################################
				xml_node<>* attrNode =  featureNode->first_node();

				//Store the attribute of each fingerprint 
				while (attrNode!= NULL){
					int size = -2;
					int count = -2;

					xml_attribute<>* attrAttr = attrNode->first_attribute();
					if(attrAttr == NULL) throw eNoAttr;

					std::string attrAttrName = attrAttr->name();
					if(attrAttrName == "size") size = s2i::string2int(attrAttr->value());
					else if(attrAttrName == "count") count= s2i::string2int(attrAttr->value());
					else throw eFeature_FE;

					attrAttr = attrAttr->next_attribute();
					if(attrAttr == NULL) throw eNoAttr;

					attrAttrName = attrAttr->name();
					if(attrAttrName == "size") size = s2i::string2int(attrAttr->value());
					else if(attrAttrName == "count") count = s2i::string2int(attrAttr->value());
					else throw eFeature_FE;

					if(size == -2 || count == -2) throw eSC_FE;

					//Store the attribute into the fingerprint;
					addFingerprint(featureName, size, count);
					attrNode = attrNode->next_sibling();
				}
				//########################################################

			}

			featureNode= featureNode->next_sibling(); 
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

	return true;

}

Birthmark::~Birthmark(){
	std::map<std::string, Feature*>::iterator it;
	for(it = m_Fingerprint.begin(); it != m_Fingerprint.end(); it++)
		delete it->second;

}

//GETTERS
void Birthmark::getMaxSequence(std::list<std::string>& rVal){
	rVal = m_MaxSequence;
}

void Birthmark::getMinSequence(std::list<std::string>& rVal){
	rVal = m_MinSequence;
}

void Birthmark::getConstants(std::set<int>& rVal){
	rVal = m_Constants;
}

void Birthmark::getFingerprint(std::map<std::string, Feature*>& rVal){
	rVal = m_Fingerprint;
}

std::string Birthmark::getName(){
	return m_Name;
}

int Birthmark::getID(){
	return m_ID;
}





//SETTERS
void Birthmark::setMaxSequence(std::list<std::string>& val){
	m_MaxSequence = val;
}

void Birthmark::setMinSequence(std::list<std::string>& val){
	m_MinSequence = val;
}

void Birthmark::setConstants(std::set<int>& val){
	m_Constants = val;
}

void Birthmark::setFingerprint(std::map<std::string , Feature* >& val){
	m_Fingerprint = val;
}

void Birthmark::setName(std::string name){
	m_Name = name;
}

void Birthmark::setID(int id){
	m_ID = id;
}





//ADD
void Birthmark::addMaxSequence(std::string seq){
	m_MaxSequence.push_back(seq);
}

void Birthmark::addMinSequence(std::string seq){
	m_MinSequence.push_back(seq);
}

void Birthmark::addConstant(int constant){
	m_Constants.insert(constant);
}

void Birthmark::addFingerprint(std::string featureName, Feature* feature){
	m_Fingerprint[featureName] = feature;
}

void Birthmark::addFingerprint(std::string featureName, unsigned size, unsigned count){
	std::map<std::string, Feature*>::iterator it;
	it = m_Fingerprint.find(featureName);
	if(it == m_Fingerprint.end()){
		Feature* feature = new Feature(size, count);
		m_Fingerprint[featureName] = feature;	
	}
	else
		it->second->addEntry(size, count);
}

void Birthmark::print(){
	printf("---------------------------------------------------------------\n"); 
	printf(" Birthmark: CKT: %s ID: %d\n", m_Name.c_str(), m_ID);
	printf("---------------------------------------------------------------\n"); 

	std::list<std::string>::iterator it;
	for(it = m_MaxSequence.begin(); it != m_MaxSequence.end(); it++)
		printf("Max Sequence: %s\n", it->c_str());
	
	for(it = m_MinSequence.begin(); it != m_MinSequence.end(); it++)
		printf("Min Sequence: %s\n", it->c_str());
	
	
	
	std::set<int>::iterator iSet;
	printf("Constants: ");	
	for(iSet = m_Constants.begin(); iSet != m_Constants.end(); iSet++)
		printf("%d ", *iSet);
	
	
	
	std::map<std::string, Feature*>::iterator iFP;
	printf("\nFingerprint:\n");
	for(iFP = m_Fingerprint.begin(); iFP != m_Fingerprint.end(); iFP++){
		printf("TYPE: %s\t", iFP->first.c_str());
		iFP->second->print(); 
		printf("\n");
	}
	printf("---------------------------------------------------------------\n"); 

}
