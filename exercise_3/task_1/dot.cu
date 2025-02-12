#include <iostream>
#include <cstdlib>
#include <ctime>
#include <stdio.h>
// Lukujen määrä
#define N 1000000

// Säeryhmän koko
#define LOCAL_SIZE 1024

#define INIT_M 128

using namespace std;

__device__ double dotProductSum = 0.0;


__global__ void dotProduct(double *x,double *y, double *res, int n) {
    
    __shared__ double localsum[LOCAL_SIZE];
    const int global_id = blockIdx.x * blockDim.x + threadIdx.x;
    const int global_size = gridDim.x * blockDim.x;
    const int local_id = threadIdx.x;
    localsum[local_id] = 0.0;
    
    //1024 numbers ot add
    for(int i = global_id; i < n; i += global_size)
		localsum[local_id] += x[i] * y[i];

    __syncthreads();


    //reduction method initially by me but fixed by ChatGPT
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (local_id < stride) {
            localsum[local_id] += localsum[local_id + stride];
        }
        __syncthreads();
    }

    if(threadIdx.x == 0)
        atomicAdd(res,localsum[0]);

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
    
    
    
    
    
    
    
    const int partialSumCount = (N-1)/INIT_M+1;
    
    const int workGroupCount = (partialSumCount-1)/LOCAL_SIZE+1;

    const int workItemCount = workGroupCount*LOCAL_SIZE;
    
    double res;
    double *deviceRes;
	cudaMalloc((void **)&deviceRes, sizeof(double));
    cudaMemset(deviceRes, 0, sizeof(double));
    
    dotProduct<<<workGroupCount, LOCAL_SIZE>>>(devicex, devicey, deviceRes, N);
	//copying deviceRes vector content to res vector
	cudaMemcpy(&res, deviceRes, sizeof(double), cudaMemcpyDeviceToHost);

    double realValue = 0.0;
	
    for (int i = 0; i < N; i++)
    {
        realValue += hostx[i] * hosty[i];
    }
    



	cout << "Sum value: " << res << std::endl;
	cout << "Real value: " << realValue << endl;
	cout << "Diff: " << fabs(res-realValue) << std::endl;




	//freeing the memory that was allocated so that the OS can assign it to hold something else
	cudaFree(devicex);
    cudaFree(devicey);
    cudaFree(deviceRes);
	delete [] hostx;
    delete [] hosty;
	
	return 0;
}