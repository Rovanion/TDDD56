// Matrix addition, CPU version
// gcc matrix_cpu.c -o matrix_cpu -std=c99

#include <stdio.h>
#include <math.h>

void printDeviceProperties(){
	cudaDeviceProp prop;
	cudaGetDeviceProperties(&prop, 0);
	printf("  Device name: %s\n", prop.name);
	printf("  Memory Clock Rate (KHz): %d\n",
				 prop.memoryClockRate);
	printf("  Memory Bus Width (bits): %d\n",
				 prop.memoryBusWidth);
	printf("  Peak Memory Bandwidth (GB/s): %f\n\n",
				 2.0*prop.memoryClockRate*(prop.memoryBusWidth/8)/1.0e6);
}


__global__
void add_matrix(float *a, float *b, float *c, int N) {
	int indexX = blockIdx.x * blockDim.x + threadIdx.x;
	int indexY = blockIdx.y * blockDim.y + threadIdx.y;
	int index = indexY * N + indexX;
	c[index] = a[index] + b[index];
}

// https://www.youtube.com/watch?v=fu0gbHnRGYk
__global__
void clear_my_bitch_out(float *c, int N) {
	int indexX = blockIdx.x * blockDim.x + threadIdx.x;
	int indexY = blockIdx.y * blockDim.y + threadIdx.y;
	int index = indexY * N + indexX;
	c[index] = 0;
}


int main() {
	printDeviceProperties();
	for (unsigned int i = 5; i < 11; i++) {
		const int N = pow(2, i);
		const int blockSize = pow(2, 4);

		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);

		float* a = new float[N*N];
		float* b = new float[N*N];
		float* c = new float[N*N];
		float* ad;
		float* bd;
		float* cd;
		const int size = N * N * sizeof(float);
		cudaMalloc((void**)&ad, size);
		cudaMalloc((void**)&bd, size);
		cudaMalloc((void**)&cd, size);

		for (int i = 0; i < N; i++) {
			for (int j = 0; j < N; j++)	{
				a[i+j*N] = 10 + i;
				b[i+j*N] = (float)j / N;
			}
		}
		cudaMemcpy(ad, a, size, cudaMemcpyHostToDevice);
		cudaMemcpy(bd, b, size, cudaMemcpyHostToDevice);

		dim3 dimBlock(blockSize, blockSize);
		dim3 dimGrid(N/blockSize, N/blockSize);
		cudaEventRecord(start);
		add_matrix<<<dimGrid, dimBlock>>>(ad, bd, cd, N);
		cudaEventRecord(stop);
		cudaThreadSynchronize();
		cudaMemcpy(c, cd, size, cudaMemcpyDeviceToHost);

		cudaEventSynchronize(stop);
		float milliseconds = 0;
		cudaEventElapsedTime(&milliseconds, start, stop);

		for (int i = 0; i < N; i++) {
			for (int j = 0; j < N; j++) {
				printf("%0.2f ", c[i+j*N]);
			}
			printf("\n");
		}
		printf(
				"GPU execution took %f milliseconds for N=%d, Blocks=%dx%d, Grid=%dx%d.\n",
				milliseconds, N, dimBlock.x, dimBlock.y, dimGrid.x, dimGrid.y);

		// Try to clean up everything on the GPU, and do it twice!
		clear_my_bitch_out<<<dimGrid, dimBlock>>>(cd, N);
		cudaDeviceReset();
	}
}
