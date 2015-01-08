#!/usr/bin/python2.7

import networkx as nx;
import sys;
import re;


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



def extractSWString():
	swList = set();
	for dataflow_node in dataflowList_node:
		#print "CHECKING DATAFLOW";
		sw="";
		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
		
			#	Make sure it isn't a port/point node
			if 'n' in node:
				continue;

			#print "CHECKING NODE: " + node;
			operation = labelAttr[node];

			if 'x' in node: 									 #Check to see if the node is a splice
				sw = sw + 'N';
			elif ('$add' in operation) or ('sub' in operation):  #Add or sub operation
				sw = sw + 'A';
			elif '$mul' in operation:                            #Multiplication operation
				sw = sw + 'X';
			elif '$eq' in operation:	                           #Equality Operation
				sw = sw + 'E';
			elif '$mux' in operation:                            #Conditional
				sw = sw + 'M';
			elif '$dff' in operation or '$adff' in operation:    #memory
				sw = sw + 'F';
			elif '$shift' in operation:                          #Shift
				sw = sw + 'S';
			elif '$gt' in operation or '$lt' in operation:       #Comparator
				sw = sw + 'C';
			elif '$' in operation:
				sw = sw + 'L';                                     #Logic
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
		print "Traceback Error:  Multiinput point!!!!!";
		print "NODE: " + node;
		print "predList: ";
		print predList;
		sys.exit(1);
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

# Read in dot file of the dataflow
fileName = sys.argv[1];
print "[DFX] -- Reading in DOT File: " + fileName;
dfg = nx.DiGraph(nx.read_dot(fileName));


#Get the nodes and edges of the graph
print "[DFX] -- Getting node and edge list"
nodeList = dfg.nodes();
edgeList = dfg.edges();

outNodeList= [];
inNodeList= [];
constantList= [];

###############################################################################
# Get the shape and label attributes
###############################################################################
shapeAttr = nx.get_node_attributes(dfg, 'shape');
labelAttr = nx.get_node_attributes(dfg, 'label');



###############################################################################
# Preprocess edges 
###############################################################################
edgeAttr = nx.get_edge_attributes(dfg, 'label');
for edge in edgeList:
	if edge not in edgeAttr:
		edgeAttr[edge] = 1;
	else:
		label = edgeAttr[edge];
		label = re.search('<(.*)>', label);
		edgeAttr[edge] = label.group(1);



###############################################################################
# Preprocess nodes
###############################################################################
for node in nodeList:
	if 'v' in node:                          # Check to see if it is a  constant
		constantList.append(node);
	elif shapeAttr[node] == "octagon":       # Check to see if it is a port node
		inputs = dfg.predecessors(node);
		if len(inputs) == 0:
			inNodeList.append(node);
		else:
			outNodeList.append(node);
		#print "SHAPE: " + shapeAttr[node];
	elif shapeAttr[node] == "point":         # Check to see if it is a point node
		#removeComponent(node);
		continue;
	elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
		removeComponent(node);
	else:                                    # Process the Combinational blocks
		label = labelAttr[node];
		label = re.search('\\\\n(.*)\|', label);

		if label != None:
			labelAttr[node] = label.group(1);

	#print "LABEL: " + labelAttr[node];
	#print "NAME:  " + node;

	#print





#Set the nodes with the simplified label
#nx.set_node_attributes(dfg, 'label', labelAttr);


#Combine adders into add trees
atIndex = 1;
for node in nodeList:
	#print "CHECKING NODE: " + repr(node);
	if(dfg.has_node(node)):
		if 'n' not in node:
			findAddTree(node);


	

# Dataflow extraction Vectorized
dataflowList_node = [];
for out in outNodeList:
	for inNode in inNodeList:
		#print "FROM " + inNode + " TO: " + out;
		try:
			p = nx.shortest_path(dfg, inNode, out);

			#Store the path of node names into list
			dataflowList_node.append(p);
		except:
			continue;
			#print "No path from " + inNode + " to " + out;




# Extract the dataflow object names with bus sizes
dataflowList = [];
for dataflow_node in dataflowList_node:
	dataflow = [];
	#print "CHECKING DATAFLOW";

	for index in xrange(len(dataflow_node)-2):
		node = dataflow_node[index+1];
		#print "CHECKING NODE: " + node;
		
		#	Make sure it isn't a port/point node
		if 'n' in node:
			continue;

		operation = labelAttr[node];

		if 'x' in node: 									 #Check to see if the node is a splice
			operation = "NETSPLICE";
		elif '$add' in operation:             #Check to see if the operation is a add
			osize = edgeAttr[(node, dataflow_node[index+2])];
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
			osize = edgeAttr[(node, dataflow_node[index+2])];
			operation = operation + repr(osize);
		elif '$' == operation:	
			predList = dfg.predecessors(node);
			operation = operation + repr(len(predList));
				
		
		
		#print "OPERATION= " + operation;
			
				
		dataflow.append(operation);
	#print;
	dataflowList.append(dataflow);

#print dataflowList;
#print constantList;


sw = extractSWString();
print sw;
maxString = "";
maxStringLen = 0;
for sw_str in sw:
	if len(sw_str) > maxStringLen:
		maxStringLen = len(sw_str);
		maxString = sw_str;

print "MAX STRING FEATURE: " + maxString;
fileStream = open(".yscript.seq", 'w');
fileStream.write(maxString);
fileStream.close();




