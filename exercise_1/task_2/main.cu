#include <iostream>

// Main program
int main() {
	
	std::cout << 
		"The first task of the first exercises: / " \
		"CUDA-example" << std::endl;
	std::cout << "Name of the person returning the exercise: Sasu Ilmo" << std::endl;
	// for Non-Finnish: 'Matti Meikäläinen' is a common placeholder name
	
	// Query how many CUDA-compatible devices can be found
	int deviceCount;
	cudaGetDeviceCount(&deviceCount);
	
	std::cout << "Found " << deviceCount << " CUDA-devices:" << std::endl;
	
	// Käydään CUDA-yhteensopivat laitteet läpi
	// Go through the CUDA-compatible devices
	for(int i = 0; i < deviceCount; i++) {
		cudaDeviceProp prop;
		cudaGetDeviceProperties(&prop, i);
		std::cout << 
			"    " << prop.pciBusID << "/" << prop.pciDeviceID << ": " << 
			prop.name << " (CC " << prop.major << "." << prop.minor << ")" << 
			std::endl;
	}
	
	return 0;
}
