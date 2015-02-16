/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  birthmark.cpp
	@  @  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "birthmark.hpp"

	
Birthmark::Birthmark(){
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

}
