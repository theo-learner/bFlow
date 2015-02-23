#!/usr/bin/python2.7

import networkx as nx;
import sys, traceback;
import re;
import copy;
import dataflow as dfx;


def findAddTree(node):
	global atIndex;
	global dfg;

	#print "FINDING ADD TREE UNDER NODE: " + node;
	label = labelAttr[node];

	if '$add' in label:
		predList = dfg.predecessors(node);

		for pred in predList:
			#Get the predecessor if it is a spliced 
			pred2 = pred;

			if 'x' in pred:
				pred2 = dfg.predecessors(pred);
				pred2 = pred2[0];

			if '$add' in labelAttr[pred2]:
				#print node + " " + pred2 + " combines to make an add tree";
				#Combine the two nodes to an addTree node
				name = "at" + repr(atIndex);
				atIndex = atIndex + 1;
				dfg.add_node(name, label="$addTree");
				labelAttr[name] = "$addTree";
				shapeAttr[name] = "record";

				#Get the neighbors
				succList = dfg.successors(node);
				ppredList = dfg.predecessors(pred2);
				predList.remove(pred2);
				predList.extend(ppredList);
				#print succList;
				#print predList;
			
				#Get the size of the "adder"
				osize = edgeAttr[(node, succList[0])];
				maxLength = 0;
				for predt in predList:
					if(predt, node) in edgeAttr:
						size = edgeAttr[(predt, node)];
						if size > maxLength: 
							maxLength = size;

				size = max(maxLength, osize);

				#Remove nodes;
				#print "DELETING NODE: " + repr(node) + " " + repr(pred);
				dfg.remove_node(node);
				dfg.remove_node(pred2);

				#Connect the tree block into the circuit
				for src in predList:
					dfg.add_edge(src, name, label=size);
					edgeAttr[(src, name)] = size
				
				for dest in succList:
					dfg.add_edge(name, dest, label=size);
					edgeAttr[(name, dest)] = size

				#Recurse
				findAddTree(name);
				break;

	
	
	###############################################################################
	# Extract the dataflow object names with bus sizes
	###############################################################################
def extractDF(dataflowList_node):
	dataflowList = [];
	for dataflow_node in dataflowList_node:
		dataflow = [];
		#print "CHECKING DATAFLOW";
		#print dataflow_node;
		#for index in xrange(len(dataflow_node)-2):
		#	print labelAttr[dataflow_node[index]];

		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
			#print "CHECKING NODE: " + node;
			
			#	Make sure it isn't a port/point node
			if 'n' in node:
				continue;
			elif shapeAttr[node] == "point":         # Check to see if it is a point node
				continue;
			elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
				continue;

			operation = labelAttr[node];

			if 'x' in node: 									 #Check to see if the node is a splice
				operation = "NETSPLICE";

			elif '$add' in operation:             #Check to see if the operation is a add
				#osize = edgeAttr[(node, dataflow_node[index+2])];
				osize = edgeAttr[(dataflow_node[index+2], node)];
				operation = operation + repr(osize);

				if 'Tree' in operation:
					predList = dfg.predecessors(node);
					operation = operation + "_" + repr(len(predList));

			elif '$mul' in operation: 
				insize = [];
				predList = dfg.predecessors(node);
				for pred in predList:
					osize = edgeAttr[(pred, node)];
					insize.append(osize);

				operation = operation + insize[0] + "x" + insize[1];
			elif '$eq' == operation:	
				predList = dfg.predecessors(node);
				osize = edgeAttr[(predList[0], node)];
				operation = operation + repr(osize);
			elif ('$mux' in operation) or ('sub' in operation):
				#osize = edgeAttr[(node, dataflow_node[index+2])];
				osize = edgeAttr[(dataflow_node[index+2], node)];
				operation = operation + repr(osize);
			elif '$' == operation:	
				predList = dfg.predecessors(node);
				operation = operation + repr(len(predList));
					
			dataflow.append(operation);
		dataflowList.append(dataflow);
	print dataflowList;
	return dataflowList;




def extractSWString(dataflowList_node):
	swList = set();
	for dataflow_node in dataflowList_node:
		#print "CHECKING DATAFLOW";
		sw="";
		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
		
			#	Make sure it isn't a port/point node
			if 'n' in node:# or 'x' in node:
				continue;
			elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
				continue;

			if shapeAttr[node] == "point":         # Check to see if it is a point node
				continue;
			elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
				continue;

			#print "CHECKING NODE: " + node;
			operation = labelAttr[node];

			if 'x' in node: 									 #Check to see if the node is a splice
				sw = sw + 'N';
			elif ('$add' in operation) or ('sub' in operation):                        #Add or sub operation
				sw = sw + 'A';
			elif ('$fa' in operation) or ('lcu' in operation):                        #Add or sub operation
				sw = sw + 'A';
			elif ('$alu' in operation) or ('pow' in operation):                        #Add or sub operation
				sw = sw + 'P';
			elif '$mul' in operation or '$div' in operation or 'mod' in operation:     #Multiplication operation
				sw = sw + 'X';
			elif '$mux' in operation or '$pmux' in operation:                          #Conditional
				sw = sw + 'M';
			elif '$dff' in operation or '$adff' in operation:                          #memory
				sw = sw + 'F';
			elif '$eq' in operation or '$ne' in operation:	                           #Equality Operation
				sw = sw + 'E';
			elif '$sh' in operation or '$ssh' in operation:                            #Shift
				sw = sw + 'S';
			elif '$gt' in operation or '$lt' in operation:                             #Comparator
				sw = sw + 'C';
			elif '$dlatch' in operation or '$sr' in operation:                         #memory
				sw = sw + 'F';
			elif '$' in operation:
				sw = sw + 'L';                                                           #Logic
			else:
				sw = sw + 'B';                                     #...
				

			#print "OPERATION= " + operation + " SW: " + sw;
				
					
		#print;
		swList.add(sw);

	return swList;


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





def findMaxPath(node, dst, marked, path, maxPath, maxPathList):
	#print "node " + node+ " dst: " + dst;
	if node == dst:
		path.append(node);
		if len(path) > len(maxPath):
			#maxPathList = [];
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			#print "NEW MAX PATH"
			#print maxPath;
		elif len(path) == len(maxPath):
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			
		path.pop(len(path)-1);
		return maxPath;

	path.append(node);
	marked.append(node);	

	predList = dfg.predecessors(node);
	for pred in predList:
		if pred not in marked:
			maxPath = findMaxPath(pred, dst,  marked, path, maxPath, maxPathList);
		else:
			length = len(maxPathList)
			for index in xrange(length):
				start = False;
				for i in maxPathList[index]:
					if i == pred:
						start = True;
						tempPath = copy.deepcopy(path);

					if start:
						tempPath.append(i);
	
				if start == True:
					if len(tempPath) > len(maxPath):
						#maxPathList = [];
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
						#print "NEW MAX PATH"
						#print maxPath;
					elif len(tempPath) == len(maxPath):
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
					break;
				


	path.pop(len(path)-1);
	#print "BT PATH"
	#print path;
	return maxPath;


















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
	fileStream = open(".seq", 'w');
	fileStream.write(sequence);
	fileStream.close();


	constSet= result[2];
	fileStream = open(".const", 'w');
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

	fileStream = open(".component", 'w');
	compstr = "";
	compstr = compstr + repr(len(fpDict));

	for fp in fpDict:
		compstr = compstr + "\n" + repr(len(fp));
		for k, v in fp.iteritems():
			compstr = compstr + " " + repr(k) + " " + repr(v) + "   ";
	fileStream.write(compstr);
	fileStream.close();






except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);




