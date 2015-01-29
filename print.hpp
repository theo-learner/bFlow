
#ifndef PRINT_GUARD 
#define PRINT_GUARD

#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <map>
#include <vector>
#include <set>
#include <list>



void cprint(std::map<unsigned, unsigned>& str);
void cprint(std::vector<std::map<unsigned, unsigned> >& );
void cprint(std::set<std::string>& str);


#endif
