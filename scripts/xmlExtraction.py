#!/usr/bin/python2.7

'''
	xmlExtraction: 
		Extracts the birthmark from the AST and stores it in XML
'''

import dataflow as dfx
from bs4 import BeautifulSoup

def generateXML(dotfile, ID,  cktName, soup):
	result = dfx.extractDataflow(dotfile);

#######################################################
	ckttag = soup.new_tag("CIRCUIT");
	ckttag['name'] = cktName;
	ckttag['id'] = ID 

	#Store the max seq
	maxList = result[0];
	for seq in maxList:
		seqtag = soup.new_tag("MAXSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
		
	minList = result[1];
	for seq in minList:
		seqtag = soup.new_tag("MINSEQ");
		seqtag.string =seq 
		ckttag.append(seqtag);
	
	constSet= result[2];
	for const in constSet:
		consttag = soup.new_tag("CONSTANT");
		consttag.string = const
		ckttag.append(consttag);
	
	fpDict= result[3];

	for n, fp in fpDict.iteritems():		
		fptag = soup.new_tag("FP");
		fptag['type'] = n;
		fptag.string = repr(fp);
		ckttag.append(fptag);
		
	alphaList = result[5];
	for seq in alphaList:
		seqtag = soup.new_tag("ALPHASEQ");
		seqtag.string = seq 
		ckttag.append(seqtag);
	
	statstr = result[4];
	stattag = soup.new_tag("STAT");
	stattag.string = statstr;
	ckttag.append(stattag);

	return ckttag

	#return soup
#######################################################
