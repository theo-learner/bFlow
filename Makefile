CXX = g++
SRC_DIR = src

CFLAGS = \
		-Wall \
		-Wunused-result \
		-O1 \
		-g \
		$

OBJSERVER = \
	$(SRC_DIR)/database.o \
	$(SRC_DIR)/birthmark2.o \
	$(SRC_DIR)/similarity.o \
	$(SRC_DIR)/print.o \
	$(SRC_DIR)/server.o \
	$

OBJREF= \
	$(SRC_DIR)/database.o \
	$(SRC_DIR)/birthmark2.o \
	$(SRC_DIR)/similarity.o \
	$(SRC_DIR)/print.o \
	$

DOTDIR:= dot/
DATADIR:= dot/


all: bench_matlab rsearch bench_db cserver compareAST

#build subdirectories
	
bench_matlab: $(OBJREF) $(SRC_DIR)/bench_matlab.o 
	$(CXX) $(OBJREF) $(SRC_DIR)/bench_matlab.o -o bench_matlab 

rsearch: $(OBJREF) $(SRC_DIR)/rsearch.o
	$(CXX) $(OBJREF)  $(SRC_DIR)/rsearch.o -o rsearch 

compareAST: $(OBJREF) $(SRC_DIR)/compareAST.o 
	$(CXX) $(OBJREF) $(SRC_DIR)/compareAST.o -o compareAST

bench_db: $(OBJREF) $(SRC_DIR)/bench_db.o 
	$(CXX) $(OBJREF) $(SRC_DIR)/bench_db.o -o bench_db

host_test1: $(OBJREF) $(SRC_DIR)/opt_test.o 
	$(CXX) $(OBJREF) $(SRC_DIR)/opt_test.o -o host_test1 

cserver:  $(OBJSERVER) $(SRC_DIR)/cserver.o
	$(CXX)  -o cserver $(OBJSERVER) $(SRC_DIR)/cserver.o 
	

$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $< -Ilibs/



$(SRC_DIR)/birthmark2.o: $(SRC_DIR)/birthmark.cpp 
	$(CXX) $(CFLAGS) -c -O1 -o $(SRC_DIR)/birthmark2.o $(SRC_DIR)/birthmark.cpp -Ilibs/

clean: 
	rm -vf $(SRC_DIR)/*.o hbflow cserver rsearch bench_db bench_matlab compareAST

cleanall: 
	rm -vf $(SRC_DIR)/*.o hbflow cserver rsearch bench_db bench_matlab compareAST scripts/*.pyc  data/*.csv data/*.dat data/*.log db/*.xml data/yoscript
