/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  feature.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#ifndef FEATURE_GUARD
#define FEATURE_GUARD

#include <stdlib.h> 
#include <stdio.h>
#include <string>
#include <vector>
#include <list>
#include <map>
#include <set>
#include <assert.h>

class Feature{
	private: 
		std::map<unsigned, unsigned> m_SizeCount;

	public:
		Feature();
		Feature(std::vector<unsigned>&, std::vector<unsigned>&);
		Feature(unsigned, unsigned);                     //PARAM: Size, Count

		void getFeature(std::map<unsigned, unsigned>&);
		unsigned getCount(unsigned);                     //PARAM: Size
		
		void setFeatures(std::map<unsigned, unsigned>&);
		
		void addEntry(unsigned, unsigned);               //PARAM: Size, Count

		void print();

	
};
#endif
