#!/usr/bin/python2.7

'''
	extractDataflow module
		Contains functions to extract a dataflow from a dot file
		given after yosys synthesis of a verilog file
'''

import networkx as nx;
import sys, traceback;
import re;
import copy;
import error;





def extractSWString(dataflowList_node, labelAttr, shapeAttr):
	swList = set();
	for dataflow_node in dataflowList_node:
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
			elif '$mem' in operation:                         #memory
				sw = sw + 'R';
			elif '$' in operation:
				sw = sw + 'L';                                                           #Logic
			else:
				sw = sw + 'B';                                     #...
				

				
					
		swList.add(sw);

	return swList;



def findMaxPath(dfg, node, dst, marked, path, maxPath, maxPathList):
	if node == dst:
		path.append(node);
		if len(path) > len(maxPath):
			#maxPathList = [];
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
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
			maxPath = findMaxPath(dfg, pred, dst,  marked, path, maxPath, maxPathList);
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
					elif len(tempPath) == len(maxPath):
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
					break;
				


	path.pop(len(path)-1);
	return maxPath;
















def extractDataflow(fileName):
	# Read in dot file of the dataflow
	print "[DFX] -- Extracting features..."# from : " + fileName;
	dfg = nx.DiGraph(nx.read_dot(fileName));
	g = nx.Graph(nx.read_dot(fileName));

	nc = nx.number_connected_components(g);
	if nc == 1:
		fileStream = open(".stat", 'w');
		fileStream.write(repr(nx.diameter(g)) + "\n");
		fileStream.write(repr(nx.radius(g))+ "\n");
		fileStream.write(repr(nx.degree_pearson_correlation_coefficient(g))+ "\n");
		fileStream.close();

	#Get the nodes and edges of the graph
	nodeList = dfg.nodes();
	edgeList = dfg.edges();
	

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
	name = ["add", "sub", "mul", "div", "sh", "mux", "eq", "cmp", "ff", "mem", "log", "bb", "ffC", "outC" ];
	addc= {};
	muxc= {};
	ffc= {};
	subc= {};
	mulc= {};
	divc= {};
	eqc= {};
	cmpc= {};
	memc= {};
	shc= {};
	lc= {};
	bc= {};
	fflist = [];

	outNodeList= [];
	inNodeList= [];
	constantList= [];
	memorywrList= [];
	for node in nodeList:
		if 'v' in node:                          # Check to see if it is a  constant
			constantList.append(node);
		elif shapeAttr[node] == "octagon":       # Check to see if it is a port node
			inputs = dfg.predecessors(node);
			if len(inputs) == 0:
				inNodeList.append(node);
			else:
				outNodeList.append(node);
		elif shapeAttr[node] == "point":         # Check to see if it is a point node
			continue;
		elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
			continue;
		else:                                    # Process the Combinational blocks
			label = labelAttr[node];
			label = re.search('\\\\n(.*)\|', label);
	
			if label != None:
				labelAttr[node] = label.group(1);
				operation = labelAttr[node];

				if("$memwr" in operation):
					memorywrList.append(node);
					continue;
				
				sucList = dfg.successors(node);
				#print "SIZE OF SUCC: " + repr(len(sucList)) + " LABEL: " + label.group(1);

				size = edgeAttr[(node, sucList[0])];
				size = int(size);


				#Count the number of components
				if ('$add' in operation):
					if(size in addc):
						addc[size] = addc[size] + 1;
					else:
						addc[size] = 1;
				elif ('sub' in operation):                        #Add or sub operation
					if(size in subc):
						subc[size] = subc[size] + 1;
					else:
						subc[size] = 1;
				elif '$mul' in operation:
					if(size in mulc):
						mulc[size] = mulc[size] + 1;
					else:
						mulc[size] = 1;
				elif '$div' in operation:
					if(size in divc):
						mulc[size] = divc[size] + 1;
					else:
						mulc[size] = 1;
				elif '$mux' in operation or '$pmux' in operation:                          #Conditional
					if(size in muxc):
						muxc[size] = muxc[size] + 1;
					else:
						muxc[size] = 1;
				elif '$dff' in operation or '$adff' in operation:                          #memory
					if(size in ffc):
						ffc[size] = ffc[size] + 1;
					else:
						ffc[size] = 1;
					fflist.append(node);
				elif '$mem' in operation:
					if(size in memc):
						memc[size] = memc[size] + 1;
					else:
						memc[size] = 1;
				elif '$eq' in operation or '$ne' in operation:	                           #Equality Operation
					if(size in eqc):
						eqc[size] = eqc[size] + 1;
					else:
						eqc[size] = 1;
				elif '$sh' in operation or '$ssh' in operation:                            #Shift
					if(size in shc):
						shc[size] = shc[size] + 1;
					else:
						shc[size] = 1;
				elif '$gt' in operation or '$lt' in operation:                             #Comparator
					if(size in cmpc):
						cmpc[size] = cmpc[size] + 1;
					else:
						cmpc[size] = 1;
				elif '$dlatch' in operation or '$sr' in operation:                         #memory
					if(size in ffc):
						ffc[size] = ffc[size] + 1;
					else:
						ffc[size] = 1;
					fflist.append(node);
				elif '$' in operation:
					if(size in lc):
						lc[size] = lc[size] + 1;
					else:
						lc[size] = 1;
				else:
					if(size in bc):
						bc[size] = bc[size] + 1;
					else:
						bc[size] = 1;
	
		
	
	###############################################################################
	# FF and input correspondence
	###############################################################################
	ffCc = {};
	for ff in fflist:
		count = 0;

		for inNode in inNodeList:
			if(nx.has_path(dfg, inNode, ff)):
				count = count + 1;
		
		if(count in ffCc):
			ffCc[count] = ffCc[count] + 1;
		else:
			ffCc[count] = 1;
	
	outCc = {};
	for out in outNodeList:
		count = 0;

		for inNode in inNodeList:
			if(nx.has_path(dfg, inNode, out)):
				count = count + 1;

		for constant in constantList:
			if(nx.has_path(dfg, constant, out)):
				count = count + 1;
		
		if(count in outCc):
			outCc[count] = outCc[count] + 1;
		else:
			outCc[count] = 1;
		

	###############################################################################
	# Dataflow extraction Vectorized
	###############################################################################
	dataflowMaxList_node = [];
	dataflowMinList_node = [];
	for out in outNodeList:
		for inNode in inNodeList:
			#t = nx.dfs_postorder_nodes(dfg, inNode);
			if(not nx.has_path(dfg, inNode, out)):
				continue;
			
			marked = [];
			path= [];
			maxPath= [];
			maxPathList= [];
			findMaxPath(dfg, out, inNode, marked, path, maxPath, maxPathList);

			for s in nx.all_shortest_paths(dfg, inNode, out):
				dataflowMinList_node.append(list(reversed(s)));

			#Store the path of node names into list
			maxLength = 0;
			
			tempMaxList = []
			for p in maxPathList:
				if len(p) > maxLength:
					maxLength = len(p);
					tempMaxList= [];
					tempMaxList.append(p);

				elif len(p) == maxLength:
					tempMaxList.append(p);

			for p in tempMaxList:
				dataflowMaxList_node.append(p);






	###############################################################################
	# Extract the sequence 
	###############################################################################
	swMax = extractSWString(dataflowMaxList_node, labelAttr, shapeAttr);
	swMin = extractSWString(dataflowMinList_node, labelAttr, shapeAttr);

	swMax = list(swMax);
	swMax.sort(lambda x, y: -1*(cmp(len(x), len(y))));

	seqOutput = "";
	numMaxSeq = 3;
	numSeq = 0;
	sequence = "";
	maxLength = 0;
	maxList = [];
	for sw_str in swMax:
		sequence = sequence + sw_str + "\n";
		maxList.append(sw_str);
		numSeq = numSeq + 1;
		if(numMaxSeq == numSeq):
			break;

	sequence = repr(numSeq) + "\n" + sequence;
	seqOutput = sequence;

	

	swMin = list(swMin);
	swMin.sort(lambda x, y: -1*(cmp(len(x), len(y))));

	numSeq = 0;
	sequence = "";
	maxLength = 0;
	minList = [];
	for sw_str in swMin:
		sequence = sequence + sw_str + "\n";
		minList.append(sw_str);
		numSeq = numSeq + 1;
		if(numMaxSeq == numSeq):
			break;

	sequence = repr(numSeq) + "\n" + sequence;
	seqOutput = seqOutput +  sequence;



	#Output Constant Data
	constSet = set();
	constStr = "";
	for constant in constantList:
		cnstVal = labelAttr[constant];
		cnstVal = re.search('\'(.*)', cnstVal);
		if(cnstVal == None):
			cnstVal = labelAttr[constant];
			cnstVal = cnstVal.replace("L","")
			constSet.add(cnstVal);
			constStr = constStr + cnstVal+ ",";
		else:
			cnstVal = cnstVal.group(1);
			if('x' in cnstVal):
				cnstVal = -2;
				continue;
			elif('z' in cnstVal):
				cnstVal = -3;
				continue;
			else:
				cnstVal = repr(int(cnstVal, 2));
				cnstVal.replace("L", "")
				if(len(cnstVal) > 19):
					cnstVal = "9999999999999999";

			constSet.add(cnstVal);
			constStr = constStr + cnstVal + ",";

	fileStream = open(".const", 'w');
	fileStream.write(repr(len(constSet))+"\n");
	for constant in constSet:		
		fileStream.write(constant+"\n");
	fileStream.close();
	
	constStr = constStr[:-1];
	fileStream = open(".const2", 'w');
	if(len(constStr)> 0):
		constStr = constStr.replace(",0", ",-1");
		if(constStr[0] == '0'):
			constStr = '-1' + constStr[1:];

	fileStream.write(constStr);
	fileStream.close();
	
	
	#Output number for each component 
	compstr = "";
	fileStream = open(".component", 'w');
	compstr = compstr + "13\n"+repr(len(addc)) + " ";
	for k, v in addc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(subc)) + " ";
	for k, v in subc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(mulc)) + " ";
	for k, v in mulc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(divc)) + " ";
	for k, v in divc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";
	
	compstr = compstr + "\n"+repr(len(shc)) + " ";
	for k, v in shc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(muxc)) + " ";
	for k, v in muxc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(eqc)) + " ";
	for k, v in eqc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(cmpc)) + " ";
	for k, v in cmpc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(ffc)) + " ";
	for k, v in ffc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(memc)) + " ";
	for k, v in memc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(lc)) + " ";
	for k, v in lc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";

	compstr = compstr + "\n"+repr(len(bc)) + " ";
	for k, v in bc.iteritems():		
		fileStream.write(repr(k) + " " + repr(v) + "   ");

	compstr = compstr + "\n"+repr(len(ffCc)) + " ";
	for k, v in ffCc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";
	
	compstr = compstr + "\n"+repr(len(outCc)) + " ";
	for k, v in outCc.iteritems():		
		compstr = compstr +repr(k) + " " + repr(v) + "   ";
	
	#fileStream.write(compstr);
	#fileStream.close();

	fp = [];
	fp.append(addc)
	fp.append(subc)
	fp.append(mulc)
	fp.append(divc)
	fp.append(shc)
	fp.append(muxc)
	fp.append(eqc)
	fp.append(cmpc)
	fp.append(ffc)
	fp.append(memc)
	fp.append(lc)
	fp.append(bc)
	fp.append(ffCc)
	fp.append(outCc)
	result = (maxList, minList, constSet, fp, name);
	return result;



def main():
	if len(sys.argv) != 2: 
		print "[ERROR] -- Not enough argument. Provide DOT File to process";
		print "        -- ARG1: dot file";
		exit();
	
	dotfile = sys.argv[1];
	extractDataflow(dotfile);


if __name__ == '__main__':
	main();
