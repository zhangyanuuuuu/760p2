#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <math.h>
#include <assert.h>
#include "cg_user.h"
#undef DEBUG
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
int numGrids;
int *NetPins;
//////////////////////////////////////////
//                                      // 
//             parser                   //
//                                      //
//////////////////////////////////////////
//
#define max(a,b) (a>b?a:b)
#define min(a,b) (a<b?a:b)
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

		Ng = chipHeight*chipWidth/(grid_length*grid_length);
        numGrids=sqrt(Ng);
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
		NetPins=new int [numNets+1];
 		for(int i=0;i<=numNets;i++) NetPins[i]=0;
		for (int i = 1; i <= numPins; i++) {
			getline(inFile, line);
			stringstream ss(line);
			ss >> count;
#ifdef DEBUG
			assert(count == i);
#endif
			ss >> Pins[i].netNum >> Pins[i].px >> Pins[i].py;
    			NetPins[Pins[i].netNum]=i;
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

		if( NetPins[i]!=0){
                        sum_xp +=exp(Pins[NetPins[i]].px/alpha);
			sum_xn +=exp(-Pins[NetPins[i]].px/alpha);
			sum_yp +=exp(Pins[NetPins[i]].py/alpha);
			sum_yn +=exp(-Pins[NetPins[i]].py/alpha);
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

			if(NetPins[net_idx]!=0){
                        xp +=exp(Pins[NetPins[net_idx]].px/alpha);
			xn +=exp(-Pins[NetPins[net_idx]].px/alpha);
			yp +=exp(Pins[NetPins[net_idx]].py/alpha);
			yn +=exp(-Pins[NetPins[net_idx]].py/alpha);
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
double p_potential(double x){
 double ans=1/(1+exp(2*20*(x-r/2)));
 return ans;
}

double gate_covered_grids(double x, double y, int i, double**gr){ 
   double val=0;
   int left,right,up,down;
   double potential;
        left=max(0,x-Gates[i].width/2-r);
        right=min(numGrids-1,x+Gates[i].width/2+r);
        up=max(0,y-r);
        down=min(numGrids-1,y+r);
        for(int row=up;row<=down;row++)
          for(int col=left;col<=right;col++){
            potential=p_potential(fabs(row-x))*p_potential(fabs(col-y))*Gates[i].width/(r*r);
           // val+=pow(potential-Cg,2);
            gr[row][col]+=potential;

        }
  // cout<<"gate"<<val<<endl;

   return val;
 
}
double
myval_overlap(double *x, INT n){
   double val=0;
   double **gr=new double* [numGrids];
   for(int i=0;i<numGrids;i++){

            gr[i]=new double[numGrids];
    }
   for(int i=0;i<numGrids;i++)
     for(int j=0;j<numGrids;j++){
        gr[i][j]=0;
    }
   for(int i=0;i<n;i+=2){
      gate_covered_grids(x[i],x[i+1],i/2+1,gr);
     }


    for(int i=0;i<numGrids;i++)
      for(int j=0;j<numGrids;j++)
        {
            val+=pow(gr[i][j]-Cg,2);
        }  
#ifdef DEBUG 
   cout<<"val for overlap"<<val<<endl;
#endif
   return val;
}
double overlap_update(double oldpos[2], double newpos[2], int i, double**gr){

   double val=0;
   int left,right,up,down;
   double potential;
   double **gg=new double* [numGrids];
   for(int k=0;k<numGrids;k++){

            gg[k]=new double[numGrids];
    }
        left=max(0,min(oldpos[0],newpos[0])-Gates[i].width/2-r);
        right=min(numGrids-1,max(oldpos[0],newpos[0])+Gates[i].width/2+r);
        up=max(0,min(oldpos[1],newpos[1])-r);
        down=min(numGrids-1,max(oldpos[1],newpos[1])+r);
   for(int row=up;row<=down;row++)
    for(int col=left;col<=right;col++){
        gg[row][col]=gr[row][col];
        gg[row][col]-=p_potential(fabs(row-oldpos[0]))*p_potential(fabs(col-oldpos[1]))*Gates[i].width/(r*r);

        gg[row][col]+=p_potential(fabs(row-newpos[0]))*p_potential(fabs(col-newpos[1]))*Gates[i].width/(r*r);
        
        val+=-pow(gr[row][col]-Cg,2)+pow(gg[row][col]-Cg,2);
    }
   return val;
}
void  
mygrad_overlap(double *g, double *x, INT n){
   double **gr=new double* [numGrids];
   double old[2],nnew[2];
    for(int i=0;i<numGrids;i++){

            gr[i]=new double[numGrids];
    }
   for(int i=0;i<numGrids;i++)
     for(int j=0;j<numGrids;j++){
        gr[i][j]=0;
    }
   for(int i=0;i<n;i+=2){
      gate_covered_grids(x[i],x[i+1],i/2+1,gr);
     }
   double potential;
   int left,right,up,down;
     double x_minus,x_plus,y_minus,y_plus,x_delta,y_delta;
    for(int i=0;i<n;i+=2){      
      /*  x_plus=gate_covered_grids(x[i]+delta_h,x[i+1],i/2+1);
        x_minus=gate_covered_grids(x[i]-delta_h,x[i+1],i/2+1);
        g[i]=(x_plus-x_minus)/(2*delta_h);
        y_plus=gate_covered_grids(x[i],x[i+1]+delta_h,i/2+1);
        y_minus=gate_covered_grids(x[i],x[i+1]-delta_h,i/2+1);
        g[i+1]=(y_plus-y_minus)/(2*delta_h);               
    */
        old[0]=x[i];
        old[1]=x[i+1];
        nnew[0]=x[i]+delta_h;
        nnew[1]=x[i+1];
        x_plus=overlap_update(old,nnew,i/2+1,gr);
        nnew[0]=x[i]-delta_h;
        x_minus=overlap_update(old,nnew,i/2+1,gr);
        nnew[0]=x[i];
        nnew[1]=x[i+1]+delta_h;
        y_plus=overlap_update(old,nnew,i/2+1,gr);
        nnew[1]=x[i+1]-delta_h;
        y_minus=overlap_update(old,nnew,i/2+1,gr);

        g[i]=(x_plus)/(delta_h);
        g[i+1]=(y_plus)/(delta_h);               
//		cout<<"Derevative for gate "<<i/2+1<<" is "<<g[i]<<endl;
    }
#ifdef DEBUG
	for (int i = 0; i < n ; i++) {
		cout<<"Derivative for gate "<<i/2+1<<" is "<<g[i]<<endl;
	}
#endif
}
double get_boundary_pel(double x, double y, int i){
       
   double width;
   double pel=0;
        width=Gates[i/2+1].width/2;
        if(x-width<0) pel+=pow((width-x)/alpha,2);
        if(x+width>100) pel+=pow((x+width-100)/alpha,2);
        if(y-0.5<0) pel+=pow((0.5-y)/alpha,2);
        if(y+0.5>100) pel+=pow((y+0.5-100)/alpha,2);
  return pel;
}

double myval_boundary(double *x, INT n){
   double pel=0;
   for(int i=0;i<n;i+=2)
    {
       pel+= get_boundary_pel(x[i],x[i+1],i);
    }
   return pel;

}

double mygrad_boudary(double*g, double *x, INT n){
   double x_plus,x_minus,y_plus,y_minus;
   for(int i=0;i<n;i+=2){
        x_plus=get_boundary_pel(x[i]+delta_h,x[i+1],i);
        x_minus=get_boundary_pel(x[i]-delta_h,x[i+1],i);
        y_plus=get_boundary_pel(x[i],x[i+1]+delta_h,i);
        y_minus=get_boundary_pel(x[i],x[i+1]-delta_h,i);
       g[i]=(x_plus-x_minus)/(2*delta_h);
       g[i+1]=(y_plus-y_minus)/(2*delta_h);

    }


}
double 
costfun(double *x, INT n){
   return myvalue(x,n)+myval_overlap(x,n)+myval_boundary(x,n);

}

void
costfungrad(double *g, double *x, INT n){
   double *g1=new double [n];
   double *g2=new double [n];
   double *g3=new double [n];
   mygrad(g1,x,n);
   mygrad_overlap(g2,x,n);
   mygrad_boudary(g3,x,n);
   for(int i=0;i<n;i++)
     g[i]=g1[i]+g2[i]+g3[i];

}

// plain version of grad
/*
void 
myval_overlap(double *x, INT n){
   double val=0;
   double potential;
   int left,right,up,down;
   for(int i=0;i<n;i+=2){
        left=x[i]-Gates[i/2].width/2-r;
        right=x[i]+Gates[i/2].width/2+r;
        up=x[i+1].gy-r;
        down=x[i+1].gy+r;
        for(int row=up;row<=down;row++)
          for(int col=left;col<=right;col++){
            potential=p_potential(fabs(row-x[i]))*p_potential(fabs(col-x[i+1]))*Gate[i/2].width/(r*r);
            val+=pow(potential-Cg,2);

        }
        


    }
   return val;
 
}

void  
mygrad_overlap(double *g, double *x, INT n){
    
   double potential;
   int left,right,up,down;
   double x_minus,x_plus,y_minus,y_plus,x_delta,y_delta;
    for(int i=0;i<n;i+=2){      
        left=x[i]-Gates[i/2].width/2-r;
        right=x[i]+Gates[i/2].width/2+r;
        up=x[i+1].gy-r;
        down=x[i+1].gy+r;

        for(int row=up;row<=down;row++)
          for(int col=left;col<=right;col++){
            x_plus=p_potential(fabs(row-x[i]-delta_h))*p_potential(fabs(col-x[i+1]))*Gate[i/2].width/(r*r);
           
            x_minus=p_potential(fabs(row-x[i]+delta_h))*p_potential(fabs(col-x[i+1]))*Gate[i/2].width/(r*r);

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
   #ifdef DEBUG
    //argv[1]="./benchmark/toy1";
   #endif
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

	double *g = new double [n];
	costfungrad(g,x,n);
#ifdef DEBUG
	for (int i = 0; i < n ; i++) {
		cout<<"Derivative for gate "<<i/2+1<<" is "<<g[i]<<endl;
	}
#endif

	//solve it
  printf("FIRST CALL TO CG_DESCENT, cg_tol=%g\n", cg_tol);
	cg_return = cg_descent(x, n, &Stats, &Parm, cg_tol, costfun, costfungrad, NULL, NULL);
#ifdef DEBUG
	for (int i = 0; i < numGates; i++) {
		printf("gate %d is at position (%f,%f)\n", i+1, x[2*i], x[2*i+1]);
	}
	cout<<"HPWL is "<<costfun(x,numGates*2)<<endl;
#endif
    for (int i=0;i<numGates;i++)
        printf("%d %f %f\n",i+1,x[2*i],x[2*i+1]);	
}
