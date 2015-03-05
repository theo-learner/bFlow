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
from collections import Counter

def Entropy(text):
    import math
    log2=lambda x:math.log(x)/math.log(2)
    exr={}
    infoc=0
    for each in text:
        try:
            exr[each]+=1
        except:
            exr[each]=1
    textlen=len(text)
    for k,v in exr.items():
        freq  =  1.0*v/textlen
        infoc+=freq*log2(freq)
    infoc*=-1
    return infoc
	

def findMaxEntropy(sequenceList):
	maxEntropy = 0;
	maxString = '';
	for sequence in sequenceList:
		entropy = Entropy(sequence)
		if entropy > maxEntropy:
			maxEntropy = entropy;
			maxString = sequence;
	
	return maxString;


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

def extractSequenceLetter(node, labelAttr, shapeAttr):
	#	Make sure it isn't a port/point node
	if 'n' in node or 'v' in node:#or 'x' in node:
		return ""
	elif shapeAttr[node] == "diamond":       # Check to see if it is a point node
		return ""
	elif shapeAttr[node] == "point":         # Check to see if it is a point node
		return ""

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
		return 'N';
	elif any(s in operation for s in muxStr):
		return 'M';
	elif any(s in operation for s in regStr):
		return 'F';
	elif any(s in operation for s in addStr):
		return 'A';
	elif any(s in operation for s in logicStr):
		return 'L';
	elif any(s in operation for s in eqStr):
		return 'E';
	elif any(s in operation for s in cmpStr):
		return 'C';
	elif any(s in operation for s in shiftStr):
		return 'S';
	elif any(s in operation for s in multStr):
		return 'X';
	elif any(s in operation for s in divStr):
		return 'D';
	elif any(s in operation for s in memStr):
		return 'R';
	elif any(s in operation for s in macStr):
		return 'W';
	elif any(s in operation for s in aluStr):
		return 'U';
	elif any(s in operation for s in arithStr):
		return 'H';
	elif any(s in operation for s in lutStr):
		return 'T';
	else:
		print "Unknown operation: " + operation;
		return 'B';                                   


def extractSWString(dataflow_node, labelAttr, shapeAttr):
	sw = '';
	for index in xrange(len(dataflow_node)-2):
		node = dataflow_node[index+1];
		sw = sw + extractSequenceLetter(node, labelAttr, shapeAttr);
	return sw;



def extractSWStringList(dataflowList_node, foundList, labelAttr, shapeAttr):
	swList = set();
	for dataflow_node in dataflowList_node:
		sw = extractSWString(dataflow_node, labelAttr, shapeAttr);

		if(sw in foundList):
			continue;
		swList.add(sw);

	return swList;


def numAlpha(seqList):
	setList = set();
	setList.update(seqList);
	setList.discard("");

	return len(setList);

	
def findMaxAlphaPath(dfg, node, dst, marked, path, maxNumAlpha, maxPath, maxPathList, labelAttr, shapeAttr):
	
	letter = extractSequenceLetter(node, labelAttr, shapeAttr);
	if(letter == 'X'):
		print "MULT FOUNNDDDDDDDDDDDDDDDD!"
		exit()
	if node == dst:
		path.append(node);
		newSequence = extractSWString(path, labelAttr, shapeAttr);
		numAlphabet = numAlpha(newSequence);
		if numAlphabet > maxNumAlpha:
			maxPathList[:] = [];
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			maxNumAlpha = numAlphabet
		elif numAlphabet == maxNumAlpha:
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			
			
		path.pop(len(path)-1);
		return maxNumAlpha;

	path.append(node);
	marked.append(node);	

	predList = dfg.predecessors(node);

	for pred in predList:
		if pred not in marked:
			maxNumAlpha= findMaxAlphaPath(dfg, pred, dst,  marked, path, maxNumAlpha, maxPath, maxPathList, labelAttr, shapeAttr);
		else:
			for mp in maxPathList:
				try:
					index = mp.index(pred);
					tempPath = path + mp[index:]
					newSequence = extractSWString(tempPath, labelAttr, shapeAttr);
					numAlphabet = numAlpha(newSequence);

					if numAlphabet > maxNumAlpha:
						maxPathList[:] = [];
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
						maxNumAlpha = numAlphabet
					elif numAlphabet == maxNumAlpha:
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
						break;
				except ValueError:
					continue;
				
	path.pop(len(path)-1);
	return maxNumAlpha;


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

def dfs(dfg, node, marked, path):
	letter = extractSequenceLetter(node, labelAttr, shapeAttr);
	if(letter == 'X'):
		print "MULT FOUNNDDDDDDDDDDDDDDDD!"
		exit()
	path.append(node);
	marked.append(node);	

	predList = dfg.predecessors(node);
	for pred in predList:
		if pred not in marked:
			dfs(dfg, pred, marked, path);


	path.pop(len(path)-1);


def faninCone(dfg, node, dst, marked, path, maxPath, maxPathList):
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
	if(".dot" not in fileName):
		print "[ERROR] -- Input file does not seem to be a dot file"
		exit()	

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
	ffList = [];
	multList = [];
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
				#labelAttr[node] = operation

				size = 0;
				for pred in predList:
					psize = int(edgeAttr[(pred, node)]);
					if(psize > size):
						size = psize;

				for succ in sucList:
					ssize = int(edgeAttr[(node, succ)]);
					if(ssize > size):
						size = ssize;

				if(size == 0):
					print "[WARNING] -- There is a size of zero. OPERATION: " + operation;
					print "IN:  " + repr(len(predList))
					print "OUT: " + repr(len(sucList))
					

				#Count the number of components
				if any(s in operation for s in muxStr):
					inc(fpDict["mux"], size)
				elif any(s in operation for s in regStr):
					inc(fpDict["reg"], size)
					ffList.append(node);
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
					multList.append(node)
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

	print "TOT Fanin: " + repr(totalFanin)
	print "TOT Fanout: " + repr(totalFanout)
	print "count: " + repr(nodeCount)
	avgFanin = totalFanin / nodeCount;	
	avgFanout = totalFanout / nodeCount;	
	#print "Avg Fanin: " + repr(avgFanin)
	#print "Avg Fanout: " + repr(avgFanout)
	#print "Max Fanin: " + repr(maxFanin)
	#print "Max Fanout: " + repr(maxFanout)
	#print "Num Nodes: " + repr(len(nodeList))
	#print "Num Edges: " + repr(len(edgeList))
	#print "Num In : " + repr(len(inNodeList))
	#print "Num Out: " + repr(len(outNodeList))
	#num node, num edge, num input, num output, max fanin, max fanout num cycle, 
	for outNode in outNodeList:
		for mult in multList:
			print "CHECKING " + mult + " TO " + outNode;
			if(nx.has_path(dfg, mult, outNode)):
				print "---------------YES_-------------";
	exit()



	#Need to wait till all the inputs have been found during node processing
	if (float(len(inNodeList) + len(constantList)) * 0.25 > len(ffList)) or len(ffList) == 1:
		for node in ffList:	
			count = 0;
			for inNode in inNodeList:
				if(nx.has_path(dfg, inNode, node)):
					count = count + 1;

			for inNode in constantList:
				if(nx.has_path(dfg, inNode, node)):
					count = count + 1;

			inc(fpDict["ffC"], count)
	else:
		inFanout = {};
		for inNode in inNodeList:
			fanout = nx.dfs_successors(dfg, inNode);
			inFanout[inNode] = fanout
		
		for inNode in constantList:
			fanout = nx.dfs_successors(dfg, inNode);
			inFanout[inNode] = fanout

		ffCounts = dict()	
		for n, fanout in inFanout.iteritems():
			ffNodes = [fanoutnode for fanoutnode in  fanout for ff in ffList if ff == fanoutnode]
			for ff in ffNodes:
				ffCounts[ff] = ffCounts.get(ff, 0) + 1;
		
		fpDict["ffC"] = Counter(ffCounts.values());
					
		

	
	###########################################################################
	# Dataflow extraction Vectorized
	###########################################################################
	print "[DFX] -- Extracting functional features..."# from : " + fileName;
	dataflowMaxList_node = [];
	dataflowMinList_node = [];
	maxList = set();
	minList = set();
	totalPathLen = 0;
	pathCount = 0;
	for out in outNodeList:
		count = 0;

		minPaths = []
		maxPaths = []

		for constant in constantList:
			if(nx.has_path(dfg, constant, out)):
				count = count + 1;

		for inNode in inNodeList:
			if(not nx.has_path(dfg, inNode, out)):
				continue;

			shortestPaths = nx.all_shortest_paths(dfg, inNode, out)
			for s in shortestPaths:
				minPaths.append(list(reversed(s)));
				totalPathLen = totalPathLen + len(s);
				pathCount = pathCount + 1;

			#Necessary for recursion
			marked = [];
			path= [];
			maxPath= [];
			maxPathList= [];
			#findMaxAlphaPath(dfg, out, inNode, marked, path, 0, maxPath, maxPathList, labelAttr, shapeAttr);
			findMaxPath(dfg, out, inNode, marked, path, maxPath, maxPathList);
			#print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
			#newSequence = extractSWStringList(maxPathList,[], labelAttr, shapeAttr);
			#print newSequence 
			#print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
			#maxPathList.sort(lambda x, y: -1*(cmp(len(x), len(y))));
			maxPaths = maxPaths + maxPathList;
			
			count = count + 1;

			#Extract the sequence representation
			swMax = extractSWStringList(maxPaths, maxList, labelAttr, shapeAttr);
			swMin = extractSWStringList(minPaths, minList, labelAttr, shapeAttr);

			#Find the sequences with the highest entropy
			maxSequence = findMaxEntropy(swMax);
			minSequence = findMaxEntropy(swMin);
			#print "MAX: " + maxSequence;

			#Store the highest entropy sequence
			maxList.add(maxSequence);
			minList.add(minSequence);
			
		#Number of inputs the output depends on;
		inc(fpDict["outC"], count)
	
	
	compstr = repr(len(fpDict)) ;
	for n, fp in fpDict.iteritems():		
		compstr = compstr + "\n" + n + "\t" + repr(len(fp)) + " ";
		for k, v in fp.iteritems():		
			compstr = compstr +repr(k) + " " + repr(v) + "   ";
		
	print compstr


	###########################################################################
	# Extract the sequence 
	###########################################################################
	
	#swMax = extractSWStringList(dataflowMaxList_node, labelAttr, shapeAttr);
	#swMin = extractSWStringList(dataflowMinList_node, labelAttr, shapeAttr);

	maxSeq = 3;
	swMax = list(maxList);
	swMax.sort(lambda x, y: -1*(cmp(len(x), len(y))));
	maxList = getTopSequence(maxSeq, swMax)
	print "MAXLIST: " + repr(maxList);

	swMin = list(minList);
	swMin.sort(lambda x, y: -1*(cmp(len(x), len(y))));
	minList = getTopSequence(maxSeq, swMin)
	print "MINLIST: " + repr(minList);
	
	
	
	



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
