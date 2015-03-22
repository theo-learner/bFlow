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

/**
 * Exception 
 *  Generic exception handler for all exception 
 */
class Exception: public std::exception{
	public:
		Exception(
				std::string m="Exception!!") : 
			msg("\n[ERROR] - " + m + "\n\n") {}
		~Exception() throw() {}
		const char* what() const throw() { 
			return msg.c_str(); 
		}

	private:
		std::string msg;
};

/**
 * ArgException 
 *  Exception Handler for Argument mismatches 
 */
class ArgException: public std::exception{
	public:
		ArgException(
				std::string m="Arguments do not match!!") : 
			msg("\n[ERROR] - " + m + "\n") {}
		~ArgException() throw() {}
		const char* what() const throw() { 
			return msg.c_str(); 
		}

	private:
		std::string msg;
};
#endif



