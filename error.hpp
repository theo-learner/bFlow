#ifndef ERROR_GUARD
#define ERROR_GUARD


//System Includes
#include <stdlib.h>
#include <stdio.h>
#include <exception>

class ServerException: public std::exception
{
public:
 	ServerException(
		std::string m="Exception occured in server\n") : 
					msg("\n\n[ERROR] -- " + m + "\n") {}
  	~ServerException() throw() {}
  	const char* what() const throw() { 
		return msg.c_str(); 
	}

private:
  std::string msg;
};
#endif



