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
	m_Count= count;
}

Feature::Feature(unsigned size, unsigned count){

	assert(size.size() != 0);

	m_Sizes= size;
	m_Count= count;
}






void getSizes(std::vector<unsigned>& rVal){
	rVal = m_Sizes;
}

void getCounts(std::vector<unsigned>& rVal){
	rVal = m_Counts;
}


unsigned getSize(unsigned index){
	return m_Sizes[index];
}
unsigned getCount(unsigned index){
	return m_Counts[index];
}
		

void setSizes(std::vector<unsigned>& val){
	m_Sizes = val:
}

void setCounts(std::vector<unsigned>& val){
	m_Count = val:

}
		

void addEntry(unsigned size, unsigned count, unsigned index){
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
