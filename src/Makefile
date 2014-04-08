all: placer pv1 pv2

CC = g++ -lm -W -Wall -pedantic -Wmissing-prototypes \
	-Wredundant-decls  -Wdisabled-optimization \
	-g -fexceptions -Wno-parentheses -Wshadow -Wcast-align \
	-Winline  -Wno-unknown-pragmas -g

OBJ = cg_descent.o

$(OBJ): $(INCLUDE)

placer: $(OBJ) main.cpp
	$(CC) -o placer main.cpp $(OBJ)

pv1: $(OBJ) v1.cpp
	$(CC) -o pv1 v1.cpp $(OBJ)

pv2: $(OBJ) v2.cpp
	$(CC) -o pv2 v2.cpp $(OBJ)

clean:
	rm *.o

purge:
	rm *.o placer pv1
