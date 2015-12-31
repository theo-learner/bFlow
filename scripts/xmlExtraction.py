#!/usr/bin/python2.7

'''
	xmlExtraction: 
		Extracts the birthmark from the AST and stores it in XML
'''

#import dataflow as dfx
from bs4 import BeautifulSoup
from sortedcontainers import SortedSet
from bExtractor import BirthmarkExtractor
import timeit

def generateXML(dotfile, soup, kVal, verbose=False, findEndGram=False, strict=False, runFlag=False):
	if(".dot" not in dotfile):
		print "[ERROR] -- Input file does not seem to be a dot file"
		raise error.GenError("");
	
	bExtractor = BirthmarkExtractor(dotfile, strictFlag=strict, );
	result = bExtractor.getBirthmark(kVal, isFindEndGram=findEndGram, productivity=runFlag);

	if verbose == True:
		print "MAXSEQ" 
		print result[0]
		print
		print "MINSEQ" 
		print result[1]
		print
		print "CONSTANT" 
		print result[2]
		print
		print "FP" 
		print result[3]
		print
		print "STATS" 
		print result[4]
		print
		print "ALPHASEQ" 
		print result[5]
		print
		print "KLIST" 
		for gram, cnt in result[6][0].iteritems():
			print repr(cnt) + "\t" + repr(gram);
		print
		print "ENDGRAM"
		for gram in result[6][2]:
			print repr(gram) + "   " + repr(result[6][3][gram]);

#######################################################
	ckttag = soup.new_tag("ckt");

	#Store the max seq
	
	maxList = result[0];
	for seq in maxList:
		seqtag = soup.new_tag("max");
		seqtag.string =seq 
		ckttag.append(seqtag);
		
	minList = result[1];
	for seq in minList:
		seqtag = soup.new_tag("min");
		seqtag.string =seq 
		ckttag.append(seqtag);
	
	alphaList = result[5];
	for seq in alphaList:
		seqtag = soup.new_tag("alph");
		seqtag.string = seq 
		ckttag.append(seqtag);
	
	constSet= result[2];
	for const, count in constSet.iteritems():
		consttag = soup.new_tag("cnst");
		consttag.string = const+ ":" + repr(count)
		ckttag.append(consttag);
	
	fpDict= result[3];

	for n, fp in fpDict.iteritems():		
		fptag = soup.new_tag("fp");
		fptag['type'] = n;
		fptag.string = repr(fp);
		ckttag.append(fptag);
	
		
	statstr = result[4];
	stattag = soup.new_tag("stat");
	stattag.string = statstr;
	ckttag.append(stattag);

	
	
	kgramset = result[6][0];
	kgramlinenum= result[6][1];
	for s, cnt in kgramset.iteritems():
		kgramlist_tag = soup.new_tag("kl");

		kstring = "".join(item for item in s);
		kgramdp_tag = soup.new_tag("dp");
		kgramdp_tag.string = kstring;
		kgramlist_tag.append(kgramdp_tag);


		"""
		for lineset in kgramlinenum[s]:
			klinenum = ",".join(item for item in lineset)

			kgramline_tag = soup.new_tag("ln");
			kgramline_tag.string = klinenum;
			kgramlist_tag.append(kgramline_tag);
		"""
		
		
		kgramlist_tag['cnt'] = cnt
		ckttag.append(kgramlist_tag);
	

	if(findEndGram != False):
		endGramList = result[6][2];
		endGramLine = result[6][3];

		for s in endGramList:
			kgramlist_tag = soup.new_tag("endkl");

			kstring = "".join(item for item in s);
			kgramdp_tag = soup.new_tag("dp");
			kgramdp_tag.string = kstring;
			kgramlist_tag.append(kgramdp_tag);


			for lineset in endGramLine[s]:
				klinenum = ",".join(item for item in lineset)

				kgramline_tag = soup.new_tag("ln");
				kgramline_tag.string = klinenum;
				kgramlist_tag.append(kgramline_tag);
			
			
			ckttag.append(kgramlist_tag);

	return ckttag

	#return soup
#######################################################
