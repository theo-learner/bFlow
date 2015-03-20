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
	
msim: $(OBJREF) mat.o 
	$(CXX) $(OBJREF) mat.o -o matlab 

autocor: $(OBJS) autocor.o 
	$(CXX) $(OBJS) autocor.o -o autocor 

refTest: $(OBJREF) refTest.o 
	$(CXX) $(OBJREF) refTest.o -o refTest

dbTest: $(OBJREF) dbTest.o 
	$(CXX) $(OBJREF) dbTest.o -o dbTest

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

mainserver:  $(OBJSERVER) mainserver.o
	$(CXX) -o serverMain $(OBJSERVER) mainserver.o 
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $< -Ilibs/



clean: 
	rm -v *.o hbflow serverMain matlab refTest  dbTest

cleanall: 
	rm -v *.o hbflow serverMain matlab refTest dbTest  scripts/*.pyc  data/*.csv data/*.dat data/*.log db/*.xml
