/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  feature.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
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
		//std::string m_FeatureName;
		std::vector<unsigned> m_Sizes;
		std::vector<unsigned> m_Counts;

	public:
		Feature();
		Feature(std::vector<unsigned>&, std::vector<unsigned>&);
		Feature(unsigned, unsigned);

		void getSizes(std::vector<unsigned>&);
		void getCounts(std::vector<unsigned>&);

		unsigned getSize(unsigned);
		unsigned getCount(unsigned);
		
		void setSizes(std::vector<unsigned>&);
		void setCounts(std::vector<unsigned>&);
		
		void addEntry(unsigned, unsigned); //PARAM: size, count

		//std::string getName(unsigned);
		//void setName(std::string);
		void print();

	
};
#endif
