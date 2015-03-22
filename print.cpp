/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  print.cpp
	@    Printing functions 
  @	
  @  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "print.hpp"

void cprint(std::vector<std::map<unsigned, unsigned> >& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}

	std::map<unsigned, unsigned>::iterator it;
	for(unsigned int i = 0; i < str.size(); i++){
		if(str[i].size() == 0)	printf("EMPTY");
		for(it = str[i].begin(); it != str[i].end(); it++)
			printf("%d:%d ", it->first, it->second);
		printf("\n");
	}
	printf("\n");
}

void cprint(std::vector<double >& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}
	
	for(unsigned int i = 0; i < str.size(); i++)
		printf("%f ", str[i]);
	printf("\n");
}

void cprint(std::vector<std::vector<int> >& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}
	
	for(unsigned int i = 0; i < str.size(); i++){
		for(unsigned int q = 0; q < str[i].size(); q++)
			printf("%d ", str[i][q]);
		printf("\n");
	}
	printf("\n");
}

void cprint(std::map<unsigned, unsigned>& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}
	
	std::map<unsigned, unsigned>::iterator it;
	for(it = str.begin(); it != str.end(); it++)
		printf("%d:%d ", it->first, it->second);
	printf("\n");
}

void cprint(std::set<std::string>& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}

	std::set<std::string>::iterator iSet;
	for(iSet = str.begin(); iSet != str.end(); iSet++)
		printf("%s ", iSet->c_str());
	printf("\n");
}

void cprint(std::set<int>& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}

	std::set<int>::iterator iSet;
	for(iSet = str.begin(); iSet != str.end(); iSet++)
		printf("%d ", *iSet);
	printf("\n");
}


void cprint(std::map<char, std::map<char, double> >& str){
	if(str.size() == 0) {
		printf("EMPTY\n");
		return;
	}

	std::map<char, std::map<char, double> >::iterator iMap;
	std::map<char, double>::iterator iMap2;
	printf("          ");
	for(iMap = str.begin(); iMap != str.end(); iMap++)
		printf("%10c", iMap->first);
	
	for(iMap = str.begin(); iMap != str.end(); iMap++){
		printf("\n%10c", iMap->first);
		for(iMap2 = iMap->second.begin(); iMap2 != iMap->second.end(); iMap2++)
			printf("%10.2f", iMap2->second);
	}
	printf("\n");
}
