#include <iostream>
#include <cstdlib>
#include <ctime>
#include <omp.h>
#include <chrono>
#include<cmath>



double dotMatrixProduct(double** a, double* x, double* y, int N, int tCount) {
    double result = 0;
    omp_set_num_threads(tCount);
    #pragma omp parallel
    {
        double sum = 0;
        #pragma omp for nowait
        for (int i = 0; i < N; i++) {
            // Sum for each row
            double rowSum = 0;  
            for (int j = 0; j < N; j++) {
                rowSum += a[i][j] * x[i] * y[j];
            }
            sum += rowSum;
        }

        #pragma omp atomic
        result += sum;  // Atomic to stop race condition
    }

    return result;
}


int main()
{
    int N = 1000;
    int rows = N, cols = N;
    double** matrix = new double*[rows];
    for (int i = 0; i < rows; i++) {
        matrix[i] = new double[cols];
    }

    // Fill matrix with values
    int value = 2;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix[i][j] = value;
        }
    }

    std::srand(static_cast<unsigned int>(std::time(0)));

    
    double *x = new double[N];
    double *y = new double[N];
	for(int i = 0; i < N; i++) {
        x[i] = std::rand() % 11;
        y[i] = std::rand() % 11;
    }

    //verification sum to make sure that the subroutine gives correct answer
    auto start = std::chrono::high_resolution_clock::now();
    double sum = 0;
    for(int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++)
        {
            sum = sum + matrix[i][j] * x[i] * y[j]; 
        }
    }

    auto end = std::chrono::high_resolution_clock::now();


    //comparison times and flops
    std::chrono::duration<double, std::milli> elapsed = end - start;
    std::cout << "results with no parallelizing:";
    std::cout << "Elapsed time: " << elapsed.count() << " ms\n";
    std::cout << "Flops: " << 1.0E-9* pow(3*N,2)  /elapsed.count() << " GFlops" << std::endl;

    for (size_t i = 1; i < 11; i++)
    {
    start = std::chrono::high_resolution_clock::now();
    double result = dotMatrixProduct(matrix, x, y , N,i);
    
    end = std::chrono::high_resolution_clock::now();
    //3n^2 calculations
    
    
    //check to see if reusult was correct
    if (result == sum)
    {
        std::cout << "The result was correct. " << "result and sum were: " << result <<
		std::endl;
    }else
    {
       std::cout << "The result was wrong." << "result was: "  << result << " and sum was: " << sum << 
		std::endl;
    }
    
    elapsed = end - start;
    std::cout << "results with " << i << "threads:";
    std::cout << "Elapsed time: " << elapsed.count() << " ms\n";
    std::cout << "Flops: " << 1.0E-9* pow(3*N,2)  /elapsed.count() << " GFlops" << std::endl;
    }


    //delete matrix and arrays
    for(int i = 0; i < N; i++)
        delete [] matrix[i];
    delete [] matrix;
    delete [] x;
    delete [] y;
    return 0;
}
