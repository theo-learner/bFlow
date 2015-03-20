/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  error.hpp
	@      
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#ifndef ERROR_GUARD
#define ERROR_GUARD

//System Includes
#include <stdlib.h>
#include <stdio.h>
#include <exception>

class Exception: public std::exception{
	public:
		Exception(
				std::string m="Exception!!") : 
			msg("\n\n[ERROR] - " + m + "\n") {}
		~Exception() throw() {}
		const char* what() const throw() { 
			return msg.c_str(); 
		}

	private:
		std::string msg;
};
#endif



