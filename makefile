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
	main.o \
	sw/src/ssw.o \
	$

all: main

#build subdirectories
	
main: $(OBJS)
	$(CXX) $(OBJS) -o main

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $<




clean: 
	rm *.o
