/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  server.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "server.hpp"

/**
 * Constructor 
 *  Default constructor takes a port number
 */
Server::Server(unsigned port){
	m_Port = port;
	m_bufferLength = 1024;
	m_ServerSktID = -1;
	m_ClientSktID = -1;
}










/**
 * waitForClient 
 *  Function should be called first!
 *  Waits for a client to connect and connects with it
 */
bool Server::waitForClient(){
	closeSocket();
	printf("[SERVER] -- Preparing TCP/IP connection with client front-end\n");
	printf("[SERVER] -- Opening Socket...");
	m_ServerSktID = socket(AF_INET, SOCK_STREAM, 0);
	if(m_ServerSktID< 0)
		throw Exception("(Server::waitForClient:T1) Server socket cannot be opened");

	printf("ID: %d\n", m_ServerSktID);

	printf("[SERVER] -- Preparing to bind...\n");
	socklen_t clientLength;
	struct sockaddr_in server_addr, client_addr;
	bzero((char *) &server_addr, sizeof(server_addr));
	server_addr.sin_family = AF_INET;                   //Address format is host and port number
	server_addr.sin_addr.s_addr = INADDR_ANY;
	server_addr.sin_port= htons(m_Port);

	if (bind(m_ServerSktID, (struct sockaddr *) &server_addr, 
				sizeof(server_addr)) < 0)
		throw Exception("(Server::waitForClient:T2) Binding error");

	print();

	printf("[SERVER] -- Listening for clients...\n");
	listen(m_ServerSktID, 5);

	clientLength = sizeof(client_addr);
	m_ClientSktID= accept(m_ServerSktID, (struct sockaddr*) &client_addr, &clientLength);
	if(m_ClientSktID< 0) throw Exception("(Server::waitForClient:T3) Error accepting client");

	printf(" * Client found!\n");

	return true;
}

/**
 * waitForClient 
 *  Receive data in multiple chunks by checking a non-blocking socket
 *  Times out when no more data is sent
 */
std::string Server::receiveAllData(){
	if(m_ClientSktID < 0) 
		throw Exception("(Server::recvAllData:T1) ClientID is not set");

	int size_recv , total_size= 0;
	struct timeval begin , now;
	char buffer[m_bufferLength];
	double timediff;
	double timeout = 0.5;
	std::string data = "";


	//Blocking Receive to wait for the first data sent by the client
	printf("[SERVER] -- Waiting for data from client...\n");
	bzero(buffer, m_bufferLength);
	if((size_recv = recv(m_ClientSktID, buffer, m_bufferLength-1, 0) ) <= 0)
		throw Exception("(Server::recvAllData:T2) Failed to recv msg. Client might have disconnected");

	buffer[m_bufferLength] = '\0';
	data += buffer ;
	
	//make socket non blocking
	int option = fcntl(m_ClientSktID, F_GETFL);
	option = option | O_NONBLOCK;
	fcntl(m_ClientSktID, F_SETFL, option);


	//beginning time
	gettimeofday(&begin , NULL);
	//printf("[SERVER] -- Initial packet received. Retrieving all data\n");

	while(1){
		gettimeofday(&now , NULL);
		//printf("TIME: %f\n", timediff);

		//time elapsed in seconds
		timediff = (now.tv_sec - begin.tv_sec) + 1e-6 * (now.tv_usec - begin.tv_usec);

		//if you got some data, then break after timeout
		if( timediff > timeout )
			break;

		bzero(buffer, m_bufferLength);
		if((size_recv =  recv(m_ClientSktID, buffer, m_bufferLength-1, 0) ) < 0){
			usleep(5000);
		}
		else if(size_recv != 0){
			total_size += size_recv;
			buffer[m_bufferLength] = '\0';
			data += buffer ;

			//reset beginning time
			gettimeofday(&begin , NULL);
		}
		else
			usleep(5000);
	}
	printf("[SERVER] -- Data received from client\n");
	
	//Set it so that receive is blocking
	option = option & ~O_NONBLOCK;
	fcntl(m_ClientSktID, F_SETFL, option);

	return data;
}	


/**
 * sendData 
 *  Sends data to the client 
 */
bool Server::sendData(std::string data){
	if(m_ClientSktID < 0){
		throw Exception("(Server::sendData:T1) ClientID is not set");
	}

	int result = write(m_ClientSktID, data.c_str(), data.length());	

	if(result < 0){
		throw Exception("(Server::sendData:T2) Failed to send message");
	}

	return true;
}

/**
 * closeSocket 
 *  Closes the socket connection to the client
 */
void Server::closeSocket(){
	if(m_ServerSktID < 0){
		return;
	}

	printf("[SERVER] -- Closing socket...\n");
	close(m_ServerSktID);
	close(m_ClientSktID);
	m_ServerSktID = -1;
	m_ClientSktID = -1;
}











/**
 * print 
 *  Prints the server information such as IP, network interfaces 
 *  and port number. Used for easy connection for client
 */
void Server::print(){
	printf("[SERVER] -- Server Information\n");
	struct ifaddrs* ifAddrStruct=NULL;
	struct ifaddrs* ifa=NULL;
	void* tmpAddrPtr=NULL;

	getifaddrs(&ifAddrStruct);

	for (ifa = ifAddrStruct; ifa != NULL; ifa = ifa->ifa_next) {
		if (!ifa->ifa_addr) continue;

		if (ifa->ifa_addr->sa_family == AF_INET) { // check it is IP4
			// is a valid IP4 Address
			tmpAddrPtr=&((struct sockaddr_in *)ifa->ifa_addr)->sin_addr;
			char addressBuffer[INET_ADDRSTRLEN];
			inet_ntop(AF_INET, tmpAddrPtr, addressBuffer, INET_ADDRSTRLEN);
			printf(" * [IPV4] DEV: %-7s\tIP: %s\n", ifa->ifa_name, addressBuffer); 
		} 
		
		else if (ifa->ifa_addr->sa_family == AF_INET6) { // check it is IP6
			// is a valid IP6 Address
			tmpAddrPtr=&((struct sockaddr_in6 *)ifa->ifa_addr)->sin6_addr;
			char addressBuffer[INET6_ADDRSTRLEN];
			inet_ntop(AF_INET6, tmpAddrPtr, addressBuffer, INET6_ADDRSTRLEN);
			printf(" * [IPV6] DEV: %-7s\tIP: %s\n", ifa->ifa_name, addressBuffer); 
		} 
	}

	printf(" * [PORT] : %d\n\n", m_Port);

	if (ifAddrStruct!=NULL) freeifaddrs(ifAddrStruct);
}





