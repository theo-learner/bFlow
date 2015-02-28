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
import timeit


def inc(counter, size):
	if(size in counter):
		counter[size] = counter[size] + 1;
	else:
		counter[size] = 1;

def getTopSequence(maxSeq, seqList):
	slist = [];
	numSeq = 0;
	for seq in seqList:
		slist.append(seq);
		numSeq = numSeq + 1;
		if(maxSeq == numSeq):
			return slist;

	return slist;



def extractSWString(dataflowList_node, labelAttr, shapeAttr):
	swList = set();
	for dataflow_node in dataflowList_node:
		sw="";
		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
		
			#	Make sure it isn't a port/point node
			if 'n' in node:#or 'x' in node:
				continue;
			elif shapeAttr[node] == "diamond":       # Check to see if it is a point node
				continue;
			elif shapeAttr[node] == "point":         # Check to see if it is a point node
				continue;

			operation = labelAttr[node];

			logicStr  = ["$not", "$and", "$or", "$xor", "$xnor", "$reduce", "$logic"]
			regStr    = ["$sr","$dff","$dffe","$adff","$dffsr","$dlatch"]
			wireStr   = ["$pos","$slice","$concat", "neg"]
			eqStr     = ["$eq","$eqx","$ne", "$nex"]
			muxStr    = ["$mux","$pmux"]
			shiftStr  = ["$shr","$shl","$sshl","$sshl","$shift","$shiftx"]
			arithStr  = ["$fa","$lcu", "$pow"]
			aluStr    = ["$alu"]
			macStr    = ["$macc", "alumacc"]
			addStr    = ["$add", "$sub"]
			multStr   = ["$mul"]
			cmpStr    = ["$lt", "$le", "$gt", "$ge"]
			divStr    = ["$div", "$mod"]
			lutStr    = ["$lut"]
			memStr    = ["$mem"]

			if 'x' in node or any(s in operation for s in wireStr):
				sw = sw + 'N';
			elif any(s in operation for s in muxStr):
				sw = sw + 'M';
			elif any(s in operation for s in regStr):
				sw = sw + 'F';
			elif any(s in operation for s in addStr):
				sw = sw + 'A';
			elif any(s in operation for s in logicStr):
				sw = sw + 'L';
			elif any(s in operation for s in eqStr):
				sw = sw + 'E';
			elif any(s in operation for s in cmpStr):
				sw = sw + 'C';
			elif any(s in operation for s in shiftStr):
				sw = sw + 'S';
			elif any(s in operation for s in multStr):
				sw = sw + 'X';
			elif any(s in operation for s in divStr):
				sw = sw + 'D';
			elif any(s in operation for s in memStr):
				sw = sw + 'R';
			elif any(s in operation for s in macStr):
				sw = sw + 'W';
			elif any(s in operation for s in aluStr):
				sw = sw + 'U';
			elif any(s in operation for s in arithStr):
				sw = sw + 'H';
			elif any(s in operation for s in lutStr):
				sw = sw + 'T';
			else:
				print "Unknown operation: " + operation;
				sw = sw + 'B';                                   
				
		swList.add(sw);

	return swList;



def findMaxPath(dfg, node, dst, marked, path, maxPath, maxPathList):
	if node == dst:
		path.append(node);
		if len(path) >= len(maxPath):
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
			for mp in maxPathList:
				try:
					index = mp.index(pred);
					newLen = len(path) + len(mp) - index
					
					if newLen >= len(maxPath):
						tempPath = path + mp[index:]
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);

					break;
				except ValueError:
					continue;
				


	path.pop(len(path)-1);
	return maxPath;












def longest_path(G):
    dist = {} # stores [node, distance] pair
    for node in nx.topological_sort(G):
        # pairs of dist,node for all incoming edges
        pairs = [(dist[v][0]+1,v) for v in G.pred[node]] 
        if pairs:
            dist[node] = max(pairs)
        else:
            dist[node] = (0, node)
    node,(length,_)  = max(dist.items(), key=lambda x:x[1])
    path = []
    while length > 0:
        path.append(node)
        length,node = dist[node]
    return list(reversed(path))



def extractDataflow(fileName):
	# Read in dot file of the dataflow
	print "[DFX] -- Extracting structural features..."# from : " + fileName;

	start_time = timeit.default_timer();
	dfg = nx.DiGraph(nx.read_dot(fileName));

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
	
	
	
	##########################################################################
	# Preprocess nodes
	##########################################################################
	logicStr  = ["$not", "$and", "$or", "$xor", "$xnor", "$reduce", "$logic"]
	regStr    = ["$sr","$dff","$dffe","$adff","$dffsr","$dlatch"]
	wireStr   = ["$pos","$slice","$concat", "neg"]
	eqStr     = ["$eq","$eqx","$ne", "$nex"]
	muxStr    = ["$mux","$pmux"]
	shiftStr  = ["$shr","$shl","$sshl","$sshl","$shift","$shiftx"]
	arithStr  = ["$fa","$lcu", "$pow"]
	aluStr    = ["$alu"]
	macStr    = ["$macc", "alumacc"]
	addStr    = ["$add", "$sub"]
	multStr   = ["$mul"]
	cmpStr    = ["$lt", "$le", "$gt", "$ge"]
	divStr    = ["$div", "$mod"]
	lutStr    = ["$lut"]
	memStr    = ["$mem"]


	fpDict = {}
	name = ["add", "mul", "div", "sh", "mux", "eq", "cmp", "reg", "mem", "log", "bb", "ffC", "outC" ];
	for s in name:
		fpDict[s] = {};
	
	outNodeList= [];
	inNodeList= [];
	constantList= [];
	totalFanin = 0;
	totalFanout = 0;
	maxFanin = 0;
	maxFanout = 0;
	nodeCount = 0;

	for node in nodeList:
		if 'v' in node:                     # Check to see if it is a  constant
			constantList.append(node);
			continue;

		predList = dfg.predecessors(node);
		sucList = dfg.successors(node);
		totalFanin = totalFanin + len(predList)
		totalFanout = totalFanout + len(sucList)
		nodeCount = nodeCount + 1;

		if shapeAttr[node] == "octagon":  # Check to see if it is a port node
			if len(predList) == 0:
				inNodeList.append(node);
			else:
				outNodeList.append(node);


		if(len(predList) > maxFanin):
			maxFanin = len(predList)
		if(len(sucList) > maxFanout):
			maxFanout = len(sucList)

		#If it is a operational block
		if shapeAttr[node] != "point" and shapeAttr[node] != "diamond":   
			label = labelAttr[node];
			label = re.search('\\\\n(.*)\|', label);
	
			if label != None:
				operation = label.group(1);
				labelAttr[node] = operation;

				size = 0;
				for pred in predList:
					psize = int(edgeAttr[(pred, node)]);
					if(psize > size):
						size = psize;

				for succ in sucList:
					ssize = int(edgeAttr[(node, succ)]);
					if(ssize > size):
						size = ssize;

				#Count the number of components
				if any(s in operation for s in muxStr):
					inc(fpDict["mux"], size)
				elif any(s in operation for s in regStr):
					count = 0;
					inc(fpDict["reg"], size)
					for inNode in inNodeList:
						if(nx.has_path(dfg, inNode, node)):
							count = count + 1;
					inc(fpDict["ffC"], count)
				elif any(s in operation for s in addStr):
					inc(fpDict["add"], size)
				elif any(s in operation for s in logicStr):
					inc(fpDict["log"], size)
				elif any(s in operation for s in eqStr):
					inc(fpDict["eq"], size)
				elif any(s in operation for s in cmpStr):
					inc(fpDict["cmp"], size)
				elif any(s in operation for s in shiftStr):
					inc(fpDict["sh"], size)
				elif any(s in operation for s in multStr):
					inc(fpDict["mul"], size)
				elif any(s in operation for s in divStr):
					inc(fpDict["div"], size)
				elif any(s in operation for s in memStr):
					inc(fpDict["mem"], size)
				elif any(s in operation for s in macStr):
					print "[WARNING] -- There is a macc type node: " + operation
				elif any(s in operation for s in aluStr):
					print "[WARNING] -- There is an alu type node: " + operation
				elif any(s in operation for s in arithStr):
					print "[WARNING] -- There is an arithmetic type node: " + operation
				elif any(s in operation for s in lutStr):
					print "[WARNING] -- There is a lut node: " + operation
				else:
					inc(fpDict["bb"], size)
	
	avgFanin = totalFanin / nodeCount;	
	avgFanout = totalFanout / nodeCount;	
	#print "TOT Fanin: " + repr(totalFanin)
	#print "TOT Fanout: " + repr(totalFanout)
	#print "count: " + repr(count)
	#print "Avg Fanin: " + repr(avgFanin)
	#print "Avg Fanout: " + repr(avgFanout)
	#print "Max Fanin: " + repr(maxFanin)
	#print "Max Fanout: " + repr(maxFanout)
	#print "Num Nodes: " + repr(len(nodeList))
	#print "Num Edges: " + repr(len(edgeList))
	#num node, num edge, num input, num output, max fanin, max fanout num cycle, 


	
	###########################################################################
	# Dataflow extraction Vectorized
	###########################################################################
	print "[DFX] -- Extracting functional features..."# from : " + fileName;
	dataflowMaxList_node = [];
	dataflowMinList_node = [];
	totalPathLen = 0;
	pathCount = 0;
	for out in outNodeList:
		count = 0;
		for constant in constantList:
			if(nx.has_path(dfg, constant, out)):
				count = count + 1;

		for inNode in inNodeList:
			if(not nx.has_path(dfg, inNode, out)):
				continue;

			shortestPaths = nx.all_shortest_paths(dfg, inNode, out)
			for s in shortestPaths:
				dataflowMinList_node.append(list(reversed(s)));
				totalPathLen = totalPathLen + len(s);
				pathCount = pathCount + 1;

			marked = [];
			path= [];
			maxPath= [];
			maxPathList= [];
			findMaxPath(dfg, out, inNode, marked, path, maxPath, maxPathList);

			maxPathList.sort(lambda x, y: -1*(cmp(len(x), len(y))));
			dataflowMaxList_node = dataflowMaxList_node + maxPathList[:3];
			
			count = count + 1;

		inc(fpDict["outC"], count)
	
	
	#compstr = repr(len(fpDict)) ;
	#for n, fp in fpDict.iteritems():		
#		compstr = compstr + "\n" + n + repr(len(fp)) + " ";
#		for k, v in fp.iteritems():		
#			compstr = compstr +repr(k) + " " + repr(v) + "   ";
		
#	print compstr


	###########################################################################
	# Extract the sequence 
	###########################################################################
	swMax = extractSWString(dataflowMaxList_node, labelAttr, shapeAttr);
	swMin = extractSWString(dataflowMinList_node, labelAttr, shapeAttr);

	maxSeq = 3;
	swMax = list(swMax);
	swMax.sort(lambda x, y: -1*(cmp(len(x), len(y))));
	maxList = getTopSequence(maxSeq, swMax)
	#print "MAXLIST: " + repr(maxList);

	swMin = list(swMin);
	swMin.sort(lambda x, y: -1*(cmp(len(x), len(y))));
	minList = getTopSequence(maxSeq, swMin)
	#print "MINLIST: " + repr(minList);
	
	
	
	
	



	#Output Constant Data
	print "[DFX] -- Extracting constant features..."# from : " + fileName;
	constSet = set();
	constStr = "";
	for constant in constantList:
		cnstVal = labelAttr[constant];
		cnstVal = re.search('\'(.*)', cnstVal);
		if(cnstVal == None):
			cnstVal = labelAttr[constant];
			cnstVal = cnstVal.replace("L","")
			if(len(cnstVal) > 19):
				cnstVal = "9999999999999999";
			constSet.add(cnstVal);
			constStr = constStr + cnstVal+ ",";
		else:
			cnstVal = cnstVal.group(1);
			if('x' in cnstVal):   #DON'T CARE
				cnstVal = -2;
				continue;
			elif('z' in cnstVal): #HIGH IMPEDANCE
				cnstVal = -3;
				continue;
			else:
				cnstVal = repr(int(cnstVal, 2));
				cnstVal.replace("L", "")
				if(len(cnstVal) > 19):
					cnstVal = "9999999999999999";

			constSet.add(cnstVal);
			constStr = constStr + cnstVal + ",";

	#print "CONST: " + repr(constSet);

	
	
	print "[DFX] -- Extracting additional features..."
	statstr = repr(len(nodeList)) + "," + repr(len(edgeList)) + ","
	statstr = statstr + repr(len(inNodeList)) + "," + repr(len(outNodeList)) + ","
	statstr = statstr + repr(maxFanin) + "," + repr(maxFanout) + ",";
	#statstr = statstr + repr(len(list(nx.simple_cycles(dfg)))) + ",";
	statstr = statstr + repr(float(totalPathLen)/float(pathCount));
	for freq in nx.degree_histogram(dfg):
		statstr = statstr + "," + repr(freq);
	#print "STAT: " + statstr

	elapsed = timeit.default_timer() - start_time;
	print "[DFX] -- ELAPSED: " +  repr(elapsed);
	print

	result = (maxList, minList, constSet, fpDict, statstr);
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
