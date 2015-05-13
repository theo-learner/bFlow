CXX = g++

CFLAGS = \
		-Wall \
		-Wunused-result \
		-O1 \
		-g \
		$

OBJS = \
	sw/src/ssw.o \
	sw/src/ssw_cpp.o \
	similarity.o \
	print.o \
	$

OBJSERVER = \
	database.o \
	birthmark2.o \
	similarity.o \
	print.o \
	server.o \
	$

OBJREF= \
	database.o \
	birthmark2.o \
	similarity.o \
	print.o \
	$

DOTDIR:= dot/
DATADIR:= dot/


all: bench_matlab rsearch bench_db cserver compareAST

#build subdirectories
	
bench_matlab: $(OBJREF) bench_matlab.o 
	$(CXX) $(OBJREF) bench_matlab.o -o bench_matlab 

autocor: $(OBJS) autocor.o 
	$(CXX) $(OBJS) autocor.o -o autocor 

rsearch: $(OBJREF) rsearch.o
	$(CXX) $(OBJREF)  rsearch.o -o rsearch 

compareAST: $(OBJREF) compareAST.o 
	$(CXX) $(OBJREF) compareAST.o -o compareAST

bench_db: $(OBJREF) bench_db.o 
	$(CXX) $(OBJREF) bench_db.o -o bench_db

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

cserver:  $(OBJSERVER) cserver.o
	$(CXX)  -o cserver $(OBJSERVER) cserver.o 
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $< -Ilibs/


birthmark2.o: birthmark.cpp 
	$(CXX) $(CFLAGS) -c -O1 -o birthmark2.o birthmark.cpp -Ilibs/

clean: 
	rm -vf *.o hbflow cserver rsearch bench_db bench_matlab compareAST

cleanall: 
	rm -vf *.o hbflow cserver rsearch bench_db bench_matlab compareAST scripts/*.pyc  data/*.csv data/*.dat data/*.log db/*.xml data/yoscript
