#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <math.h>
#include <assert.h>
#include "cg_user.h"
#define DEBUG
using namespace std;

const string delimiter = " \t\n\r";
const double alpha = 1.0;
const double delta_h = 0.01;
//data structure definition
struct pin {
	double px;
	double py;
	int netNum;
};

struct gate {
	double gx;
	double gy;
	double width;
};

typedef vector<int> net;

//global variables

int chipWidth, chipHeight, numGates, numNets, numPins;
double Unit;
gate* Gates;
net* Nets;
pin* Pins;

//////////////////////////////////////////
//                                      // 
//             parser                   //
//                                      //
//////////////////////////////////////////
void
parse(char* fileName)
{
	string line;
	srand(time(NULL));
	ifstream inFile(fileName);
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
			Gates[i].width = Unit*netConnect;
			for (int j = 0; j < netConnect; j++) {
				ss >> netNum;
				Nets[netNum].push_back(i);
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
#ifdef DEBUG
	for (int i = 1; i <= numGates; i++) {
		printf("Gate %d is initialized in (%f,%f), with width %f\n", i, Gates[i].gx, Gates[i].gy, Gates[i].width);
	}
	for (int i = 1; i <= numPins; i++) {
		printf("Pin %d is at location(%f,%f)\n", i, Pins[i].px, Pins[i].py);
	}
#endif
}

//////////////////////////////////////////
//                                      // 
//        calculate halfPerim           //
//                                      //
//////////////////////////////////////////
/*
double halfPerim(net* Net) {
	double max_x = 0.0;
	double min_x = 0.0;
 	double max_y = 0.0;
	double min_y = 0.0;
	for (int i = 0; i < Net->size(); i++) {
		max_x += exp(Net[i]->gx/alpha);
		min_y += exp(-Net[i]->gy/alpha);
		max_y += exp(Net[i]->gx/alpha);
		min_y += exp(-Net[i]->gy/alpha);
	}
	max_x = alpha * log(max_x);
	min_x = -alpha * log(min_x);
	max_y = alpha * log(max_y);
	min_y = -alpha * log(min_y);
}
*/
double 
myvalue(double *x, INT n)
{	
	double sumAllNets = 0.0;
	// x if formatted as gate[1].x->position0, gate[1].y->position1, gate[2].x->p2, gate[2].y->p3...
	for (int i = 1; i <= numNets; i++) {
		double sum_xp = 0.0;
		double sum_xn = 0.0;
		double sum_yp = 0.0;
		double sum_yn = 0.0;
		int index_x, index_y;

		for (unsigned int j = 0; j < Nets[i].size(); j++) {
			index_x = 2*Nets[i][j] - 2;
			index_y = 2*Nets[i][j] - 1;
			sum_xp += exp(x[index_x]/alpha);
			sum_xn += exp(-x[index_x]/alpha);
			sum_yp += exp(x[index_y]/alpha);
			sum_yn += exp(-x[index_y]/alpha);
		}
		sumAllNets += alpha*(log(sum_xp) + log(sum_xn) + log(sum_yp) + log(sum_yn));
	}

	return sumAllNets;
}

void mygrad(double *g, double *x, INT n) {
	double v_new, v_old;
	for (int i = 0; i < n; i++) {
		v_old = myvalue(x, n);
		x[i] += delta_h;
		v_new = myvalue(x, n);
		g[i] = (v_new - v_old) / delta_h;
		x[i] -= delta_h;
	}
}


//////////////////////////////////////////
//                                      // 
//        main function                 //
//                                      //
//////////////////////////////////////////
int
main(int argc, char *argv[])
{
	if (argc < 2) {
		printf("Usage: ./exe <filename>\n");
		exit(-1);
	}
	parse(argv[1]);

	//put the value of gate position to array x
	//pointer to the x[i] vector
	double *x = new double [numGates*2];
	for (int i = 1; i <= numGates; i++) {
		x[2*(i-1)] = Gates[i].gx;
		x[2*(i-1)+1] = Gates[i].gy;
	}
	
	int n = numGates*2; //dimension of the x array
	double cg_tol;
	cg_stats Stats;
	cg_parameter Parm;
	int cg_return;

	cg_default(&Parm);
	cg_tol = 1.e-8;

	//solve it
  printf("FIRST CALL TO CG_DESCENT, cg_tol=%g\n", cg_tol);
	cg_return = cg_descent(x, n, &Stats, &Parm, cg_tol, myvalue, mygrad, NULL, NULL);
#ifdef DEBUG
	for (int i = 0; i < numGates; i++) {
		printf("gate %d is at position (%f,%f)\n", i+1, x[2*i], x[2*i+1]);
	}
	cout<<"HPWL is "<<myvalue(x,numGates*2)<<endl;
#endif
	
}
