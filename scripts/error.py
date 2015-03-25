#!/usr/bin/python2.7

'''
	Error Module: 
		Error and exception Handling	
'''

class Error(Exception):
	"""Base class for exceptions in this module"""
	pass

class YosysError(Error):
	def __init__(self, msg):
		self.msg = msg;

class SizeError(Error):
	def __init__(self, msg):
		self.msg = msg;

class ArgError(Error):
	def __init__(self):
		pass

class GenError(Error):
	def __init__(self, msg):
		self.msg = msg;
