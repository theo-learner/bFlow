CXX = g++

CFLAGS = \
		-Wall \
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
	birthmark.o \
	feature.o \
	similarity.o \
	print.o \
	server.o \
	$

OBJREF= \
	database.o \
	birthmark.o \
	feature.o \
	similarity.o \
	print.o \
	$

all: 
	mkdir -p dot

#build subdirectories
	
bench_matlab: $(OBJREF) bench_matlab.o 
	$(CXX) $(OBJREF) bench_matlab.o -o bench_matlab 

autocor: $(OBJS) autocor.o 
	$(CXX) $(OBJS) autocor.o -o autocor 

refTest: $(OBJREF) refTest.o 
	$(CXX) $(OBJREF) refTest.o -o refTest

bench_db: $(OBJREF) bench_db.o 
	$(CXX) $(OBJREF) bench_db.o -o bench_db

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

cserver:  $(OBJSERVER) cserver.o
	$(CXX) -o cserver $(OBJSERVER) cserver.o 
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $< -Ilibs/



clean: 
	rm -v *.o hbflow cserver refTest bench_db bench_matlab

cleanall: 
	rm -v *.o hbflow cserver refTest bench_db bench_matlab scripts/*.pyc  data/*.csv data/*.dat data/*.log db/*.xml
