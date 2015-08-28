#!/bin/bash

./gSpan6/gSpan -f dotdb/ram/db_gspan -s .99 -i -o  
./gSpan6/gSpan -f dotdb/count/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/fifo/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/fir/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/iir/db_gspan -s .99 -i -o
./gSpan6/gSpan -f dotdb/image/db_gspan -s .99 -i -o
./gSpan6/gSpan -f dotdb/life/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/mult/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/ram/db_gspan -s .99 -i -o 
./gSpan6/gSpan -f dotdb/uart/db_gspan -s .99 -i -o 

