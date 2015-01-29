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
