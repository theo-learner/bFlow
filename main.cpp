#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <sstream>
#include "sw/src/ssw.h"

std::string create_yosys_script(std::string, std::string);
bool readDumpFile(std::string, std::string);
std::string readSeqFile(std::string);
const std::string g_YosysScript= "ys";
std::string extractDataflow(std::string);

int main(int argc, char** argv){
	try{
		if(argc != 3) throw 4;

		printf("Extracting dataflow from reference design\n");	
		std::string refseq = extractDataflow(argv[1]);

		//Make sure database file is okay
		std::ifstream infile;
		infile.open(argv[2]);
		if (!infile.is_open()) throw 5;

		std::string file;
		printf("Extracting dataflows from database\n");	

		while(getline(infile, file)){
			std::string seq = extractDataflow(file);
			printf("ALIGNING SEQ1: %s - SEQ2: %s\n", refseq.c_str(), seq.c_str());
			if(refseq.length() < seq.length())
				swAlignment(refseq.c_str(), refseq.size(), seq.c_str(), seq.size());
			else
				swAlignment(seq.c_str(), seq.size(), refseq.c_str(), refseq.size());

			/*cmd = "python pscript.py " + cname + "_df.dot > .pscript.dmp";
				system(cmd.c_str());
				if(!readDumpFile(".pscript.dmp", "Traceback (")){
				printf("[ERROR] -- pyscript encountered an error. Exiting\n");
				return 0;
				}
			 */
		}
	}
	catch(int e){
		if(e == 1)
			printf("[ERROR] -- Yosys encountered an error. Exiting\n");
		else if(e == 2)
			printf("[ERROR] -- There was no sequence extracted. Exiting\n");
		else if(e == 3)
			printf("[ERROR] -- Unknown File extension. Expecting Verilog or VHDL File\n");
		else if(e == 4)
			printf("[ERROR] -- Not enough arguments <Verilog File> <Database File> \n");
		else if(e == 5)
			printf("[ERROR] -- Cannot open the database for import...exiting\n");
		else
			printf("[ERROR] -- Error Occurred that was not mapped before\n");

		return 0;
	}

	return 1;
}

std::string create_yosys_script(std::string infile, std::string outFile){
	//Create Yosys Script	
	std::string yosysScript = "";
	yosysScript += "read_verilog ";
	yosysScript += infile + "\n\n";

	yosysScript += "hierarchy -check\n";
	yosysScript += "proc; opt; fsm; opt; wreduce; opt\n\n";
	
	yosysScript += "show -width -format dot -prefix ./" + outFile + "\n";

	std::ofstream ofs;
	ofs.open(g_YosysScript.c_str());

	ofs<< yosysScript;
	printf("Yosys script generated\n");
	return g_YosysScript.c_str();

}
		
bool readDumpFile(std::string file, std::string errorString)	{
		std::stringstream ss;
		std::ifstream ifs;
		ifs.open(file.c_str());
		ss<<ifs.rdbuf();
		ifs.close();

		if(ss.str().find(errorString) != std::string::npos)
			throw 1;
		else return true;
}

std::string readSeqFile(std::string file){

		std::stringstream ss;
		std::ifstream ifs;
		ifs.open(file.c_str());
		ss<<ifs.rdbuf();
		ifs.close();

	std::string seq = ss.str();
	if(seq == "") throw 2;

	return seq;
}

std::string extractDataflow(std::string file){
		printf("\nVerilog File: %s\n", file.c_str());
	
		int lastSlashIndex = file.find_last_of("/") + 1;
		if(lastSlashIndex == -1) lastSlashIndex = 0;

		int lastDotIndex= file.find_last_of(".");
		std::string cname = file.substr(lastSlashIndex, lastDotIndex-lastSlashIndex);
		std::string extension= file.substr(lastDotIndex+1, file.length()-lastDotIndex);
		printf("VNAME: %s\tVEXT: %s\n", cname.c_str(), extension.c_str());

		//Make sure the file is a verilog file
		if(extension != "v" && extension != "vhd") throw 3;

		//RUN YOSYS TO GET DATAFLOW OF THE VERILOG FILE
		std::string scriptFile = create_yosys_script(file, cname+"_df");
		if(scriptFile == "") return 0;

		std::string cmd = "yosys -Qq -s ";
		cmd += scriptFile + " -l .yosys.dmp";
		printf("[CMD] -- Running command: %s\n", cmd.c_str());
		system(cmd.c_str());

		//Check to see if yosys encountered an error
		readDumpFile(".yosys.dmp", "ERROR:");

		//RUN PYTHON SCRIPT TO EXTRACT DATAFLOW FROM DOT FILE THAT IS GENERATED
		cmd = "python pscript.py " + cname + "_df.dot";
		printf("[CMD] -- Running command: %s\n", cmd.c_str());
		system(cmd.c_str());

		std::string seq = readSeqFile(".yscript.seq");
		return seq;
}
