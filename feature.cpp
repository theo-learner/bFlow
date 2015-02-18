/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  feature.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "feature.hpp"


Feature::Feature(){
}

Feature::Feature(std::vector<unsigned>& size, std::vector<unsigned>& count){
	assert(count.size() == size.size());

	//m_Sizes= size;
	//m_Counts= count;

	for(unsigned int i = 0; i < size.size(); i++)
		m_SizeCount[size[i]] = count[i];

}

Feature::Feature(unsigned size, unsigned count){

	assert(size != 0);

	m_SizeCount[size] = count;

	//m_Sizes.push_back(size);
	//m_Counts.push_back(count);
}





/*
void Feature::getSizes(std::vector<unsigned>& rVal){
	rVal = m_Sizes;
}

void Feature::getCounts(std::vector<unsigned>& rVal){
	rVal = m_Counts;
}

unsigned Feature::getSize(unsigned index){
	return m_Sizes[index];
}
void Feature::setSizes(std::vector<unsigned>& val){
	m_Sizes = val;
}

void Feature::setCounts(std::vector<unsigned>& val){
	m_Counts = val;
}
*/
	
void Feature::getFeature(std::map<unsigned, unsigned>& rVal){
	rVal = m_SizeCount;
}

unsigned Feature::getCount(unsigned index){
	//return m_Counts[index];
	return m_SizeCount[index];
}
		
void Feature::setFeatures(std::map<unsigned, unsigned>& val){
	m_SizeCount = val;
}

		

void Feature::addEntry(unsigned size, unsigned count){
	//m_Sizes.push_back(size);
	//m_Counts.push_back(count);
	m_SizeCount[size] = count;
}



void Feature::print(){
//	for(unsigned int i = 0; i < m_Sizes.size(); i++)
//		printf("%d : %d   ", m_Sizes[i], m_Counts[i]);

	std::map<unsigned, unsigned>::iterator it;
	for(it = m_SizeCount.begin(); it != m_SizeCount.end(); it++)
		printf("%d : %d   ", it->first, it->second);
}

/*void setNames(std::string name){
	m_FeatureName = name;
}
std::string getName(){
	rVal = m_FeatureName;
}
*/
