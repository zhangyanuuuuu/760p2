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
//parameters needs to be turned
const double alpha = 1.0;
const double r = 2.0;
const double delta_h = 0.01;
const double grid_length = 0.5;

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

double chipWidth, chipHeight;
int	numGates, numNets, numPins;
double Unit;
int Ng;
double Cg;
double area;
gate* Gates;
net* Nets;
pin* Pins;
int** gateNetList;
int* gateNetListSize;

//////////////////////////////////////////
//                                      // 
//             parser                   //
//                                      //
//////////////////////////////////////////
void
parse(char* fileName)
{
	area = 0.0;
	string line;
	srand(time(NULL));
	ifstream inFile(fileName);
	if (inFile.is_open()) {
		//readin the first line to get the chip width, height, and Unit 
		inFile >> chipWidth >> chipHeight >> Unit;		

		//readin the second line to get the num of gates and nets
		inFile >> numGates >> numNets;

		Ng = chipHeight*chipWidth/grid_length;
#ifdef DEBUG
		cout<<"chip width is "<<chipWidth<<" and chip height is "<<chipHeight<<endl;
		cout<<"unit size is "<<Unit<<endl;
		cout<<"number of gates is "<<numGates<<" and num nets is "<<numNets<<endl;
		cout<<"number of grids is "<<Ng<<endl;
#endif


		Gates = new gate [numGates + 1];
		gateNetListSize = new int [numGates + 1];
		gateNetList = new int* [numGates + 1];
		for (int i = 1; i <= numGates; i++) {
			Gates[i].gx = rand() % (int)chipWidth;
			Gates[i].gy = rand() % (int)chipHeight;
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
			gateNetListSize[i] = netConnect;
			gateNetList[i] = new int [netConnect];
			Gates[i].width = Unit*netConnect;
			area += Gates[i].width;
			for (int j = 0; j < netConnect; j++) {
				ss >> netNum;
				Nets[netNum].push_back(i);
				gateNetList[i][j] = netNum;
			}
		}
		Cg = area/((double)Ng * 1.0);

		getline(inFile, line);
		stringstream ss(line);
		ss >> numPins;
#ifdef DEBUG
		cout<<"Toal are is "<<area<<" and Ng is "<<Ng<<" Cg is "<<Cg<<endl;
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

//incremental version of grad
void
mygrad(double *g, double *x, INT n) 
{
	double xp, xn, yp, yn, xp_plus, xn_plus, yp_plus, yn_plus, xp_minus, xn_minus, yp_minus, yn_minus;
	double delta_x, delta_y;
	int gate_idx, net_idx;
	int index_x, index_y;
	for (int i = 0; i < n; i += 2) { //each time calculate x and y for the gate
		gate_idx = i/2+1;
		delta_x = delta_y = 0.0;
		for (int j = 0; j < gateNetListSize[gate_idx]; j++) { // each net
			net_idx = gateNetList[gate_idx][j]; //get the net number
			xp = xn = yp = yn = 0;
			for (unsigned int k = 0; k < Nets[net_idx].size(); k++) { //each gate for this net
				index_x = 2*Nets[net_idx][k]-2;
				index_y = 2*Nets[net_idx][k]-1;
				xp += exp(x[index_x]/alpha);
				xn += exp(-x[index_x]/alpha);
				yp += exp(x[index_y]/alpha);
				yn += exp(-x[index_y]/alpha);
			}

			xp_plus = xp - exp(x[i]/alpha) + exp((x[i]+delta_h)/alpha);
			xn_plus = xn - exp(-x[i]/alpha) + exp(-(x[i]+delta_h)/alpha);
			yp_plus = yp - exp(x[i+1]/alpha) + exp((x[i+1]+delta_h)/alpha);
			yn_plus = yn - exp(-x[i+1]/alpha) + exp(-(x[i+1]+delta_h)/alpha);

			xp_minus = xp - exp(x[i]/alpha) + exp((x[i]-delta_h)/alpha);
			xn_minus = xn - exp(-x[i]/alpha) + exp(-(x[i]-delta_h)/alpha);
			yp_minus = yp - exp(x[i+1]/alpha) + exp((x[i+1]-delta_h)/alpha);
			yn_minus = yn - exp(-x[i+1]/alpha) + exp(-(x[i+1]-delta_h)/alpha);

			delta_x += alpha*(log(xp_plus)-log(xp_minus)+log(xn_plus)-log(xn_minus));
			delta_y += alpha*(log(yp_plus)-log(yp_minus)+log(yn_plus)-log(yn_minus));
		}
		g[i] = delta_x/(2*delta_h);
		g[i+1] = delta_y/(2*delta_h);
	}
}

// plain version of grad
/*
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
*/

// non numerical version
/*
void
mygrad(double *g, double *x, INT n) 
{
	for (int i = 0; i < n; i++) {
		g[i] = 0.0;
	}
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

		for (unsigned int j = 0; j < Nets[i].size(); j++) {
			index_x = 2*Nets[i][j] - 2;
			index_y = 2*Nets[i][j] - 1;
			g[index_x] += exp(x[index_x]/alpha) / sum_xp;
			g[index_x] -= exp(-x[index_x]/alpha) / sum_xn;
			g[index_y] += exp(x[index_y]/alpha) / sum_yp;
			g[index_y] -= exp(-x[index_y]/alpha) / sum_yn;
		}
	}
}
*/

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
	cg_tol = 1.e-5;

#ifdef DEBUG
	double *g = new double [n];
	mygrad(g,x,n);
	for (int i = 0; i < n ; i++) {
		cout<<"Derevative for gate "<<i/2+1<<" is "<<g[i]<<endl;
	}
#endif

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
