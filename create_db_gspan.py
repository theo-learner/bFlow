#!/usr/bin/python2.7
'''
	MKDB-GSPAN: 
		Creates a database file for gSpan. Input files are dot files of synthesized 
		verilog files given by YoSys. 

		Used to find the most frequent subgraph that exists among a group of circutis
'''


import networkx as nx;
import sys, traceback;
import re;
from os import listdir;

def translate(dotfile):
	print " -- Reading in dot File: " + dotfile;
	dfg = nx.DiGraph(nx.read_dot(dotfile));

	nodeList = dfg.nodes();
	labelAttr = nx.get_node_attributes(dfg, 'label');
	shapeAttr = nx.get_node_attributes(dfg, 'shape');


###############################################################################
# Preprocess edges 
###############################################################################
	edgeList = dfg.edges();
	edgeAttr = nx.get_edge_attributes(dfg, 'label');
	for edge in edgeList:
		if edge not in edgeAttr:
			edgeAttr[edge] = 1;
		else:
			label = edgeAttr[edge];
			label = re.search('<(.*)>', label);
			edgeAttr[edge] = label.group(1);


	circuit = "";
	index = 0; 
	nmap = {};

	###############################################################################
	# Process nodes
	###############################################################################
	for node in nodeList:
		nmap[node] = index;

		if 'v' in node:                          # Check to see if it is a  constant
			circuit = circuit + "v " +   repr(index) + " 0\n";

		elif shapeAttr[node] == "octagon":       # Check to see if it is a port node
			inputs = dfg.predecessors(node);
			if len(inputs) == 0:
				circuit = circuit + "v " + repr(index) + " 1\n";
			else:
				circuit = circuit + "v " + repr(index) + " 2\n";

		# Check to see if it is a point node
		elif shapeAttr[node] == "point" or shapeAttr[node] == "diamond": 
			circuit = circuit + "v " + repr(index) + " 3\n";

		else:                                    # Process the Combinational blocks
			label = labelAttr[node];
			label = re.search('\\\\n(.*)\|', label);
	
			if label != None:
				labelAttr[node] = label.group(1);
				sucList = dfg.successors(node);
				size = edgeAttr[(node, sucList[0])];
				size = int(size);

				operation = labelAttr[node];
				if 'x' in node: 									 #check to see if the node is a splice
					sw =  '4';
				elif ('$add' in operation):
					sw =  '5';
				elif('sub' in operation):                        #add or sub operation
					sw =  '6';
				elif ('$fa' in operation):
					sw =  '7';
				elif('lcu' in operation):                        #add or sub operation
					sw = '8';
				elif ('$alu' in operation): 
					sw = '9';
				elif('pow' in operation):                        #add or sub operation
					sw = '10';
				elif '$mul' in operation :
					sw = '11';
				elif '$div' in operation :
					sw = '12';
				elif 'mod' in operation:     #multiplication operation
					sw = '13';
				elif '$mux' in operation or '$pmux' in operation:                          #conditional
					sw = '14';
				elif '$dff' in operation or '$adff' in operation:                          #memory
					sw = '15';
				elif '$eq' in operation: 
					sw = '16';
				elif '$ne' in operation:	                           #equality operation
					sw = '17';
				elif '$sh' in operation  or '$ssh' in operation:                            #shift
					sw = '18';
				elif '$gt' in operation :
					sw = '19';
				elif '$lt' in operation:                             #comparator
					sw = '20';
				elif '$dlatch' in operation or '$sr' in operation:                         #memory
					sw = '21';
				elif '$reduce' in operation:
					sw = '22';                                                           #logic
				elif '$' in operation:
					sw = '23';
				else:
					sw = '24';                                     #...

				circuit = circuit + "v " +  repr(index) + " " + sw+ "\n";
			else:
				if 'x' in node: 									 #check to see if the node is a splice
					sw =  '4';
					circuit = circuit + "v " +  repr(index) + " " + sw+ "\n";
				else:
					print "NODE: " + node + " LABEL: " + labelAttr[node];
		index = index + 1;	
	



###############################################################################
# Process edges 
###############################################################################
	for edge in edgeList:
		src = nmap[edge[0]] 
		dst = nmap[edge[1]]
		circuit = circuit + "e " + repr(src) + " " +repr(dst) + " 0\n";

	return circuit;












		
try:
	# Read in dot file of the dataflow
	#dbfile= sys.argv[1];
	#print "[MDB-gSpan] -- Reading in DB File: " + dbfile;

	#for line in dbfile:
	#	print "[MDB-gSpan] -- Reading in dot File: " + dbfile;

	if len(sys.argv) != 2:
		print "[ERROR] -- Not enough argument. Provide direction of DOT files to process";
		exit();
	
	dbdir= sys.argv[1];
	print "[MDB-gSpan] -- Reading directory " + dbdir;
	index = 0;
	dbstr= ""
	for dotfile in listdir(dbdir):
		graph = translate(dbdir+dotfile);
		if(graph == ""):
			print "[ERROR] -- Dot file returned empty string" 
			print "        -- Skipping..."
			continue;
		dbstr = dbstr + "t # " + repr(index) + "\n" +  graph;
		index = index + 1;
	
	#rint dbstr 
	
	print "[MDB-gSpan] -- Writing database file: db_gSpan" ;
	fileStream = open("db_gSpan", 'w');
	fileStream.write(dbstr);
	fileStream.close();
		

except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);


print "[MDB-gSpan] -- COMPLETE!";
