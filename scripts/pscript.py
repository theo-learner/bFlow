#!/usr/bin/python2.7

import networkx as nx;
import sys, traceback;
import re;
import copy;
import dataflow as dfx;



def removeComponent(node):
	#Get neighbors
	succList = dfg.successors(node);
	predList = dfg.predecessors(node);

	#Make sure it is not a multiInput point
	if len(predList) > 1:
		#print "Traceback Error:  Multiinput point!!!!!";
		#print "NODE: " + node;
		#print "predList: ";
		#print predList;
		#sys.exit(1);
		return;
	if len(succList) < 1:
		return;

	#Get the size of the bus

	size = edgeAttr[(node, succList[0])];

	#Remove the node and passthrough the input
	dfg.remove_node(node);
	for dest in succList:
		dfg.add_edge(predList[0], dest, label=size);
		edgeAttr[(predList[0], dest)] = size





################################################################################
#
# START OF PYTHON PROGRAM
#
################################################################################
try:
	# Read in dot file of the dataflow
	fileName = sys.argv[1];
	result = dfx.extractDataflow(fileName);

	#Store the max seq
	maxList = result[0];
	sequence = repr(len(maxList));
	for seq in maxList:
		sequence = sequence + "\n" + seq;
	
	minList = result[1];
	sequence = sequence + "\n" +  repr(len(minList));
	for seq in minList:
		sequence = sequence + "\n" + seq;
	print sequence
		
	#Output Sequence extracted 
	fileStream = open("data/seq.dat", 'w');
	fileStream.write(sequence);
	fileStream.close();


	constSet= result[2];
	fileStream = open("data/const.dat", 'w');
	fileStream.write(repr(len(constSet)));
	for const in constSet:
		fileStream.write("\n" + const);
	fileStream.close();

	
	#constStr = constStr[:-1];
	#fileStream = open(".const2", 'w');
	#if(len(constStr)> 0):
	#	constStr = constStr.replace(",0", ",-1");
	#	if(constStr[0] == '0'):
	#		constStr = '-1' + constStr[1:];

	#fileStream.write(constStr);
	#fileStream.close();
	
	
	fpDict= result[3];
	name = result[4];
	if(len(fpDict) != len(name)):
		raise;

	fileStream = open("data/component.dat", 'w');
	compstr = "";
	compstr = compstr + repr(len(fpDict));

	for fp in fpDict:
		compstr = compstr + "\n" + repr(len(fp));
		for k, v in fp.iteritems():
			compstr = compstr + " " + repr(k) + " " + repr(v) + "   ";
	fileStream.write(compstr);
	fileStream.close();
	
	statstr= result[5];
	fileStream = open("data/stat.dat", 'w');
	fileStream.write(statstr);
	fileStream.close();






except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);




