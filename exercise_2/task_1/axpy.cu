#include <iostream>
#include <cstdlib>
#include <ctime>
// Lukujen määrä
#define N 100000

// Säeryhmän koko
#define LOCAL_SIZE 1024




__global__ void axpy(double *x,double *y, double a, int n) {

	// blockIdx.x  = Säieryhmän indeksinumero
	// blockDim.x  = Säieryhmän koko
	// threadIdx.x = Säikeen lokaali indeksinumero

    //there are N-1 global ids in the calculation
    //block id is the block that we are in starting from zero
    //block dim is the number of threads in a block in this case 1024
    //thread id is the id of the thread in the block from 0 to blockdim -1
    //we can use this to get the global id for the thread
	const int global_id = blockIdx.x * blockDim.x + threadIdx.x;
	//if clause is here to stop any extra thread that were created from accessing out of bounds memory
	if(global_id < n)
		y[global_id] =  a * x[global_id] + y[global_id]; 
}



int main() {
    //seed RNG
    std::srand(static_cast<unsigned int>(std::time(0)));

    double a = std::rand() % 11;
    
    double *hostx = new double[N];
    double *hosty = new double[N];
	//fill vectors with random numbers
    for(int i = 0; i < N; i++) {
        hostx[i] = std::rand() % 11;
        hosty[i] = std::rand() % 11;
    }
	double result = 0;
    //verification sum for later verification
    for (int i = 0; i < N; i++)
    {
        result +=  a * hostx[i] + hosty[i];
    }
    
	//vector used by cuda device
	double *devicex;
    //allocating memory on the cuda device to fit the vector
	cudaMalloc((void **)&devicex, N*sizeof(double));
    //copying contents of vector hostx to devicex
	cudaMemcpy(devicex, hostx, N*sizeof(double), cudaMemcpyHostToDevice);
    
    
    //same as above but for hosty and devicey
    double *devicey;
    cudaMalloc((void **)&devicey, N*sizeof(double));

    cudaMemcpy(devicey, hosty, N*sizeof(double), cudaMemcpyHostToDevice);
	//calling axpy kernel there are N/LOCAL_SIZE+1 amount of blocks and LOCAL_SIZE amount of threads in a block
	axpy<<<N/LOCAL_SIZE+1, LOCAL_SIZE>>>(devicex, devicey, a, N);
	//copying devicey vectors content to hosty vector
	cudaMemcpy(hosty, devicey, N*sizeof(int), cudaMemcpyDeviceToHost);
	
	double cudaResult = 0; 
    //calculating sum of devicey
    for (int i = 0; i < N; i++)
    {
        cudaResult +=  hosty[i];
    }
    if (result == cudaResult)
    {
        std::cout << "The result was correct." << 
		std::endl;

    }else
    {
       std::cout << "The result was wrong." << 
		std::endl;
    }
    
    
	//freeing the memory that was allocated so that the OS can assign it to hold something else
	cudaFree(devicex);
    cudaFree(devicey);
	delete [] hostx;
    delete [] hosty;
	
	return 0;
}