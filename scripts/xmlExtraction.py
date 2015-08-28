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

def generateXML(dotfile, soup, kVal, verbose=False, findEndGram=False):

	start_time = timeit.default_timer();
	print "VERBOSE: " + repr(verbose)
	#result = dfx.extractDataflow(dotfile, kVal);

	if(".dot" not in dotfile):
		print "[ERROR] -- Input file does not seem to be a dot file"
		raise error.GenError("");
	
	bExtractor = BirthmarkExtractor(dotfile);
	result = bExtractor.getBirthmark(kVal, isFindEndGram= findEndGram);

	elapsed = timeit.default_timer() - start_time;
	print "[DFX] -- ELAPSED: " +  repr(elapsed);
	print

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
		print "KSET" 
		print result[6][0]
		print
		print "KCOUNT" 
		print result[6][1]
		print
		print "KLIST" 
		for gram, cnt in result[6][2].iteritems():
			print repr(cnt) + "\t" + repr(gram);
		print
		print "ENDGRAM"
		for gram in result[6][4]:
			print repr(gram) + "   " + repr(result[6][5][gram]);

#######################################################
	ckttag = soup.new_tag("CIRCUIT");

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
	for const, count in constSet.iteritems():
		consttag = soup.new_tag("CONSTANT");
		consttag.string = const+ ":" + repr(count)
		ckttag.append(consttag);
	
	fpDict= result[3];

	for n, fp in fpDict.iteritems():		
		fptag = soup.new_tag("FP");
		fptag['type'] = n;
		fptag.string = repr(fp);
		ckttag.append(fptag);
	
		
	statstr = result[4];
	stattag = soup.new_tag("STAT");
	stattag.string = statstr;
	ckttag.append(stattag);

	alphaList = result[5];
	for seq in alphaList:
		seqtag = soup.new_tag("ALPHASEQ");
		seqtag.string = seq 
		ckttag.append(seqtag);
	
	
	kgramset = result[6][0];
	for s, cnt in kgramset.iteritems():
		kgramset_tag = soup.new_tag("KSET");
		kstring = ""
		for item in SortedSet(s):
			kstring = kstring + item;

		kgramset_tag.string = kstring
		kgramset_tag['CNT'] = cnt
		ckttag.append(kgramset_tag);
	
	kgramcount= result[6][1];
	for s, c  in kgramcount.iteritems():
		kgramcount_tag = soup.new_tag("KCOUNT");

		for fnc, cnt  in s.iteritems():
			kgramcount_entrytag = soup.new_tag("FNC");
			kgramcount_entrytag['CNT'] = cnt
			kgramcount_entrytag.string = fnc;

			kgramcount_tag.append(kgramcount_entrytag);
		
		kgramcount_tag['CNT'] = c;

		ckttag.append(kgramcount_tag);
	
	kgramset = result[6][2];
	kgramlinenum= result[6][3];
	for s, cnt in kgramset.iteritems():
		kgramlist_tag = soup.new_tag("KLIST");

		kstring = "".join(item for item in s);
		kgramdp_tag = soup.new_tag("DP");
		kgramdp_tag.string = kstring;
		kgramlist_tag.append(kgramdp_tag);


		for lineset in kgramlinenum[s]:
			klinenum = ",".join(item for item in lineset)

			kgramline_tag = soup.new_tag("LN");
			kgramline_tag.string = klinenum;
			kgramlist_tag.append(kgramline_tag);
		
		
		kgramlist_tag['CNT'] = cnt
		ckttag.append(kgramlist_tag);
	

	if(findEndGram != False):
		endGramList = result[6][4];
		endGramLine = result[6][5];

		for s in endGramList:
			kgramlist_tag = soup.new_tag("ENDKLIST");

			kstring = "".join(item for item in s);
			kgramdp_tag = soup.new_tag("DP");
			kgramdp_tag.string = kstring;
			kgramlist_tag.append(kgramdp_tag);


			for lineset in endGramLine[s]:
				klinenum = ",".join(item for item in lineset)

				kgramline_tag = soup.new_tag("LN");
				kgramline_tag.string = klinenum;
				kgramlist_tag.append(kgramline_tag);
			
			
			ckttag.append(kgramlist_tag);

	return ckttag

	#return soup
#######################################################
