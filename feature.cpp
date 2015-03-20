/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  feature.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "feature.hpp"


/**
 * Constructor
 *  Default Constructor
 */
Feature::Feature(){
}

/**
 * Constructor
 *  Loads data into feature
 */
Feature::Feature(std::vector<unsigned>& size, std::vector<unsigned>& count){
	//Make sure every size has a count
	assert(count.size() == size.size());       

	for(unsigned int i = 0; i < size.size(); i++)
		m_SizeCount[size[i]] = count[i];
}

/**
 * Constructor
 *  Loads a single point into feature
 */
Feature::Feature(unsigned size, unsigned count){
	assert(size != 0);          //No component has a size of 0
	m_SizeCount[size] = count;
}










/**
 * getFeature 
 *  Returns the feature 
 */
void Feature::getFeature(std::map<unsigned, unsigned>& rVal){
	rVal = m_SizeCount;
}

/**
 * getCount
 *  Returns count of the feature of a specific size 
 */
unsigned Feature::getCount(unsigned size){
	return m_SizeCount[size];
}










/**
 * setFeatures
 *  Sets the data of feature 
 */
void Feature::setFeatures(std::map<unsigned, unsigned>& val){
	m_SizeCount = val;
}

/**
 * addEntry 
 *  Adds a size count pair into the feature
 */
void Feature::addEntry(unsigned size, unsigned count){
	m_SizeCount[size] = count;
}










/**
 * print 
 *  Prints a contents of feature 
 */
void Feature::print(){
	std::map<unsigned, unsigned>::iterator it;
	for(it = m_SizeCount.begin(); it != m_SizeCount.end(); it++)
		printf("%d : %d   ", it->first, it->second);
}





