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
	swalign.o \
	$

all: main

#build subdirectories
	
main: $(OBJS) main.o 
	$(CXX) $(OBJS) main.o -o hbflow 

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $<


clean: 
	rm *.o hbflow  .yosys.dmp .yscript.seq
