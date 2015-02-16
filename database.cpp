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

bool Database::importDatabase(std::string path){
	printf("[DATABASE] -- Importing database from XML file\n");
	printf(" * FILE: %s\n", path.c_str());
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
	printXML();
	printf("[DATABASE] -- XML File imported. Parsing...\n");

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
			std::string cktNodeName = cktNode->name();
			if(cktNodeName!= "CIRCUIT") throw eCIRCUIT_FE;

			std::string cktName = "===";  
			int id = -2;

			//Get the name and ID of the circuit 
			xml_attribute<>* cktAttr = cktNode->first_attribute();
			if(cktAttr == NULL) throw eNoAttr;

			std::string cktAttrName = cktAttr->name();
			if(cktAttrName == "name") cktName = cktAttr->value(); 
			else if(cktAttrName == "id") id = string2int(cktAttr->value()); 
			else throw eCIRCUIT_ATTR_FE ;

			cktAttr = cktAttr->next_attribute();
			if(cktAttr == NULL) throw eNoAttr;
			
			cktAttrName = cktAttr->name();
			if(cktAttrName == "name") cktName = cktAttr->value(); 
			else if(cktAttrName == "id") id = string2int(cktAttr->value()); 
			else throw eCIRCUIT_ATTR_FE ;

			if(id < 0 || cktName == "===") throw eCIRCUIT_ATTR_FE;
			Birthmark* bm= new Birthmark();
			bm->setID(id);
			bm->setName(cktName);

			std::map<unsigned, unsigned> fingerprint;
			std::list<std::string> maxseq;
			std::list<std::string> minseq;
			std::set<int> constants;
			
			//Look through the fingerprint of each circuit
			xml_node<>* featureNode = cktNode->first_node();
			while (featureNode!= NULL){
				std::string featureNodeName = featureNode->name();
				if(featureNodeName == "MAXSEQ")
					bm->addMaxSequence(featureNode->value());
				else if(featureNodeName == "MINSEQ")
					bm->addMinSequence(featureNode->value());
				else if(featureNodeName == "CONSTANT")
					bm->addConstant(string2int(featureNode->value()));
				else if(featureNodeName == "FP"){
			
			//Get the name and ID of the circuit 
			xml_attribute<>* fpAttr = featureNode->first_attribute();
			if(fpAttr == NULL) throw eNoAttr;

			std::string fAttrName= fpAttr->name();
			std::string featureName;
			if(fAttrName == "type") featureName = fpAttr->value(); 

				//########################################################
				xml_node<>* attrNode =  featureNode->first_node();

				//Store the attribute of each fingerprint 
				while (attrNode!= NULL){
					int size = -2;
					int count = -2;

					xml_attribute<>* attrAttr = attrNode->first_attribute();
					if(attrAttr == NULL) throw eNoAttr;
					
					std::string attrAttrName = attrAttr->name();
					if(attrAttrName == "size") size = string2int(attrAttr->value());
					else if(attrAttrName == "count") count= string2int(attrAttr->value());
					else throw eFeature_FE;

					attrAttr = attrAttr->next_attribute();
					if(attrAttr == NULL) throw eNoAttr;

					attrAttrName = attrAttr->name();
					if(attrAttrName == "size") size = string2int(attrAttr->value());
					else if(attrAttrName == "count") count = string2int(attrAttr->value());
					else throw eFeature_FE;

					if(size == -2 || count == -2) throw eSC_FE;

					//Store the attribute into the fingerprint;
					bm->addFingerprint(featureName, size, count);
					attrNode = attrNode->next_sibling();
				}
				//########################################################

				}



				
				featureNode= featureNode->next_sibling(); 
			}

			//Store the fingerprintlist of the circuit 
			m_Database.push_back(bm);
			cktNode = cktNode->next_sibling(); 
		}

	}

	catch (Error error){
		if(error == eNodeNull) printf("[ERROR] -- XML root node is empty\n");
		else if(error == eNodeNull) printf("[ERROR] -- Database is not empty. Aborting import\n");
		else if(error == eNoAttrSC) printf("[ERROR] -- XML node expected a size or count attribute \n");
		else if(error == eNoAttr) printf("[ERROR] -- XML node expected an attribute\n");
		else if(error == eDATABASE_FE) printf("[ERROR] -- XML File has a different format then expected (DATABASE)\n");
		else if(error == eCIRCUIT_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT)\n");
		else if(error == eCIRCUIT_ATTR_FE) printf("[ERROR] -- XML File has a different format then expected (CIRCUIT name or id attribute is missing)\n");
		else if(error == eFeature_FE) printf("[ERROR] -- XML File has a different format then expected (ATTR size or count attribute is missing)\n");
		else if(error == eCNAME_FE) printf("[ERROR] -- XML File has a different format then expected (Size Count has a value that is unknown)\n");
		return false;
	}


	printf("[DATABASE] -- Database import complete!\n");
	return true;
}

int Database::string2int(const char* string){
		char *end;
    long  l;
    l = strtol(string, &end, 10);
    if (*string == '\0' || *end != '\0') 
        return -2;

   	return (int) l;
}


void Database::printXML(){
	std::cout << m_XML << "\n";
}
