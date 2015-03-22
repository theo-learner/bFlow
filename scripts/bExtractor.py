#!/usr/bin/python2.7

'''
	dataflow module
		Contains functions to extract a dataflow from a dot file
		Given after yosys synthesis of a verilog file
'''

import networkx as nx;
import sys, traceback;
import re;
import copy;
import error;
import timeit
from collections import Counter
import yosys;
import math

class BirthmarkExtractor(object):

	def __init__(self, dotFile):
		'''
		 Constructor	
		   Initializes and reads in the circuit
			 Initializes most of the private variables and settings 
		'''
		self.dfg = nx.DiGraph(nx.read_dot(dotFile));
		#Get the nodes and edges of the graph
		self.nodeList = self.dfg.nodes();
		self.edgeList = self.dfg.edges();

		# Get the shape and label attributes
		self.shapeAttr = nx.get_node_attributes(self.dfg, 'shape');
		self.labelAttr = nx.get_node_attributes(self.dfg, 'label');

		# Preprocess edges 
		self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
		for edge in self.edgeList:
			if edge not in self.edgeAttr:
				self.edgeAttr[edge] = 1;
			else:
				label = self.edgeAttr[edge];
				label = re.search('<(.*)>', label);
				self.edgeAttr[edge] = label.group(1);

		self.logicStr  = ["$not", "$and", "$or", "$xor", "$xnor", "$reduce", "$logic"]
		self.regStr    = ["$sr","$dff","$dffe","$adff","$dffsr","$dlatch"]
		self.wireStr   = ["$pos","$slice","$concat", "neg"]
		self.eqStr     = ["$eq","$eqx","$ne", "$nex"]
		self.muxStr    = ["$mux","$pmux"]
		self.shiftStr  = ["$shr","$shl","$sshl","$sshl","$shift","$shiftx"]
		self.arithStr  = ["$fa","$lcu", "$pow"]
		self.aluStr    = ["$alu"]
		self.macStr    = ["$macc", "alumacc"]
		self.addStr    = ["$add", "$sub"]
		self.multStr   = ["$mul"]
		self.cmpStr    = ["$lt", "$le", "$gt", "$ge"]
		self.divStr    = ["$div", "$mod"]
		self.lutStr    = ["$lut"]
		self.memStr    = ["$mem"]
		
		self.constantList= [];
		self.fpDict = {}
		name = ["add", "mul", "div", "sh", "mux", "eq", "cmp", "reg", "mem", "log", "bb", "ffC", "outC" ];
		for s in name:
			self.fpDict[s] = {};

		self.statstr = "";
	
	
	
	def inc(self, name, size):
		'''
			 Increments the counter dictionary value of size
			 @PARAM: counter- the fingerprint feature dictionary
			 @PARAM: size   - the specific size of the feature
		'''
		if(size in self.fpDict[name]):
			self.fpDict[name][size] = self.fpDict[name][size] + 1;
		else:
			self.fpDict[name][size] = 1;



	def Entropy(self, text):
		'''
			 Calculates the entropy of a given string
			 @PARAM: text- string to calculate entropy of
			 @RETURN Entropy value
		'''
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



	def findMaxEntropy(self, sequenceList):
		'''
			 Finds the string in the list with the greatest entropy
			 @PARAM: sequenceList- List of sequences
			 @RETURN String with the largest entropy
		'''
		if(len(sequenceList) == 1):
			item,=sequenceList;
			return item

		maxEntropy = 0;
		maxString = '';
		for sequence in sequenceList:
			entropy = self.Entropy(sequence)
			#print "SEQUENCE:" + sequence + " ENTROPY: " + repr(entropy)
			if entropy >= maxEntropy:
				maxEntropy = entropy;
				maxString = sequence;
		
		return maxString;



	def getTopSequence(self, maxSeq, seqList):
		'''
			Gets the top (maxSeq) number of sequences
			 @PARAM: maxSeq - Number of sequences to return
			 @PARAM: seqList- Full list of sequences 
			 @RETURN List of the top maxSeq number of items in seqList
		'''
		slist = [];
		numSeq = 0;
		for seq in seqList:
			slist.append(seq);
			numSeq = numSeq + 1;
			if(maxSeq == numSeq):
				return slist;

		return slist;



	def extractSequenceLetter(self, node):
		'''
			Maps the operation of the function to a letter
			 @PARAM: node     - The node to assign a letter to
			 @RETURN Letter of the function
		'''
		if any(s in node for s in ['n', 'v', 'x']): # Check to see if node is splice, const, port
			return ""
		elif self.shapeAttr[node] == "diamond":          # Check to see if it is a wire node
			return ""
		elif self.shapeAttr[node] == "point":            # Check to see if it is a point node
			return ""

		operation = self.labelAttr[node];

		if any(s in operation for s in self.wireStr):
			return 'N';
		elif any(s in operation for s in self.muxStr):
			return 'M';
		elif any(s in operation for s in self.regStr):
			return 'F';
		elif any(s in operation for s in self.addStr):
			return 'A';
		elif any(s in operation for s in self.logicStr):
			return 'L';
		elif any(s in operation for s in self.eqStr):
			return 'E';
		elif any(s in operation for s in self.cmpStr):
			return 'C';
		elif any(s in operation for s in self.shiftStr):
			return 'S';
		elif any(s in operation for s in self.multStr):
			return 'X';
		elif any(s in operation for s in self.divStr):
			return 'D';
		elif any(s in operation for s in self.memStr):
			return 'R';
		elif any(s in operation for s in self.macStr):
			return 'W';
		elif any(s in operation for s in self.aluStr):
			return 'U';
		elif any(s in operation for s in self.arithStr):
			return 'H';
		elif any(s in operation for s in self.lutStr):
			return 'T';
		else:
			print "Unknown operation: " + operation;
			return 'B';                                   



	def extractSWString(self, dataflow_node):
		'''
			Converts a list of operations into a sequence (list) of letters
			 @PARAM: dataflow_node- A datapath of the circuit (list of operations)
			 @RETURN List of the operations converted into a sequence
		'''
		sw = '';
		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
			sw = sw + self.extractSequenceLetter(node);
		return sw;



	def extractSWStringList(self, dataflowList_node, foundList):
		'''
			Converts a list of datapaths into their sequences
			 @PARAM: dataflowList_node- List of datapaths 
			 @PARAM: foundList -        List of nodes already found. Omit them
			 @RETURN Converted list of sequences
		'''
		swList = set();
		for dataflow_node in dataflowList_node:
			sw = self.extractSWString(dataflow_node);

			if(sw in foundList):
				continue;
			swList.add(sw);

		return swList;



	def numAlpha(self, seqList):
		'''
			Gets the number of unique letters in the list
			 @PARAM: seqList- List of letters of the datapath
			 @RETURN number of unique letters in the sequence
		'''
		setList = set();
		setList.update(seqList);

		return len(setList);


		
	def findMaxAlphaPath(self, node, dst, marked, path, pathSequence, maxNumAlpha, maxPathList, maxSequenceList):
		'''
			Finds the path from node to dst that has the most unique letters 
			 @PARAM: node           - Source node 
			 @PARAM: dst            - Destination node
			 @PARAM: marked         - Nodes that have been searched through already
			 @PARAM: path           - Current path of the search
			 @PARAM: pathSequence   - The sequence of the current path
			 @PARAM: maxNumAlpha    - The number of most uniqueletters found so far 
			 @PARAM: maxPathList    - The nodes currently found with the maxNumAlpha
			 @PARAM: maxSequenceList- The sequence of the maxPathList
			 @RETURN List of the datapaths from node to dst with the most unique letters
		'''
		if node == dst:
			path.append(node);
			letter = self.extractSequenceLetter(node);
			pathSequence.append(letter)
			numAlphabet = self.numAlpha(pathSequence);
			if numAlphabet > maxNumAlpha:
				maxPathList[:] = [];
				maxSequenceList[:] = [];
				maxNumAlpha = numAlphabet
			if numAlphabet >= maxNumAlpha:
				newPath = copy.deepcopy(path);
				maxPathList.append(newPath);
				maxSequenceList.append(copy.deepcopy(pathSequence));
				
			path.pop(len(path)-1);
			pathSequence.pop(len(pathSequence)-1);
			return maxNumAlpha;

		letter = self.extractSequenceLetter(node);
		path.append(node);
		pathSequence.append(letter)
		marked.add(node);	

		succList = self.dfg.successors(node);
		for succ in succList:
			if succ not in marked:
				maxNumAlpha= self.findMaxAlphaPath(succ, dst,  marked, path, pathSequence, maxNumAlpha, maxPathList, maxSequenceList);
			else:
				i = 0;
				for mp in maxSequenceList:
					try:
						index = maxPathList[i].index(succ);

						tmpPathSequence = pathSequence + mp[index:];
						numAlphabet = self.numAlpha(tmpPathSequence);
						tmpPath = path + maxPathList[i][index:]
						
						if numAlphabet > maxNumAlpha:
							maxPathList[:] = [];
							maxSequenceList[:] = [];
							maxNumAlpha = numAlphabet

						if numAlphabet >= maxNumAlpha:
							maxPathList.append(tmpPath);
							maxSequenceList.append(tmpPathSequence);
							break;
					except ValueError:
						continue;
					finally:
						i=i+1;
					
		pathSequence.pop(len(pathSequence)-1);
		path.pop(len(path)-1);
		return maxNumAlpha



	def findMaxPath(self, node, dst, marked, path, maxLen, maxPathList):
		'''
			Finds the path from node to dst that has largest number of nodes 
			 @PARAM: node           - Source node 
			 @PARAM: dst            - Destination node
			 @PARAM: marked         - Nodes that have been searched through already
			 @PARAM: path           - Current path of the search
			 @PARAM: maxLen-          The length of max path currently found
			 @PARAM: maxPathList    - The nodes currently found with maxLen
			 @RETURN List of the datapaths who's path is maximum
		'''
		if node == dst:
			path.append(node);
			if len(path) > maxLen:
				maxPathList[:] = [];
				maxLen = len(path)
			if len(path) >= maxLen:
				newPath = copy.deepcopy(path);
				maxPathList.append(newPath);
				
			path.pop(len(path)-1);
			return maxLen;

		path.append(node);
		marked.add(node);	
		succList = self.dfg.successors(node);
		for succ in succList:
			if succ not in marked:
				maxLen = self.findMaxPath(succ, dst,  marked, path, maxLen, maxPathList);
			else:
				for mp in maxPathList:
					try:
						index = mp.index(succ);
						newLen = len(path) + len(mp) - index
						
						if newLen > maxLen:
							maxPathList[:] = [];
							maxLen = newLen 
						if newLen >= maxLen:
							tempPath = path + mp[index:]
							maxPathList.append(tempPath);
							break;
					except ValueError:
						continue;
					
		path.pop(len(path)-1);
		return maxLen



	def findMinPath(self, node, dst, marked, path, minLen, maxPathList):
		'''
			Finds the path from node to dst that has smallest number of nodes 
			 @PARAM: node           - Source node 
			 @PARAM: dst            - Destination node
			 @PARAM: marked         - Nodes that have been searched through already
			 @PARAM: path           - Current path of the search
			 @PARAM: minLen-          The length of min path currently found
			 @PARAM: maxPathList    - The nodes currently found with the minLen
			 @RETURN List of the datapaths from node to dst who's path is minimum
		'''
		if node == dst:
			newLen = len(path) + 1;
			if newLen  <= minLen:
				if newLen < minLen:
					maxPathList[:] = [];
					minLen = newLen 
				newPath = path + [node];
				maxPathList.append(newPath);
				
			return minLen;

		path.append(node);
		marked.add(node);	
		succList = self.dfg.successors(node);
		for succ in succList:
			if succ not in marked:
				minLen = self.findMinPath(succ, dst,  marked, path, minLen, maxPathList);
			else:
				for mp in maxPathList:
					try:
						index = mp.index(succ);
						newLen = len(path) + len(mp) - index
						
						if newLen <= minLen:
							if newLen < minLen:
								minLen = newLen
								maxPathList[:] = [];
							tempPath = path + mp[index:]
							maxPathList.append(tempPath);
							break;
					except ValueError:
						continue;
					
		del path[-1];
		return minLen




















	def extractStructural(self):
		'''
		 Extracts the structural component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. Part of the structural fingerprint is 
				Handled in the functional extraction (OUT)
		'''

		# Preprocess nodes
		
		self.outNodeList= [];
		self.inNodeList= [];
		ffList = [];
		multList = [];
		totalFanin = 0;
		totalFanout = 0;
		maxFanin = 0;
		maxFanout = 0;
		nodeCount = 0;

		for node in self.nodeList:
			if 'v' in node:                     # Check to see if it is a  constant
				self.constantList.append(node);
				continue;

			predList = self.dfg.predecessors(node);
			sucList = self.dfg.successors(node);
			totalFanin = totalFanin + len(predList)
			totalFanout = totalFanout + len(sucList)
			nodeCount = nodeCount + 1;

			if self.shapeAttr[node] == "octagon":  # Check to see if it is a port node
				if len(predList) == 0:
					self.inNodeList.append(node);
				else:
					self.outNodeList.append(node);


			if(len(predList) > maxFanin):
				maxFanin = len(predList)
			if(len(sucList) > maxFanout):
				maxFanout = len(sucList)

			#If it is a operational block
			if self.shapeAttr[node] != "point" and self.shapeAttr[node] != "diamond":   
				label = self.labelAttr[node];
				label = re.search('\\\\n(.*)\|', label);
		
				if label != None:
					operation = label.group(1);
					#labelAttr[node] = operation

					size = 0;
					for pred in predList:
						psize = int(self.edgeAttr[(pred, node)]);
						if(psize > size):
							size = psize;

					for succ in sucList:
						ssize = int(self.edgeAttr[(node, succ)]);
						if(ssize > size):
							size = ssize;

					if(size == 0):
						print "[WARNING] -- There is a size of zero. OPERATION: " + operation;
						print "IN:  " + repr(len(predList))
						print "OUT: " + repr(len(sucList))
						

					#Count the number of components
#TODO
					if any(s in operation for s in self.muxStr):
						self.inc("mux", size)
					elif any(s in operation for s in self.regStr):
						self.inc("reg", size)
						ffList.append(node);
					elif any(s in operation for s in self.addStr):
						self.inc("add", size)
					elif any(s in operation for s in self.logicStr):
						self.inc("log", size)
					elif any(s in operation for s in self.eqStr):
						self.inc("eq", size)
					elif any(s in operation for s in self.cmpStr):
						self.inc("cmp", size)
					elif any(s in operation for s in self.shiftStr):
						self.inc("sh", size)
					elif any(s in operation for s in self.multStr):
						self.inc("mul", size)
					elif any(s in operation for s in self.divStr):
						self.inc("div", size)
					elif any(s in operation for s in self.memStr):
						self.inc("mem", size)
					elif any(s in operation for s in self.macStr):
						print "[WARNING] -- There is a macc type node: " + operation
					elif any(s in operation for s in self.aluStr):
						print "[WARNING] -- There is an alu type node: " + operation
					elif any(s in operation for s in self.arithStr):
						print "[WARNING] -- There is an arithmetic type node: " + operation
					elif any(s in operation for s in self.lutStr):
						print "[WARNING] -- There is a lut node: " + operation
					else:
						self.inc("bb", size)

		avgFanin = totalFanin / nodeCount;	
		avgFanout = totalFanout / nodeCount;	

		#Need to wait till all the inputs have been found during node processing
		if (float(len(self.inNodeList) + len(self.constantList)) * 0.25 > len(ffList)) or len(ffList) == 1:
			for node in ffList:	
				count = 0;
				for inNode in self.inNodeList:
					if(nx.has_path(self.dfg, inNode, node)):
						count = count + 1;

				for inNode in self.constantList:
					if(nx.has_path(self.dfg, inNode, node)):
						count = count + 1;

				self.inc("ffC", count)
		else:
			inFanout = {};
			for inNode in self.inNodeList:
				fanout = nx.dfs_successors(self.dfg, inNode);
				inFanout[inNode] = fanout
			
			for inNode in self.constantList:
				fanout = nx.dfs_successors(self.dfg, inNode);
				inFanout[inNode] = fanout

			ffCounts = dict()	
			for n, fanout in inFanout.iteritems():
				ffNodes = [fanoutnode for fanoutnode in  fanout for ff in ffList if ff == fanoutnode]
				for ff in ffNodes:
					ffCounts[ff] = ffCounts.get(ff, 0) + 1;
			
			self.fpDict["ffC"] = Counter(ffCounts.values());

		print "[DFX] -- Extracting additional structural features..."
		#print "AVG MAXPATH LEN: " + repr(float(maxPathCount)/float(totalMaxPaths));
		#print "AVG MINPATH LEN: " + repr(float(minPathCount)/float(totalMinPaths));
		self.statstr = self.statstr + repr(len(self.nodeList)) + "," + repr(len(self.edgeList)) + ","
		self.statstr = self.statstr + repr(len(self.inNodeList)) + "," + repr(len(self.outNodeList)) + ","
		self.statstr = self.statstr + repr(maxFanin) + "," + repr(maxFanout) + ",";
		#statstr = statstr + repr(len(list(nx.simple_cycles(dfg)))) + ",";
		for freq in nx.degree_histogram(self.dfg):
			self.statstr = self.statstr + "," + repr(freq);
		#print "STAT: " + statstr



	def extractFunctional(self):
		'''
		 Extracts the functional component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. 
		'''
		print "[DFX] -- Extracting functional features..."# from : " + fileName;
		dataflowMaxList_node = [];
		dataflowMinList_node = [];

		self.maxList = set();
		self.alphaList = set();
		self.minList = set();
		totalMinPaths = 0;
		totalMaxPaths = 0;
		maxPathCount= 0;
		minPathCount= 0;

		maxNumAlpha = 0;
		pathHistory = [];

		for out in self.outNodeList:
			count = 0;
			for constant in self.constantList:
				if(nx.has_path(self.dfg, constant, out)):
					count = count + 1;

			for inNode in self.inNodeList:
				#Necessary for recursion
				marked = set();
				path= [];
				maxLen= 0;
				maxPathList= [];
				#print " -- Finding max paths"
				maxLen = self.findMaxPath(inNode, out, marked, path, maxLen, maxPathList);
				if(maxLen == 0):
					continue
				
				#print " -- Finding Max ALpha paths"
				marked = set();
				path= [];
				pathSequence= [];
				maxAlphaList= [];
				swAlpha = [];
				self.findMaxAlphaPath(inNode, out, marked, path, pathSequence,  0, maxAlphaList, swAlpha);
				
				#print " -- Finding shortest paths"
				marked = set();
				path= [];
				minPathList = []
				self.findMinPath(inNode, out, marked, path, maxLen+10, minPathList);

				#Extract the sequence representation, make sure to ignore representations that is already in maxList
				#print " -- Extracting Sequence"
				swMax = self.extractSWStringList(maxPathList, self.maxList);
				swMin = self.extractSWStringList(minPathList, self.minList);
				swAlpha = self.extractSWStringList(maxAlphaList, self.alphaList);

				#print " -- Finding Entropy"
				#Find the sequences with the highest entropy
				maxSequence = self.findMaxEntropy(swMax);
				minSequence = self.findMaxEntropy(swMin);
				alphaSequence = self.findMaxEntropy(swAlpha);
				nAlpha = self.numAlpha(alphaSequence);
				#print "NUMBER OF ALPHA: " + repr(nAlpha)

				#Store the highest entropy sequence
				if(maxSequence != ""):
					self.maxList.add(maxSequence);
					totalMaxPaths= totalMaxPaths + 1;
					maxPathCount= maxPathCount+ len(maxSequence);
				if(minSequence != ""):
					self.minList.add(minSequence);
					totalMinPaths= totalMinPaths + 1;
					minPathCount= minPathCount+ len(minSequence);
				if(alphaSequence != ""):
					if(nAlpha > maxNumAlpha):
						self.alphaList = set();
						maxNumAlpha = nAlpha
						self.alphaList.add(alphaSequence);
					elif(nAlpha == maxNumAlpha):
						self.alphaList.add(alphaSequence);

				count = count + 1;
				
			#Number of inputs the output depends on;
			self.inc("outC", count)
	
		# Extract the sequence 
		maxSeq = 3;
		swMax = list(self.maxList);
		swMax.sort(lambda x, y: -1*(cmp(len(x), len(y))));
		self.maxList = self.getTopSequence(maxSeq, swMax)
		#print "MAXLIST: " + repr(maxList);

		swMin = list(self.minList);
		swMin.sort(lambda x, y: -1*(cmp(len(x), len(y))));
		self.minList = self.getTopSequence(maxSeq, swMin)
		#print "MINLIST: " + repr(minList);
		
		swAlpha = list(self.alphaList);
		swAlpha.sort(lambda x, y: -1*(cmp(len(x), len(y))));
		self.alphaList= self.getTopSequence(maxSeq, swAlpha)
		print "ALPHALIST: " + repr(swAlpha);
		
		
		print "[DFX] -- Extracting additional functional features..."
		self.statstr = self.statstr + repr(float(maxPathCount)/float(totalMaxPaths)) + ',';
		self.statstr = self.statstr + repr(float(minPathCount)/float(totalMinPaths));





	def extractConstant(self):
		'''
		 Extracts the constant component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. 
		'''
		print "[DFX] -- Extracting constant features..."

		self.constSet = set();
		constStr = "";
		for constant in self.constantList:
			cnstVal = self.labelAttr[constant];
			cnstVal = re.search('\'(.*)', cnstVal);
			if(cnstVal == None):
				cnstVal = self.labelAttr[constant];
				cnstVal = cnstVal.replace("L","")
				if(len(cnstVal) > 19):
					cnstVal = "9999999999999999";
				self.constSet.add(cnstVal);

				if(cnstVal == "0"):
					cnstVal = "-1"
				constStr = constStr + cnstVal+ ",";

			else:
				cnstVal = cnstVal.group(1);
				if('x' in cnstVal):   #DON'T CARE
					cnstVal = "-2";
				elif('z' in cnstVal): #HIGH IMPEDANCE
					cnstVal = "-3";
				else:
					cnstVal = repr(int(cnstVal, 2));
					cnstVal.replace("L", "")
					if(len(cnstVal) > 19):
						cnstVal = "9999999999999999";

				self.constSet.add(cnstVal);

				if(cnstVal == "0"):
					cnstVal = "-1"

				constStr = constStr + cnstVal + ",";


	def getBirthmark(self):
		'''
		 Returns the data for the birthmark
		'''
		self.extractStructural();
		self.extractFunctional();
		self.extractConstant();
		return (self.maxList, self.minList, self.constSet, self.fpDict, self.statstr, self.alphaList);

