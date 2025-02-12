#include <iostream>
#include <cstdlib>
#include <ctime>
#include <stdio.h>
#include <random>
#include <vector>
#include <math.h>
#include <chrono>

using namespace std;

// Lukujen määrä
#define N 100

#define M 100



//only when threads > distances
//TODO: fix so that works on matrixes of all sizes
__global__ void matrixDistance(double *matrix, double *result, int rows, int cols){

    const int global_id = blockIdx.x * blockDim.x + threadIdx.x;
    if (global_id < rows * rows){

        int i = global_id / rows;   // Row index
        int j = global_id % rows;
        double localSum = 0.0;
    

        if(i < rows && j < rows){
            for (int k = 0; k < cols; ++k) {
                double diff = pow(matrix[i * cols + k] - matrix[j * cols + k],2);
                localSum += diff;
            }

            result[i * rows + j] =  sqrt(localSum);
        
        }
    }
    
    


}

//implements a stride so that we can calculate matrixes where there are more distances than threats
__global__ void matrixDistanceNoSizeLimit(double *matrix, double *result, int rows, int cols){

    const int global_id = blockIdx.x * blockDim.x + threadIdx.x;
    
    
    for (int stride = global_id; stride < rows*rows; stride += gridDim.x * blockDim.x) {
        int i = stride / rows;  // Row index
        int j = stride % rows;
        double localSum = 0.0;
        if(i < rows && j < rows){
            for (int k = 0; k < cols; ++k) {
                double diff = pow(matrix[i * cols + k] - matrix[j * cols + k],2);
                localSum += diff;
            }

            result[i * rows + j] =  sqrt(localSum);
        
        }
    }




    


}



int main() {

    //RNG
    //seed RNG
    random_device rd;                          
    mt19937 gen(12345);             
    uniform_real_distribution<double> dist(-1, 5);
    uniform_int_distribution<int> distint(100, 500);
    int rows = 5000; //distint(gen);
    int cols = 10;  //distint(gen);


    vector<vector<double>> matrix(rows, vector<double>(cols));
    vector<vector<double>> results(rows*cols, vector<double>(cols*rows));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix[i][j] = dist(gen);
        }
    }
    
    
    
    
    auto start = chrono::high_resolution_clock::now();
    //my orginal CPU implementation
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < rows; j++) {
            double distance = 0.0;
            for (int k = 0; k < cols; k++) {
                distance += pow(matrix[i][k] - matrix[j][k], 2);
            }
            distance = sqrt(distance);
            results[i][j] = distance;
        }
    } 
    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double, std::milli> elapsed = end - start;
    cout << "results with no parallelizing:";
    cout << "Elapsed time: " << elapsed.count() << " ms\n";
    cout << endl;
    

    //calculating distance matrix on the CPU
    //I modified my own implementation to use symmetry with a solution I found online
    start = chrono::high_resolution_clock::now();
    for (int i = 0; i < rows; ++i) {
        for (int j = i + 1; j < rows; ++j) {
            double distance = 0.0;
            for (int k = 0; k < cols; ++k) {
                distance += pow(matrix[i][k] - matrix[j][k], 2);
            }
            distance = sqrt(distance);
            results[i][j] = distance;
            results[j][i] = distance; // Symmetric
        }
    }
    end = std::chrono::high_resolution_clock::now();
    elapsed = end - start;
    cout << "results with no parallelizing but with symmetry optimization:";
    cout << "Elapsed time: " << elapsed.count() << " ms\n";
    cout << endl;
    
    //matrix to vector
    vector<double> matrix2d(rows * cols);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix2d[i * cols + j] = matrix[i][j];
        }
    }

    //allocating memory
    double *deviceMatrix;
    cudaMalloc(&deviceMatrix, rows * cols * sizeof(double));

    cudaMemcpy(deviceMatrix, matrix2d.data(), rows * cols * sizeof(double), cudaMemcpyHostToDevice);
    vector<double> vectorResults(rows * rows);
    for (size_t i = 0; i < vectorResults.size(); i++)
    {
        vectorResults[i] = 0;
    }
    double *deviceResults;

    cudaMalloc(&deviceResults, rows * rows * sizeof(double));

    cudaMemcpy(deviceResults, vectorResults.data(), rows * rows * sizeof(double), cudaMemcpyHostToDevice);
    
    //TODO: optimize thread and block count for the GPU
    int totalThreads = rows * rows;
    int blockSize = 256; 
    int gridSize = (totalThreads + blockSize - 1) / blockSize;
    start = chrono::high_resolution_clock::now();
    matrixDistanceNoSizeLimit<<<gridSize, blockSize>>>(deviceMatrix, deviceResults, rows, cols);
    end = chrono::high_resolution_clock::now();
    //just to check if something went wrong with the kernel
    //CUDA doesn't provide errors automatically so they
    //have to be checked like this
    cudaError_t err = cudaPeekAtLastError();
    if (err != cudaSuccess) {
        std::cerr << "CUDA error: " << cudaGetErrorString(err) << std::endl;
        return 1;
    }
    cudaDeviceSynchronize();
    elapsed = end - start;
    cout << "results with parallelizing:";
    cout << "Elapsed time: " << elapsed.count() << " ms\n";
    cout << endl;
    

    cudaMemcpy(vectorResults.data(), deviceResults, rows * rows * sizeof(double), cudaMemcpyDeviceToHost);
    
    //no point printing the matrix when there are more than 20 rows
    /*
    cout << endl;
    for (int i = 0; i < rows; i++){
        for (int j = 0; j < rows; j++){
            cout << vectorResults[i * rows + j] << " ";
        }
        cout << endl;
    } */

    cudaFree(deviceMatrix);
    cudaFree(deviceResults);


    return 0;
}