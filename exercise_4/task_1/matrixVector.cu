#include <iostream>
#include <cstdlib>
#include <ctime>
#include <stdio.h>
#include <random>
#include <vector>
// Lukujen määrä
#define N 100

#define M 100


using namespace std;

__global__ void matrixVector(double *x,double *y, double mu,int n,int m){

        int row = blockIdx.y * blockDim.y + threadIdx.y;
        int col = blockIdx.x * blockDim.x + threadIdx.x;
        double yy = 0;
    
   
        int idx = row * m + col;
        
        if(row < n && col < m){
            yy = (4.0 + mu)*x[idx];
            if(0 < row) {
                yy = yy - x[(row-1) * m + col];
            }
            if(row < n-1) {
                yy = yy - x[(row+1) * m + col];
            }
            if (0 < col) {
                yy = yy - x[row * m + (col-1)];
            } 
            if (col < m-1) {
            yy = yy - x[row * m + (col+1)];
            }
            y[idx] = yy;
        }
        
}




int main() {

    
    //RNG
    //seed RNG
    random_device rd;                          
    mt19937 gen(12345);
    //muista vaihtaa real eikä int                  
    uniform_real_distribution<double> dist(-1, 5);
    uniform_int_distribution<int> distint(5000, 10000);
    int rows = distint(gen);
    int cols = distint(gen);


    vector<vector<double>> matrix(rows, vector<double>(cols));
    vector<vector<double>> matriy(rows, vector<double>(cols));
    vector<vector<double>> gpuMatrix(rows, vector<double>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix[i][j] = dist(gen);
        }
    }
    //muista vaihtaa real eikä int
    uniform_real_distribution<double> dist2(1, 5);
    double mu = dist2(gen);
    
    
    //turn matrix into vector
    vector<double> vector(rows * cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            vector[i * cols + j] = matrix[i][j];
        }
    }

    //allocating memory
    double *devicex;
    cudaMalloc(&devicex, rows * cols * sizeof(double));

    cudaMemcpy(devicex, vector.data(), rows * cols * sizeof(double), cudaMemcpyHostToDevice);

    double *devicey;
    cudaMalloc(&devicey, rows * cols * sizeof(double));
    //defining dimensions and blocks
    dim3 blockDim(16, 16); // 16x16 threads per block
    dim3 gridDim((cols + blockDim.x - 1) / blockDim.x, (rows + blockDim.y - 1) / blockDim.y);

    matrixVector<<<gridDim, blockDim>>>(devicex, devicey, mu,rows,cols);
	



    cudaMemcpy(vector.data(), devicey, rows * cols * sizeof(double), cudaMemcpyDeviceToHost);
    //vector to matrix so we can compare results
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            gpuMatrix[i][j] = vector[i * cols + j];
        }
    }
    

    for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
        double yy = (4.0 + mu) * matrix[i][j];
        if (i > 0) {
            yy -= matrix[i - 1][j];
        }
        if (i < rows - 1) {
            yy -= matrix[i + 1][j];
        }
        if (j > 0) {
            yy -= matrix[i][j - 1];
        }
        if (j < cols - 1) {
            yy -= matrix[i][j + 1];
        }
        matriy[i][j] = yy;
    }
}








    
    cout << "matrix size is: " << rows << "*" << cols << endl;


    int diffAmount = 0;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if(fabs(matriy[i][j] - gpuMatrix[i][j]) > 0 ){
                cout << "Diff: " << fabs(matriy[i][j] - gpuMatrix[i][j]) << " GPU result was: " << gpuMatrix[i][j] << " " << "CPU result was: " << matriy[i][j] << endl;

                diffAmount++;
            }
            
        }
        
    }
    
    
    cout << "number of differences: " << diffAmount << endl;
    float diff = (static_cast<float>(diffAmount) / (rows * cols)) * 100;
    cout << "difference in percentage: " << diff << endl;

	
    //freeing the memory that was allocated
    cudaFree(devicex);
    cudaFree(devicey);


	
	
	return 0;
}