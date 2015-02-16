#ifndef ERROR_GUARD
#define ERROR_GUARD


//System Includes
#include <stdlib.h>
#include <stdio.h>
#include <exception>

class ServerSendException: public std::exception
{
public:
 	ServerSendException(
		std::string m="[ERROR] -- Exception occured when trying to send data over s        erver\n") : msg(m) {}
  	~ServerSendException() throw() {}
  	const char* what() const throw() { 
		return msg.c_str(); 
	}

private:
  std::string msg;
};
#endif



