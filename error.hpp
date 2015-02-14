#ifndef ERROR_GUARD
#define ERROR_GUARD


//System Includes
#include <stdlib.h>
#include <stdio.h>

class ServerSendException : public Exception{
	const char* what() const throw(){
		return "[ERROR] -- Exception occured when trying to send data to client\n"; 
	}
}

#endif
