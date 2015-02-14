CXX = g++

CFLAGS = \
		-Wall \
		-g \
		-Wno-unused-function \
		-Wno-write-strings \
		-Wno-sign-compare \
		-Wno-unused-but-set-variable \
		-Iyosys

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
	$

all: main mainserver

#build subdirectories
	
main: $(OBJS) main.o 
	$(CXX) $(OBJS) main.o -o hbflow 

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

mainserver: $(OBJS) $(OBJSERVER) mainserver.o
	$(CXX) $(OBJSERVER) $(OBJS) mainserver.o -o serverMain
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $<


clean: 
	rm *.o hbflow  .yosys.dmp .yscript.seq
