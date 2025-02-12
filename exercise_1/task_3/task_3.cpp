#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>
using std::cout;
using std::endl;



float dot(const std::vector<float>& num1, const std::vector<float>& num2,int length) {

    
    cout << "size of the arrays is: " << length << endl;
    float sum = 0;
    for(int i = 0; i < length; i++){
        sum += num1[i] * num2[i];
    }


    return sum;
}



int main() {


    srand(static_cast<unsigned>(time(0))); // Seed random number generator
    int arraylength = rand() % 10 + 1;    // Random number between 1 and 100
    std::vector<float> array1(arraylength);
    std::vector<float> array2(arraylength);
    cout << "first vector is: ";
    for (int i = 0; i < arraylength; ++i) {
        array1[i] = 1.0f + static_cast<float>(rand()) / (RAND_MAX / 99.0f);
        cout << array1[i] << " ";
    }
    cout << endl;
    cout << "second vector is: ";
    for (int i = 0; i < arraylength; ++i) {
        array2[i] = 1.0f + static_cast<float>(rand()) / (RAND_MAX / 99.0f);
        cout << array2[i] << " ";
    }
    cout << endl;

    float result = dot(array1,array2, arraylength); 
    cout << "the dot product is: " << result << endl;
    return 0;
}



