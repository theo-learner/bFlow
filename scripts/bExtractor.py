#!/usr/bin/python2.7

'''
Birthmark Extractor module
  Object that contains methods to extract birthmarks from the dataflow
  Features it looks for currently:
    Functional Datapaths MAX, MIN, Most unique operation path
    Structural component enumeration and statistics
    Constant enumeration
    Path-based n-gram search
'''

import networkx as nx;
import sys, traceback;
import re;
import copy;
import error;
import timeit
import time;
from collections import Counter
#from frozendict import FrozenDict 
import yosys;
import math

class BirthmarkExtractor(object):

  def __init__(self, dotFile, strictFlag=False):
    '''
     Constructor	
       Initializes and reads in the circuit
       Initializes most of the private variables and settings 
    '''
    self.strictFlag = strictFlag;
    if(self.strictFlag):
      print " - Strict processing: ON"
    else:
      print " - Strict processing: OFF"
    self.dfg = nx.DiGraph(nx.read_dot(dotFile));
    print "DOT FILE: " +  dotFile;

    #Get the nodes and edges of the graph
    self.nodeList = self.dfg.nodes();
    self.edgeList = self.dfg.edges();

    # Get the shape and label attributes
    self.shapeAttr = nx.get_node_attributes(self.dfg, 'shape');
    self.labelAttr = nx.get_node_attributes(self.dfg, 'label');

    # Preprocess edges 
    #self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');

    self.alpha_map = dict();

    name = ["+", "*", "/", "S", "M", "L", "=", "C", "F", "R", "N", "!", "H"];

    if(not self.strictFlag):
      self.alpha_map["$logic_not"] = "L";
      self.alpha_map["$logic_and"] = "L";
      self.alpha_map["$logic_or"] = "L";
      self.alpha_map["$and"] = "L";
      self.alpha_map["$or"] = "L";
      self.alpha_map["$not"] = "L";
      self.alpha_map["$xor"] = "L";
      self.alpha_map["$xnor"] = "L";
      self.alpha_map["$reduce_and"] = "L";
      self.alpha_map["$reduce_or"] = "L";
      self.alpha_map["$reduce_xor"] = "L";
      self.alpha_map["$reduce_xnor"] = "L";
      self.alpha_map["$reduce_bool"] = "L";

      self.alpha_map["$shl"] = "S";
      self.alpha_map["$sshl"] = "S";
      self.alpha_map["$shr"] = "S";
      self.alpha_map["$sshr"] = "S";
      self.alpha_map["$shift"] = "S";
      self.alpha_map["$shiftx"] = "S";

      self.alpha_map["$lt"] = "C";
      self.alpha_map["$le"] = "C";
      self.alpha_map["$ge"] = "C";
      self.alpha_map["$gt"] = "C";

      self.alpha_map["$add"] = "+";
      self.alpha_map["$sub"] = "+";

      self.alpha_map["$eq"] = "=";
      self.alpha_map["$eqx"] = "=";
      self.alpha_map["$ne"] = "=";
      self.alpha_map["$nex"] = "=";

      self.alpha_map["$ne"] = "!";
      self.alpha_map["$neq"] = "!";

      self.alpha_map["$mux"] = "M";
      self.alpha_map["$pmux"] = "M";

    else:
      self.alpha_map["$logic_not"] = "L";
      self.alpha_map["$logic_and"] = "L";
      self.alpha_map["$logic_or"] = "L";

      self.alpha_map["$and"] = "D";

      self.alpha_map["$or"] = "|";

      self.alpha_map["$not"] = "~";

      self.alpha_map["$xor"] = "^";
      self.alpha_map["$xnor"] = "^";

      self.alpha_map["$reduce_and"] = "B";
      self.alpha_map["$reduce_or"] = "B";
      self.alpha_map["$reduce_xor"] = "B";
      self.alpha_map["$reduce_xnor"] = "B";
      self.alpha_map["$reduce_bool"] = "B";

      self.alpha_map["$shl"] = "(";
      self.alpha_map["$sshl"] = "(";

      self.alpha_map["$shr"] = ")";
      self.alpha_map["$sshr"] = ")";
      
      self.alpha_map["$shift"] = "S";
      self.alpha_map["$shiftx"] = "S";

      self.alpha_map["$lt"] = "{";
      self.alpha_map["$le"] = "{";

      self.alpha_map["$ge"] = "}";
      self.alpha_map["$gt"] = "}";

      self.alpha_map["$eq"] = "=";
      self.alpha_map["$eqx"] = "=";

      self.alpha_map["$ne"] = "!";
      self.alpha_map["$nex"] = "!";

      self.alpha_map["$add"] = "+";
      self.alpha_map["$sub"] = "-";

      self.alpha_map["$mux"] = "M";
      self.alpha_map["$pmux"] = "P";

      name = ["+", "-", "*", "/", "S","P", "M", "L", "=", "F", "R", ")", "(", "D", "|", "~", "^", "}", "{", "!", "-", "B", "N", "H"];

    self.alpha_map["$dff"] = "F";
    self.alpha_map["$dffe"] = "F";
    self.alpha_map["$adff"] = "F";
    self.alpha_map["$sr"] = "F";
    self.alpha_map["$dffsr"] = "F";
    self.alpha_map["$dlatch"] = "F";
    self.alpha_map["$dlatchsr"] = "F";

    self.alpha_map["$pos"] = "N";
    self.alpha_map["$slice"] = "N";
    self.alpha_map["$concat"] = "N";
    self.alpha_map["$neg"] = "N";

    self.alpha_map["$fa"] = "H";
    self.alpha_map["$lcu"] = "H";
    self.alpha_map["$pow"] = "H";

    self.alpha_map["$alu"] = "A";

    self.alpha_map["$macc"] = "W";
    self.alpha_map["$alumacc"] = "W";

    self.alpha_map["$mul"] = "*";
    self.alpha_map["$div"] = "/";
    self.alpha_map["$mod"] = "/";

    self.alpha_map["$lut"] = "T";
    self.alpha_map["$mem"] = "R";
    
    self.fpDict = {}

    for n in name:
      self.fpDict[n]=0;

    self.statstr = "";
    self.statstrf = "";

    self.constantList= set();
    self.outNodeList= [];
    self.inNodeList= [];
    self.cnodes = []
    self.addlist = []
    self.linenumber= dict()
    self.commutative = False;





  def KGram2(self, k):
    '''
      Searches and extracts the kgrams from the dot file	
       @PARAM: k - Length of the kgram
    '''
    start_time = timeit.default_timer();
    print " -- Extracting KGRAM k length from nodes (NODES: " + repr(len(self.cnodes)) + ", EDGES: "+repr(len(self.edgeList)) + ")";
    self.kgramlist= Counter();
    self.kgram= set();
    self.kgramline = dict(); #tuple(Sequence letters)...list of list of line numbers associated with the tuple 

    #self.kgramcountertuple= Counter();
    self.k = k;

    for c in self.cnodes:
      #print "\n\nChecking node: " + c
      path = [];
      self.markflag = 0;
      marked = set();
      commutative_paths = []
      self.addTree = False;  #Flag to mark if the current traversal is in a addtree
      self.findKGramPath(c ,  marked,  path, commutative_paths);
      #print

    #for k, v in self.kgramlist.iteritems() :
    #	self.kgramset[frozenset(k)] += v;
    #	self.kgramcounter[FrozenDict(Counter(k))] += v;
      
    elapsed = timeit.default_timer() - start_time;
    return elapsed;
    


  def reorder_path_commutative(self, path, node):
    '''
      reorder_path_commutative
        Reorders a sequence of operations that are commutative 
        ie. +-+- ->  ++--
    '''

    operation = self.extractSequenceLetter(node);
    found = False;

    if(operation == '+'):
      secondary = '_';
    elif(operation == '*'):
      secondary = '/';
    elif(operation == '('):
      secondary = ')';
    else:
      return;
      
    secondaryExists= False;
    for i in xrange(len(path)-2, -1, -1):
      op2 = self.extractSequenceLetter(path[i]);
      if op2 != secondary:

        #Check to see if there is a need to reorder the +
        if(not secondaryExists):
          return;

        path.insert(i+1, node)
        del path[-1];
        found = True;
        break;
      else:
        secondaryExists = True;
        
    if not found:
      path.insert(0, node)
      del path[-1];
    



  def addUniquePath(self, path, pathList):
    '''
      addUniquePath
        Adds a unique path into the list if the sequence does not exist
    '''
    found = set();
    pathToAdd = tuple(self.extractSequenceLetter(n) for n in path)

    for p in pathList:
      pathItem = tuple(self.extractSequenceLetter(n) for n in p)
      if(pathToAdd == pathItem):
        return;

    pathList.append(copy.deepcopy(path));



  def commutative_search(self, function, node, path, marked, commutative_paths, cinputs):
    '''
      commutative_search	
        Searches neighbor nodes for possible commutative paths
    '''

    marked.add(node)
    appended = False

    if "c" in node:
      operation = self.extractSequenceLetter(node);

      if (operation == '_' or operation == '+') and function == "+-":
        pathlen = len(path)
        appended = True;
        path.append(node);
        self.reorder_path_commutative(path, node);

        '''
        print " NEW CPATH: " + repr(path);
        sw= [self.extractSequenceLetter(n) for n in path]
        sw = "".join(sw)
        print sw;
        '''
        commutative_paths.append(copy.deepcopy(path));
        #self.addUniquePath(path, commutative_paths);
        
      else: 
        cinputs.append(node)
        return ;  #node function is not of commutative type
        

      if(pathlen <= self.k ):
        slist = self.extractSequencePath(path);
        #self.kgramline.setdefault(slist, set()).add(tuple(self.linenumber.get(n,"-1") for n in path));
        self.kgramlist[slist] += 1;

        if pathlen == self.k:
          del path[-1];
          marked.remove(node)
          return ;


    predList = self.dfg.predecessors(node);
    for pred in predList:
      if pred not in marked:
        self.commutative_search(function, pred, path, marked, commutative_paths, cinputs)

    # Check the successor too
    succList = self.dfg.successors(node);
    
    if appended == True:
      del path[-1];
      
    marked.remove(node)
        

  def findKGramPath(self, node, marked,  path, commutative_paths): 
    '''
      find the path for the specific kgrams
       @PARAM: node  : Starting node in the path
       @PARAM: makred: List of nodes that are already traversed
       @PARAM: path  : Current path for the kgram 
    '''
    #print "Checking node: " + node +  "\t" + repr(path)
    marked.add(node)
    appended = False

    #Record nodes that aren't wires, splices, constants, or ports
    if "c" in node:
      appended = True;
      path.append(node);

      #Record the current gram if len is greater than k
      pathlen = len(path)
      #if(pathlen <= self.k and pathlen > 1):
      if(pathlen <= self.k ):

        ## COMMUTATIVE SEARCH #####################################################
        if self.commutative:
          operation = self.extractSequenceLetter(node);

          self.reorder_path_commutative(path, node);
          '''
          print " NEW PATH: " + repr(path);
          sw= [self.extractSequenceLetter(n) for n in path]
          sw = "".join(sw)
          print sw;
          '''

          if(len(commutative_paths) > 0):
            for cpath in commutative_paths:
              cpath.append(node);
              if(len(cpath) <= self.k ):
                self.reorder_path_commutative(cpath, node);
                cslist = tuple(self.extractSequenceLetter(n) for n in cpath)
                #self.kgramline.setdefault(cslist, set()).add(tuple(self.linenumber.get(n,"-1") for n in cpath));
                self.kgramlist[cslist] += 1;
                '''
                print " NEW ECPATH: " + repr(cpath);
                sw= [self.extractSequenceLetter(n) for n in cpath]
                sw = "".join(sw)
                print sw;
                '''

          #Previous search through
          #check to see if the operation is + or -
          if(operation == '_' or operation == '+'):
            function = "+-"

            #get the other children node that is not marked
            predList = self.dfg.predecessors(node);
            cmark = set();
            cinput = [];
            cpaths = [];
            for pred in predList:
              if pred not in marked:
                self.commutative_search(function, pred, copy.deepcopy(path), cmark, cpaths, cinput)

            if(len(cpaths) > 0):
              for i in cinput:
                commutative_paths.append([i, node]);
              for cpath in cpaths:
                for i in cinput:
                  commutative_paths.append([i]+cpath);
              commutative_paths = commutative_paths + cpaths;

              #print commutative_paths;

        ## COMMUTATIVE SEARCH #####################################################


        slist = self.extractSequencePath(path);
        #self.kgramline.setdefault(slist, set()).add(tuple(self.linenumber.get(n,"-1") for n in path));
        self.kgramlist[slist] += 1;
        
        if pathlen == self.k:
          for cpath in commutative_paths:
            if(len(cpath) > 0):
              del cpath[-1];
          del path[-1];
          marked.remove(node)
          return


    succList = self.dfg.successors(node);
    for succ in succList:
      if succ not in marked:
        self.findKGramPath(succ, marked , path, commutative_paths);
      #else:
      #	print succ + " is marked..."

    #Pop only if node was inserted into path
    #if not any(s in node for s in ['n', 'x', 'v']):
    if appended == True:
      del path[-1];
      for cpath in commutative_paths:
        if(len(cpath) > 0):
          del cpath[-1];
      #print " POP"
      
    marked.remove(node)



  def findKGramPath_Backwards(self, node, marked,  path): 
    #print "Checking node: " + node +  "\t" + repr(path)

    marked.add(node)

    #Record nodes that aren't wires, splices, constants, or ports
    if "c" in node:
      path.append(node);

      #Record the current gram if len is greater than k
      pathlen = len(path)
      #if(pathlen <= self.k and pathlen > 1):
      if(pathlen <= self.k):
        #slist = [self.extractSequenceLetter(n) for n in path[len(path)-self.k:]]

        #Reverse the path since traversal is backwards
        reversePath = list(reversed(path));
        #slist = tuple(self.extractSequenceLetter(n) for n in reversePath)
        self.endGramLine.setdefault(slist, set()).add(tuple(self.linenumber.get(n,"-1") for n in reversePath));
        self.endGramList.add(slist);
      
        #print " NEW PATH: " + repr(path) + "  " + repr(slist);

        if pathlen == self.k:
          #print " POP"
          del path[-1];
          return

        
    predList= self.dfg.predecessors(node);
    for pred in predList:
      if pred not in marked:
        self.findKGramPath_Backwards(pred, marked , path);
      #else:
      #	print succ + " is marked..."



    #Pop only if node was inserted into path
    if "c" in node:
      del path[-1];
      #print " POP"
    marked.remove(node)




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
    if 'c' in node: # Check to see if node is splice, const, port
      operation = self.labelAttr[node]
      if operation in self.alpha_map:
        return self.alpha_map[operation];
      else:
        raise error.GenError("NO KNOWN OPERATION SL: " + node + ", OP: " + operation);
    else:
      return "";

  
  
  def extractSequencePath(self, path):
    '''
      Maps the operation of the function to a letter
       @PARAM: node     - The node to assign a letter to
       @RETURN Letter of the function
    '''
    tup = [];
    for node in path:
      operation = self.labelAttr[node]
      if operation in self.alpha_map:
        tup.append(self.alpha_map[operation])
      else:
        raise error.GenError("NO KNOWN OPERATION SP: " + node + ", OP: " + operation);
    return tuple(tup)


    



  def extractSWStringList(self, dataflowList_node, foundList):
    '''
      Converts a list of datapaths into their sequences
       @PARAM: dataflowList_node- List of datapaths 
       @PARAM: foundList -        List of nodes already found. Omit them
       @RETURN Converted list of sequences
    '''
    swList = set();
    for dataflow_node in dataflowList_node:
      slist = [self.extractSequenceLetter(dataflow_node[index+1]) for index in xrange(len(dataflow_node)-2)];
      sw = "".join(slist)

      if(sw in foundList):
        continue;
      swList.add(sw);

    return swList;



    
  def findPath(self, node, dst, marked, path, simpPath, pathSequence, length, pathList, sequenceList):
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
    marked.add(node);	

    #print "Checking node: " + node + ". DST: " + dst
    if node == dst:
      #print " * Node is dst!"
      newLen = len(path) + 1;

      #Max
      newPath = path + [node];
      if newLen  >= (length[0]):
        if newLen > length[0]:
          pathList[0][:] = [];
          length[0] = newLen 
        pathList[0].append(newPath);
      #Min
      if newLen  <= length[1]:
        if newLen <  length[1]:
          pathList[1][:] = [];
          length[1] = newLen 
        pathList[1].append(newPath);
      #Alpha
      numAlphabet = len(set(pathSequence))
      if numAlphabet >= length[2]:
        newLen = len(simpPath) + 1;
        if numAlphabet > length[2]:
          pathList[2][:] = [];
          sequenceList[:] = [];
          length[2] = numAlphabet
          length[3] = newLen 
        elif newLen > length[3]:
          pathList[2][:] = [];
          sequenceList[:] = [];
          length[3] = newLen 

        newPathSequence = copy.deepcopy(pathSequence)
        newPath = simpPath + [node];
        pathList[2].append(newPath);
        sequenceList.append(newPathSequence);
      
      return length;


    letter = self.extractSequenceLetter(node);
    if(letter != ""):
      pathSequence.append(letter)
      simpPath.append(node)

    path.append(node);
    succList = self.dfg.successors(node);

    for succ in succList:
      #print succ
      if succ not in marked:
        length = self.findPath(succ, dst,  marked, path, simpPath, pathSequence, length, pathList, sequenceList);
      else:
        #MAX
        for mp in pathList[0]:
          try:
            index = mp.index(succ);
            newLen = len(path) + len(mp) - index
            
            if newLen >= length[0]:
              if newLen > length[0]:
                length[0] = newLen
                pathList[0][:] = [];
              tempPath = path + mp[index:]
              pathList[0].append(tempPath);
              break;
          except ValueError:
            continue;
        
        #MIN
        for mp in pathList[1]:
          try:
            index = mp.index(succ);
            newLen = len(path) + len(mp) - index
            
            if newLen <= length[1]:
              if newLen < length[1]:
                length[1] = newLen
                pathList[1][:] = [];
              tempPath = path + mp[index:]
              pathList[1].append(tempPath);
              break;
          except ValueError:
            continue;

        #ALPHA
        i = 0;
        for mp in sequenceList:
          try:
            index = pathList[2][i].index(succ);

            tmpPathSequence = pathSequence + mp[index:];
            numAlphabet = len(set(tmpPathSequence))
            newLen = len(simpPath) + len(mp) - index
            tmpPath = simpPath + pathList[2][i][index:]

            if numAlphabet >= length[2]:
              if numAlphabet > length[2]:
                pathList[2][:] = [];
                length[2] = numAlphabet
                length[3] = newLen 
                sequenceList[:] = [];
              elif newLen > length[3]:
                pathList[2][:] = [];
                sequenceList[:] = [];
                length[3] = newLen 

              pathList[2].append(tmpPath);
              sequenceList.append(tmpPathSequence);
              break;
            
          except ValueError:
            continue;
          finally:
            i=i+1;




    del path[-1];
    if(letter != ""):
      del pathSequence[-1];
      del simpPath[-1];
    return length






  def faninCone(self, node, marked):
    marked.add(node);	
    predList = self.dfg.predecessors(node);
    for pred in predList:
      if pred not in marked:
        self.faninCone(pred,  marked);



  def expand_add_tree(self, node):
    '''
      Some basic functionality may be lost when expanding
      Ports of subtraction is not known since port information
      is not read in by networkx
    '''
    #print "EXPANDING TREE: "+ node
    if "c" in node:
      operation = self.extractSequenceLetter(node);
      if operation in ["+", "_"] :
        #print "Found adder"
        predList = self.dfg.predecessors(node);
        #print "Possible expansion: " + repr(predList);
        if(len(predList) < 2):
          return;

        op1 = self.extractSequenceLetter(predList[0]);
        op2 = self.extractSequenceLetter(predList[1]);
        #print "OP1: " + op1 + " OP2: " + op2
        while(op1 in ["+", "_"] and op2 in ["+", "_"]):
          #print "Possible expansion: " + repr(predList);
          predList_1 = self.dfg.predecessors(predList[1]);

          """
          edgelabel = "<1>";
          try:
            edgelabel = self.edgeAttr[(predList[0],node)];
          except:
            pass;
          """

          self.dfg.remove_edge(predList[0], node);
          self.dfg.add_edge(predList[0], predList[1]);
          #self.dfg[predList[0]][predList[1]]['label'] = edgelabel;


          """
          edgelabel = "<1>";
          try:
            edgelabel = self.edgeAttr[(predList_1[0], predList[1])];
          except:
            pass;
          """

          self.dfg.remove_edge(predList_1[0], predList[1]);
          self.dfg.add_edge(predList_1[0], node);
          #self.dfg[predList_1[0]][node]['label'] = edgelabel;

          predList[0] = predList[1]
          predList[1] =  predList_1[0];
          op1 = self.extractSequenceLetter(predList[0]);
          op2 = self.extractSequenceLetter(predList[1]);
          #print "OP1: " + op1 + " OP2: " + op2
          #print predList

      else:
        return;
          

    predList = self.dfg.predecessors(node);
    for pred in predList:
      self.expand_add_tree(pred);

          


      #else operation == "_":

    

  def extractStructural(self):
    '''
     Extracts the structural component of the circuit	
        Note that all three extractions (Structural, Functional, Constant)
        Needs to be called. Part of the structural fingerprint is 
        Handled in the functional extraction (OUT)
    '''
    start_time = timeit.default_timer();

    print " -- Extracting structural features..."# from : " + fileName;
    # Preprocess nodes
    
    #ffList = [];
    multList = [];
    totalFanin = 0;
    totalFanout = 0;
    maxFanin = 0;
    maxFanout = 0;
    nodeCount = 0;
    removeConst = []
    remove_not = []

    #start_time = timeit.default_timer();
    #for node in self.nodeList:


    # Loop through each node
    for i in xrange(len(self.nodeList) -1 , -1, -1):
      node = self.nodeList[i] 


      # Check if node is constant
      if 'v' in node:                
        if(node in self.labelAttr):
          #print "ADDING CONSTANT: " + node;
          cnstVal = self.labelAttr[node]
          self.constantList.add(node);
          continue;


      # Basic Statistics
      predList = self.dfg.predecessors(node);
      sucList = self.dfg.successors(node);

      totalFanin = totalFanin + len(predList)
      totalFanout = totalFanout + len(sucList)

      nodeCount = nodeCount + 1;
      if(len(predList) > maxFanin):
        maxFanin = len(predList)
      if(len(sucList) > maxFanout):
        maxFanout = len(sucList)
      

      # Keep track of nodes that have no successor 
      #if(len(sucList) == 0):
        #self.endSet.add(node);


      # Check if node is port
      if self.shapeAttr[node] == "octagon": 
        if len(predList) == 0:
          self.inNodeList.append(node);
        else:
          self.outNodeList.append(node);
        continue; 
      elif self.shapeAttr[node] == "diamond": 
        continue;

        '''
        successorList = self.dfg.successors(node);
        predecessorList = self.dfg.predecessors(node);

        if(len(predecessorList) == 0 ):
          #self.dfg.remove_node(node);
          #self.nodeList.remove(node);
          continue;

        elif(len(predecessorList) ==  1):
          start = predecessorList[0];

          #Get the size of the edge going in
          try:
            edgelabel = self.edgeAttr[(start,node)];
            edgelabel = re.search('<(.*)>', edgelabel);
            size = int(edgelabel.group(1));
          except:
            size = 1;

          #print "REMOVING INVERTER CHAIN " + pred + " " + node
          self.dfg.remove_node(node);
          self.nodeList.remove(node);

          for end in successorList:
            self.dfg.add_edge(start, end);
            self.dfg[start][end]['label'] = "<" + repr(size) + ">";

          #Update Edge Attributes edges 
          self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
          continue;
                                        '''



      # Check if node is a primitive operation
      if 'c' not in node:   
        continue;

      
      optimized = False
      label = self.labelAttr[node];
      linenum =  re.search('!(.*)!', label);
      label = re.search('\+(.*)\+', label);
      if label == None:
        raise error.GenError("NO LABEL FOR CNODE: " + node + "\n");


      operation = label.group(1);

      """
      #Get the size of the input bus
      size = 0;
      for pred in predList:
        if (pred,node) not in self.edgeAttr:
          psize = 1;
        else:
          label = self.edgeAttr[(pred,node)];
          label = re.search('<(.*)>', label);
          psize = int(label.group(1));

        if(psize > size):
          size = psize;
      """
      
      #######################################
      #Structural optimizations
      opt_operation = -1;
      if operation == "$not":

        if(len(predList) !=  1):
          raise error.GenError("Inverter block has more than one predecessor" + node + "\n");

        pred = predList[0];

        if pred  in self.labelAttr:
          pred_operation_full = self.labelAttr[pred];
          pred_operation = re.search('\+(.*)\+', pred_operation_full);
          prevnot = False;
          if pred_operation != None:
            if pred_operation.group(1) == "$not" :
              prevnot = True;	
          elif pred_operation_full == "$not":
            prevnot = True;	

            #Compress and remove redundant inverter chains
          if prevnot:
            successorList = self.dfg.successors(node);
            predecessorList = self.dfg.predecessors(pred);
            
            start = predecessorList[0];

            """
            #Get the size of the edge going in
            edgelabel = "<1>";
            try:
              edgelabel = self.edgeAttr[(start,pred)];
              edgelabel = re.search('<(.*)>', edgelabel);
            except:
              pass;

            #print "REMOVING INVERTER CHAIN " + pred + " " + node
            """
            self.dfg.remove_node(node);
            self.dfg.remove_node(pred);
            self.nodeList.remove(pred);
            self.nodeList.remove(node);
            remove_not.append(pred)


            for end in successorList:
              self.dfg.add_edge(start, end);
              #self.dfg[start][end]['label'] = "<" + repr(size) + ">";

            #Update Edge Attributes edges 
            #self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
            continue;
        
      #Remove 0 addtion identities
      elif operation in ["$add", "$sub", "$or", "$shl", "$shr", "$shift"]:
        opt_operation = 0  #Identity is if 0 is a constant in one of the inputs
      elif operation in ["$and", "$mul"]:
        opt_operation = 1;

      if(opt_operation != -1):
        predecessorList = self.dfg.predecessors(node);
        if(len(predecessorList) == 2):
          mark = 1;  #keeps track of the other index;

          # Look for constant 0
          for pred in predecessorList:
            if('v' in pred):
              cnstlabel = self.labelAttr[pred]
              cnstVal = re.search('\'(.*)', cnstlabel);

              #No bit marking notation
              if(cnstVal == None):
                cnstVal = cnstlabel;
                cnstVal = cnstVal.replace("L","")
                cnstVal = int(cnstVal);

              else:
                cnstVal = cnstVal.group(1);
                if('x' not in cnstVal and 'z' not in cnstVal): #no X or Z
                  cnstVal = int(cnstVal, 2)
                else:
                  continue;

              #print "NODE: " + node+ " OP: " + operation + " CONST: "  + repr(cnstVal);

              if(cnstVal == opt_operation):
                #print "REMOVING CONST: " + pred
                successorList = self.dfg.successors(node);
                self.dfg.remove_node(node);
                self.dfg.remove_node(pred);
                self.nodeList.remove(pred);
                self.nodeList.remove(node);
                removeConst.append(pred)

                for end in successorList:
                  self.dfg.add_edge(predecessorList[mark], end);
                  #self.dfg[predecessorList[mark]][end]['label'] = "<" + repr(size) + ">";
                #Update Edge Attributes edges 
                #self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
                optimized = True;
                break;
            
            mark = mark - 1;

          if optimized:
            continue;
      #######################################

      if(operation in ["$add", "$sub"]):
        self.addlist.append(node)

      self.cnodes.append(node);
      self.dfg.node[node]['label'] = operation;

      #Is there an associated line number?
      if linenum != None:
        self.linenumber[node] = linenum.group(1);


      if operation in self.alpha_map:
        self.fpDict[self.alpha_map[operation]] = self.fpDict[self.alpha_map[operation]] + 1;
      else:
        raise error.GenError("NO KNOWN OPERATION ES: " + node + ", OP: " + operation);
              

    #Remove deleted constants
    for rconst in removeConst:
      try:
        self.constantList.remove(rconst);
        #print "REMOVING CONSTANT: " + rconst;
      except:
        pass;

    #Remove deleted not	
    for n in remove_not:
      try:
        self.cnodes.remove(n);
      except:
        pass;

    avgFanin = totalFanin / nodeCount;	
    avgFanout = totalFanout / nodeCount;	
    #elapsed = timeit.default_timer() - start_time;
    #print "[PNODE] -- ELAPSED: " +  repr(elapsed) 

    #Need to wait till all the inputs have been found during node processing
    #start_time = timeit.default_timer();
    '''
    inputs = self.inNodeList + self.constantList
    ffDict = dict();
    for node in ffList:	
      marked = set();
      self.faninCone(node, marked)
      intoFF = [i for i in inputs if i in marked ]
      count = len(intoFF)

      ffDict[count] = ffDict.get(count, 0) + 1;
    
    self.fpDict["ffC"] = ffDict;

    #elapsed = timeit.default_timer() - start_time;
    #print "[FF]    -- ELAPSED: " +  repr(elapsed)
    '''


    #print "[DFX] -- Extracting additional structural features..."
    #print "AVG MAXPATH LEN: " + repr(float(maxPathCount)/float(totalMaxPaths));
    #print "AVG MINPATH LEN: " + repr(float(minPathCount)/float(totalMinPaths));
    #self.statstr = self.statstr + repr(len(self.nodeList)) + "," + repr(len(self.edgeList)) + ","
    #self.statstr = self.statstr + repr(len(self.inNodeList)) + "," + repr(len(self.outNodeList)) + ","
    #self.statstr = self.statstr + repr(maxFanin) + "," + repr(maxFanout) + ",";

    self.statstr = "%s,%s,%s,%s,%s,%s," % (repr(len(self.nodeList)), repr(len(self.edgeList)), repr(len(self.inNodeList)), repr(len(self.outNodeList)), repr(maxFanin), repr(maxFanout));
    #statstr = statstr + repr(len(list(nx.simple_cycles(dfg)))) + ",";
    #for freq in nx.degree_histogram(self.dfg):
    #	self.statstr = self.statstr + "," + repr(freq);

    slist = [repr(freq) for freq in nx.degree_histogram(self.dfg)];
    s = ",".join(slist)
    self.statstr = "%s,%s," % (self.statstr, s);
    #print "STAT: " + statstr

    #Update!
    #Get the nodes and edges of the graph
    self.nodeList = self.dfg.nodes();
    self.edgeList = self.dfg.edges();

    # Get the shape and label attributes
    self.shapeAttr = nx.get_node_attributes(self.dfg, 'shape');
    self.labelAttr = nx.get_node_attributes(self.dfg, 'label');

    # Preprocess edges 
    #self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
    self.nodeList = self.dfg.nodes();
    self.edgeList = self.dfg.edges();

    return timeit.default_timer() - start_time;






  def extractFunctional(self):
    '''
     Extracts the functional component of the circuit	
        Note that all three extractions (Structural, Functional, Constant)
        Needs to be called. 
    '''
    sys.setrecursionlimit(1500)
    start_time = timeit.default_timer();
    print " -- Extracting functional features..."# from : " + fileName;

    totalMinPaths = 0;
    totalMaxPaths = 0;
    maxPathCount= 0;
    minPathCount= 0;

    maxNumAlpha = 0;
    pathHistory = [];

    #inAll = self.constantList + self.inNodeList;
    outsize = len(self.outNodeList)
    insize = len(self.inNodeList)
    curin = 0;
    curout = 0;
    plim = 0.1;

    for out in self.outNodeList:
      '''
      count = 0;
      cmarked = set()
      self.faninCone(out, cmarked)
      intoFF = [i for i in self.constantList if i in cmarked]
      count = len(intoFF)
      '''

      for inNode in self.inNodeList:
        marked = set();
        path= [];
        simpPath= [inNode];
        pathSequence= [];
        pathList= [[],[],[]];
        swAlpha = [];

        length = self.findPath(inNode, out, marked, path, simpPath, pathSequence,  [0,sys.maxint,0, 0], pathList, swAlpha);

        if(0 in length[0:2]):
          continue;
        
        
        #Extract the sequence representation, make sure to ignore representations that is already in maxList
        #print " -- Extracting Sequence"
        swMax = self.extractSWStringList(pathList[0], self.maxList);
        swMin = self.extractSWStringList(pathList[1], self.minList);
        swAlpha = self.extractSWStringList(pathList[2], self.alphaList);

        #print " -- Finding Entropy"
        #Find the sequences with the highest entropy
        maxSequence = self.findMaxEntropy(swMax);
        minSequence = self.findMaxEntropy(swMin);
        alphaSequence = self.findMaxEntropy(swAlpha);
        nAlpha = len(set(alphaSequence))

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

        


        
      #Number of inputs the output depends on;
      #self.fpDict["outC"][count] = self.fpDict["outC"].get(count, 0) + 1;
      


    # Extract the sequence 
    #print "MAXLIST: " + repr(self.maxList);
    maxSeq = 3;
    swMax = list(self.maxList);
    swMax.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
    self.maxList = swMax[0:3];
    #print "MAXLIST: " + repr(self.maxList);

    #print "MINLIST: " + repr(self.minList);
    swMin = list(self.minList);
    swMin.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
    self.minList = swMin[0:3];
    #print "MINLIST: " + repr(self.minList);
    
    #print "ALPHALIST: " + repr(self.alphaList);
    self.alphaList= list(self.alphaList);
    self.alphaList.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
    self.alphaList = self.alphaList[0:3];

    #print "ALPHALIST: " + repr(self.alphaList);
    




    print " -- Extracting additional functional features..."
    if(totalMaxPaths == 0):
      self.statstrf = "%s,%s," % (self.statstrf, repr(0));
    else:
      self.statstrf = "%s,%s," % (self.statstrf, repr(float(maxPathCount)/float(totalMaxPaths)));

    if(totalMinPaths == 0):
      self.statstrf = "%s,%s," % (self.statstrf, repr(0));
    else:
      self.statstrf = "%s,%s" % (self.statstrf, repr(float(minPathCount)/float(totalMinPaths)));
    
    return timeit.default_timer() - start_time;






  def extractConstant(self):
    '''
     Extracts the constant component of the circuit	
        Note that all three extractions (Structural, Functional, Constant)
        Needs to be called. 
    '''
    start_time = timeit.default_timer();
    print " -- Extracting constant features..."

    self.constSet = set();
    self.constMap = dict();
    constStr = "";
    for constant in self.constantList:
      cnstlabel = self.labelAttr[constant];
      cnstVal = re.search('\'(.*)', cnstlabel);
      #No bit marking notation
      if(cnstVal == None):
        cnstVal = cnstlabel;
        cnstVal = cnstVal.replace("L","")

        if(len(cnstVal) > 19):
          cnstVal = "9999999999999999";
        self.constSet.add(cnstVal);
        self.constMap[cnstVal] = self.constMap.get(cnstVal,0) + 1;

        if(cnstVal == "0"):
          cnstVal = "-1"
        constStr = constStr + cnstVal+ ",";

      else:
        cnstVal = cnstVal.group(1);

      #########################################################
        #Decompose the large constant for a pmux
        psize = sys.maxint;
        csize = 0;
        succList = self.dfg.successors(constant);
        for succ in succList:                         #Check if successor is PMUX
          if succ not in self.labelAttr:
            continue;

          operation = self.labelAttr[succ]
          if "pmux" in operation:
            predList = self.dfg.predecessors(succ);
            for pred in predList:                    #Find the size of the input
              if pred != constant:
                bitwidth = 0;
                if (pred,succ) not in self.edgeAttr:
                  bitwidth= 1;
                else:
                  label = self.edgeAttr[(pred,succ)];
                  label = re.search('<(.*)>', label);
                  bitwidth= int(label.group(1));
                if bitwidth <psize:
                  psize = bitwidth;

            if (constant,succ) not in self.edgeAttr:
              csize = 1;
            else:
              label = self.edgeAttr[(constant,succ)];
              label = re.search('<(.*)>', label);
              csize = int(label.group(1));

            if(psize == 0 or csize == 0):
              print "NEED TO RETHINK METHODS!!!! PSIZE OR CSIZE IS ZERO!"
              raise error.GenError("PMUX ERROR")
            break;
              
        if(csize > psize):
          if((csize % psize) == 0 and 'x' not in cnstVal):
            start = 0;
            while start < csize:
              cnst = repr(int(cnstVal[start:start+psize], 2));
              self.constMap[cnst] = self.constMap.get(cnstVal,0) + 1;
              start = start + psize;

            continue;
      ########################################################



        if('x' in cnstVal):   #DON'T CARE
          cnstVal = "-2";
        elif('z' in cnstVal): #HIGH IMPEDANCE
          cnstVal = "-3";
        else:
          cnstVal = repr(int(cnstVal, 2));
          cnstVal.replace("L", "")
          if(len(cnstVal) > 19):
            cnstVal = "9999999999999999";
        
        self.constMap[cnstVal] = self.constMap.get(cnstVal,0) + 1;

        self.constSet.add(cnstVal);

        if(cnstVal == "0"):
          cnstVal = "-1"

        constStr = constStr + cnstVal + ",";

    return timeit.default_timer() - start_time;


  def getBirthmark(self, kVal, isFindEndGram=False,productivity=False):
    '''
     Returns the data for the birthmark
    '''
    #print "NUMBER OF CORES: " + repr(multiprocessing.cpu_count());
    print " - Extracting birthmarks"

    #f = multiprocessing.Process(target=self.extractFunctional);
    #s = multiprocessing.Process(target=self.extractStructural);

    #f.start();
    #time.sleep(1);
    #s.start();
    #start_time = timeit.default_timer();
    self.endSet = set()
    self.endGramList = set();
    self.endGramLine = dict();
    self.pathList = set();
    self.maxList = set();
    self.minList = set();
    self.alphaList = set();



    selapsed = self.extractStructural();
    if len(self.cnodes) == 0:
      print ("[WARNING] -- No Logic found in design");
      raise error.GenError("No logic found in design: Not enough information");
                    
                


    #Update Edge Attributes edges 
    self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');
    nx.write_dot(self.dfg, "./file.dot")

    print " -- Expanding addtree"
    for anode in self.addlist:
      #print "CHECKING NODE: " + anode
      self.expand_add_tree(anode)
      #if anode == "c1960":
        #sys.exit();
      #print

    


    #elapsed = timeit.default_timer() - start_time;
    #print "[STRC] -- ELAPSED: " +  repr(elapsed) + "\n";
    #print self.endSet


    

    #print "========================================================================"
    #start_time = timeit.default_timer();
    celapsed = self.extractConstant();
    #elapsed = timeit.default_timer() - start_time;
    #print "[CONST] -- ELAPSED: " +  repr(elapsed) + "\n";

    #print "[DFX] -- Waiting for functional thread to finish..."
    #f.join();  #Wait till the first is finished
    #self.statstr = self.statstr + self.statstrf   #Append the stats from the functional
    self.statstr = "%s,%s" % (self.statstr, self.statstrf);

    kelapsed = self.KGram2(int(kVal));


    '''
                # LINE PREDICTION
    #Find the ngram backwards starting from the end node
    if isFindEndGram != False:
      #Look at nodes that have no successor. Nodes at the end.
      for node in self.endSet:
        marked = set();
        path = []
        self.findKGramPath_Backwards(node, marked, path)
        #print
    '''


    #print 
    #for gram in self.endGramList:
    #	print repr(gram) + "   " + repr(self.endGramLine[gram]);
    

    kgram = (self.kgramlist, self.kgramline, self.endGramList, self.endGramLine);
    #for gram in self.kgramlist:
#		print gram;
    


    #print "========================================================================"
    start_time = timeit.default_timer();
    felapsed = 0.0;
    self.extractFunctional();
    felapsed = timeit.default_timer() - start_time;
    #print "[FUNC] -- ELAPSED: " +  repr(elapsed) + "\n";



    fileStream = open("data/kExtractTime.csv", 'a');
    fileStream.write(repr(kelapsed) + "\n");
    fileStream.close();

    fileStream = open("data/sExtractTime.csv", 'a');
    fileStream.write(repr(selapsed) + "\n");
    fileStream.close();

    fileStream = open("data/fExtractTime.csv", 'a');
    fileStream.write(repr(felapsed) + "\n");
    fileStream.close();

    fileStream = open("data/cExtractTime.csv", 'a');
    fileStream.write(repr(celapsed) + "\n");
    fileStream.close();
    
    fileStream = open("data/numCNode.csv", 'a');
    fileStream.write(repr(len(self.cnodes)) + "\n");
    fileStream.close();
                
    fileStream = open("data/numNode.csv", 'a');
    fileStream.write(repr(len(self.dfg.nodes())) + "\n");
    fileStream.close();
    
    fileStream = open("data/numEdge.csv", 'a');
    fileStream.write(repr(len(self.dfg.edges())) + "\n");
    fileStream.close();
    
    fileStream = open("data/numVE.csv", 'a');
    fileStream.write(repr(len(self.dfg.nodes()) + len(self.dfg.edges())) + "\n");
    fileStream.close();
                
    fileStream = open("data/alphaLength.csv", 'a');
    avgalph = 0;
    for s in self.alphaList:
      avgalph += len(s);
    if(len(self.alphaList) != 0):
      avgalph = avgalph / len(self.alphaList)

    fileStream.write(repr(avgalph) + "\n");
    fileStream.close();
                
    fileStream = open("data/maxLength.csv", 'a');
    avgalph = 0;
    for s in self.maxList:
      avgalph += len(s);
    if(len(self.maxList) != 0):
      avgalph = avgalph / len(self.maxList)
    fileStream.write(repr(avgalph) + "\n");
    fileStream.close();
                


    #print "[KGRAM] -- ELAPSED: " +  repr(kelapsed) 
    #print "[FUNCT] -- ELAPSED: " +  repr(felapsed) 
    #print "[STRUC] -- ELAPSED: " +  repr(selapsed) 
    #print "[CONST] -- ELAPSED: " +  repr(celapsed) 
    
    print "[Birthmark] -- ELAPSED: " +  repr(celapsed+kelapsed+felapsed+selapsed) 
    print "[KGRAM] -- ELAPSED: " + repr(kelapsed);

    return (self.maxList, self.minList, self.constMap, self.fpDict, self.statstr, self.alphaList, kgram);



  '''
          for pred in predList:
            if (pred,node) not in self.edgeAttr:
              psize = 1;
            else:
              label = self.edgeAttr[(pred,node)];
              label = re.search('<(.*)>', label);
              psize = int(label.group(1));

            if(psize > size):
              size = psize;

          for succ in sucList:
            if (node, succ) not in self.edgeAttr:
              ssize = 1;
            else:
              label = self.edgeAttr[(node, succ)];
              label = re.search('<(.*)>', label);
              ssize = int(label.group(1));

            if(ssize > size):
              size = ssize;




  '''
