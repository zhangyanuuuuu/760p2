#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <stdlib.h>
#include <assert.h>

void
parse(int argc, char* fileName)
{
	string line;
	if (argc < 2) {
		printf("Usage: ./exe <filename>\n");
		exit(-1);
	}
	ifstream inFile(argv[1]);
	if (inFile.is_open()) {
		//readin the first line to get the chip width, height, and Unit 
		inFile >> chipWidth >> chipHeight >> Unit;		

		//readin the second line to get the num of gates and nets
		inFile >> numGates >> numNets;

#ifdef DEBUG
		cout<<"chip width is "<<chipWidth<<" and chip height is "<<chipHeight<<endl;
		cout<<"unit size is "<<Unit<<endl;
		cout<<"number of gates is "<<numGates<<" and num nets is "<<numNets<<endl;
#endif
		
		Gates = new gate [numGates + 1];
		for (int i = 1; i <= numGates; i++) {
			Gates[i].gx = rand() % chipWidth;
			Gates[i].gy = rand() % chipHeight;
		}
		Nets = new net [numNets + 1];
		srand(time(NULL));
		//escape the current line
		getline(inFile, line);

		//temp variables
		int count, netConnect, netNum;
		for (int i = 1; i <= numGates; i++) {
			getline(inFile,line);
#ifdef DEBUG
			cout << line << endl;
#endif
			stringstream ss(line);
			ss >> count;
#ifdef DEBUG
			assert(count == i);
#endif
			ss >> netConnect;
			for (int j = 0; j < netConnect; j++) {
				ss >> netNum;
				Nets[netNum].push_back(&Gates[i]);
			}
		}

		getline(inFile, line);
		stringstream ss(line);
		ss >> numPins;
#ifdef DEBUG
		cout<<"Num of pins is "<<numPins<<endl;
#endif
		Pins = new pin [numPins + 1];
		for (int i = 1; i <= numPins; i++) {
			getline(inFile, line);
			stringstream ss(line);
			ss >> count;
#ifdef DEBUG
			assert(count == i);
#endif
			ss >> Pins[i].netNum >> Pins[i].px >> Pins[i].py;
		}
	} else {
		cout<<"Unable to open file\n";
		exit(-1);
	}
}
