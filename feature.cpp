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

	m_Sizes= size;
	m_Counts= count;
}

Feature::Feature(unsigned size, unsigned count){

	assert(size != 0);

	m_Sizes.push_back(size);
	m_Counts.push_back(count);
}






void Feature::getSizes(std::vector<unsigned>& rVal){
	rVal = m_Sizes;
}

void Feature::getCounts(std::vector<unsigned>& rVal){
	rVal = m_Counts;
}


unsigned Feature::getSize(unsigned index){
	return m_Sizes[index];
}
unsigned Feature::getCount(unsigned index){
	return m_Counts[index];
}
		

void Feature::setSizes(std::vector<unsigned>& val){
	m_Sizes = val;
}

void Feature::setCounts(std::vector<unsigned>& val){
	m_Counts = val;

}
		

void Feature::addEntry(unsigned size, unsigned count){
	m_Sizes.push_back(size);
	m_Counts.push_back(count);
}



/*void setNames(std::string name){
	m_FeatureName = name;
}
std::string getName(){
	rVal = m_FeatureName;
}
*/
