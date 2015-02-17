/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@  server.hpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2013 
	@  Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/


#ifndef SERVER_GUARD
#define SERVER_GUARD

#include <stdlib.h> 
#include <stdio.h>
#include <string>
#include <cstring>
#include <sys/time.h>
#include <sys/stat.h>
#include <unistd.h>

//Socket TCP/IP Includes
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>

#include <sys/types.h>
#include <ifaddrs.h>
#include <netinet/in.h> 
#include <string.h> 
#include <arpa/inet.h>

#include "error.hpp"



class Server{
	private: 
		unsigned m_Port;
		unsigned m_bufferLength;

		int m_ServerSktID;
		int m_ClientSktID;
		

	public:
		//port number
		Server(unsigned);
		
		bool waitForClient();
		std::string receiveAllData();
		bool sendData(std::string);
		void closeSocket();

		void print();
};




#endif
