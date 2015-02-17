/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@
	@      database.cpp
	@      
	@      @AUTHOR:Kevin Zeng
	@      Copyright 2012 – 2013 
	@      Virginia Polytechnic Institute and State University
	@
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "database.hpp"
using namespace rapidxml;

Database::Database(){	
}

Database::Database(std::string file){	
	importDatabase(file);
}

Database::~Database(){
	std::list<Birthmark*>::iterator it;
	for(it = m_Database.begin(); it != m_Database.end(); it++)
		delete *it;
}

bool Database::importDatabase(std::string path){
	printf("[DATABASE] -- Importing database from XML file: %s\n", path.c_str());
	m_XML.clear();

	//Open XML File for parsing
	std::ifstream xmlfile;
	xmlfile.open(path.c_str());
	if (!xmlfile.is_open())	{
		fprintf(stderr, "[ERROR] -- Cannot open the xml file for import...exiting\n");
		fprintf(stderr, "\n***************************************************\n\n");
		exit(-1);
	}


	//Read in contents in the XML File
	std::string xmlstring = "";
	std::string xmlline;
	while(getline(xmlfile, xmlline))
		xmlstring += xmlline + "\n";

	xml_document<> xmldoc;
	char* cstr = new char[xmlstring.size() + 1];
	strcpy(cstr, xmlstring.c_str());


	//Parse the XML Data
	m_XML.parse<0>(cstr);
	//printXML();
	printf("[DATABASE] -- XML File imported. Parsing...");

	enum Error {
		eDatabaseNotEmpty,
		eNodeNull,
		eNoAttr, 
		eDATABASE_FE,
		eCIRCUIT_FE,
		eCNAME_FE, 
		eSC_FE,
		eFeature_FE,
		eCIRCUIT_ATTR_FE,
		eNoAttrSC
	};

	try{
		if(m_Database.size() != 0) throw eDatabaseNotEmpty;
		xml_node<>* rootNode= m_XML.first_node();
		if(rootNode == NULL) throw eNodeNull;

		//Make sure first node is DATABASE
		std::string rootNodeName = rootNode->name();
		if(rootNodeName != "DATABASE") throw eDATABASE_FE;
		xml_node<>* cktNode= rootNode->first_node();

		//Look through the circuits in the Database
		while (cktNode!= NULL){
			Birthmark* bm = new Birthmark();
			if(!bm->importXML(cktNode)) throw eCIRCUIT_FE;

			//Store the fingerprintlist of the circuit 
			m_Database.push_back(bm);
			cktNode = cktNode->next_sibling(); 
		}

	}

	catch (Error error){
		printf("\n");
		if(error == eNodeNull) printf("[ERROR] -- XML root node is empty\n");
		else if(error == eNodeNull) printf("[ERROR] -- Database is not empty. Aborting import\n");
		else if(error == eNoAttrSC) printf("[ERROR] -- XML node expected a size or count attribute \n");
		else if(error == eNoAttr) printf("[ERROR] -- XML node expected an attribute\n");
		else if(error == eDATABASE_FE) printf("[ERROR] -- XML File has a different format then expected (DATABASE)\n");
		else if(error == eCIRCUIT_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT)\n");
		else if(error == eCIRCUIT_ATTR_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT name or id attribute is missing)\n");
		else if(error == eFeature_FE) printf("[ERROR] -- XML File has a different format then expected (ATTR size or count attribute is missing)\n");
		else if(error == eCNAME_FE) printf("[ERROR] -- XML File has a different format then expected (Size Count has a value that is unknown)\n");

		printf("\n");
		return false;
	}


	printf("COMPLETE!\n\n");
	return true;

}


void Database::printXML(){
	std::cout << m_XML << "\n";
}
