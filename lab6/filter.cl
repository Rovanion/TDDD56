/*
 * Image filter in OpenCL
 */

/* If we understand this correctly the current OpenCL and CUDA
 * terms corresponds to each other:
 * gridDim                         == get_num_groups()
 * blockDim                        == get_local_size()
 * blockIdx                        == get_group_id()
 * threadIdx                       == get_local_id()
 * blockIdx * blockDim + threadIdx == get_global_id()
 * gridDim * blockDim              == get_global_size()
 */


#define KERNELSIZE 2

__kernel void filter(__global unsigned char *image, __global unsigned char *out, const unsigned int n, const unsigned int m) {
  unsigned int i = get_global_id(1) % 512;
  unsigned int j = get_global_id(0) % 512;
  int k, l;
  unsigned int sumx, sumy, sumz;

	int divby = (2*KERNELSIZE+1)*(2*KERNELSIZE+1);

	/* If we understand this correctly the current OpenCL and CUDA
	 * terms corresponds to each other:
	 * gridDim                         == get_num_groups()
	 * blockDim                        == get_local_size()
	 * blockIdx                        == get_group_id()
	 * threadIdx                       == get_local_id()
	 * blockIdx * blockDim + threadIdx == get_global_id()
	 * gridDim * blockDim              == get_global_size()
	 */


	// If inside image
	if (j < n && i < m) {
		if (i >= KERNELSIZE && i < m-KERNELSIZE && j >= KERNELSIZE && j < n-KERNELSIZE) {
			// Filter kernel
			sumx=0;sumy=0;sumz=0;
			for(k=-KERNELSIZE;k<=KERNELSIZE;k++)
				for(l=-KERNELSIZE;l<=KERNELSIZE;l++) {
					sumx += image[((i+k)*n+(j+l))*3+0];
					sumy += image[((i+k)*n+(j+l))*3+1];
					sumz += image[((i+k)*n+(j+l))*3+2];
				}
			out[(i*n+j)*3+0] = sumx/divby;
			out[(i*n+j)*3+1] = sumy/divby;
			out[(i*n+j)*3+2] = sumz/divby;
		}
		// Edge pixels are not filtered
		else {
			out[(i*n+j)*3+0] = image[(i*n+j)*3+0];
			out[(i*n+j)*3+1] = image[(i*n+j)*3+1];
			out[(i*n+j)*3+2] = image[(i*n+j)*3+2];
		}
	}
}
