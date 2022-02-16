//
// Created by Emilien Aufauvre on 12/12/2021.
//

#include "activation_functions.h"


using namespace cudaNN;


/**
 * Kernel functions.
 */


__global__ void __kernel_linear(float *results, float *inputs,
                                size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = inputs[index];
    }
}

__global__ void __kernel_linear_derivative(float *results, float *inputs,
                                           size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = 1.f;
    }
}

__global__ void __kernel_binary_step(float *results, float *inputs,
                                     size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = inputs[index] < 0.f ? 0.f : 1.f;
    }
}

__global__ void __kernel_binary_step_derivative(float *results, float *inputs,
                                                size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = 0.f;
    }
}

__global__ void __kernel_sigmoid(float *results, float *inputs,
                                 size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = 1.f / (1.f + expf(-inputs[index]));
    }
}

__global__ void __kernel_sigmoid_derivative(float *results, float *inputs,
                                            size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        float sigmoid = 1.f / (1.f + expf(-inputs[index]));
        results[index] = sigmoid * (1.f - sigmoid);
    }
}

__global__ void __kernel_relu(float *results, float *inputs,
                              size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = fmax(0.f, inputs[index]);
    }
}

__global__ void __kernel_relu_derivative(float *results, float *inputs,
                                         size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = inputs[index] > 0 ? 1.f : 0.f;
    }
}

__global__ void __kernel_tanh(float *results, float *inputs,
                              size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        results[index] = tanhf(inputs[index]);
    }
}

__global__ void __kernel_tanh_derivative(float *results, float *inputs,
                                         size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        float tanh_ = tanhf(inputs[index]);
        results[index] = 1.f - tanh_ * tanh_;
    }
}

__global__ void __kernel_softmax(float *results, float *inputs,
                                 float *sum,
                                 size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    float sum_ = .0f;
    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        for (int i = 0; i < nb_rows * nb_cols; i++)
        {
            sum_ += exp(inputs[i]);
        }

        results[index] = exp(inputs[index]) / sum_;
        __syncthreads();
    }
}

__global__ void __kernel_softmax_derivative(float *results, float *inputs,
                                            float *sum,
                                            size_t nb_rows, size_t nb_cols)
{
    // DO a reduction to compute the sum.
    extern __shared__ float shared_sum[];
    unsigned int tid = threadIdx.x;
    size_t col = blockIdx.x * blockDim.x + tid;

    // Copy into shared memory.
    shared_sum[tid] = inputs[col];
    __syncthreads();

    for (size_t stride = blockDim.x/2; stride > 0; stride >>= 1)
    {
        if (tid < stride)
        {
            shared_sum[tid] += shared_sum[tid + stride];
        }
    }

    __syncthreads();

    if (tid == 0)
    {
        sum[0] = shared_sum[0];
    }

    // Compute the derivative.
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;
    float softmax_x = .0f;
    float softmax_y = .0f;

    __syncthreads();

    // Derivative of softmax using the sum.
    if (row < nb_rows && col < nb_cols)
    {
        // S(x)
        softmax_x = exp(inputs[row])/sum[0];
        // S(y)
        softmax_y = exp(inputs[col])/sum[0];
        // S(x) * (1 - S(x))
        if (row == col)
        {
            results[index] = softmax_x * (1 - softmax_x);
        }
        // -S(x) * S(y)
        else
        {
            results[index] = -softmax_x * softmax_y;
        }
    }
}

void __helper(const matrix &results, const matrix &inputs,
              void (kernel)(float *result, float *inputs, size_t nb_rows, size_t nb_cols))
{
    auto cuda_dims = util::get_cuda_dims(inputs.get_dimensions());
    auto block_dims = cuda_dims.first;
    auto thread_dims = cuda_dims.second;

    float *device_data1;
    float *device_data2;

    // Prepare data on device.
    matrix_parallel::start_operation(results, &device_data1);
    matrix_parallel::start_operation(inputs, &device_data2);

    // Do computations with CUDA threads.
    kernel<<<block_dims, thread_dims>>>(
            device_data1, device_data2,
            results.get_dimensions().first, results.get_dimensions().second);
    // Wait for all threads.
    CUDA_CHECK(cudaDeviceSynchronize());
    // Retrieve/free data from device.
    matrix_parallel::end_operation(results, &device_data1);
    matrix_parallel::end_operation(inputs, &device_data2);
}

void __helper_softmax(const matrix &results, const matrix &inputs,
                      void (kernel)(float *result, float *inputs, float *sum, size_t nb_rows, size_t nb_cols))
{
    auto cuda_dims = util::get_cuda_dims(inputs.get_dimensions());
    auto block_dims = cuda_dims.first;
    auto thread_dims = cuda_dims.second;

    // Sum init for softmax.
    float sum = .0f;

    float *device_data1;
    float *device_data2;
    float *device_sum;

    // Prepare data on device.
    matrix_parallel::start_operation(results, &device_data1);
    matrix_parallel::start_operation(inputs, &device_data2);
    cudaMalloc(&device_sum,1 * sizeof(float));
    cudaMemcpy(device_sum,&sum,sizeof(float),cudaMemcpyHostToDevice);

    // Do computations with CUDA threads.
    kernel<<<block_dims, thread_dims,inputs.get_length() * sizeof(float)>>>(
            device_data1, device_data2, device_sum,
            results.get_dimensions().first, results.get_dimensions().second);
    // Wait for all threads.
    CUDA_CHECK(cudaDeviceSynchronize());
    // Retrieve/free data from device.
    matrix_parallel::end_operation(results, &device_data1);
    matrix_parallel::end_operation(inputs, &device_data2);
    cudaMemcpy(&sum,device_sum,sizeof(float),cudaMemcpyDeviceToHost);
    cudaFree(&device_sum);
}


/**
 * Wrappers for call on host.
 */


void activation_functions_parallel::linear(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_linear);
}

void activation_functions_parallel::linear_derivative(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_linear_derivative);
}

void activation_functions_parallel::binary_step(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_binary_step);
}

void activation_functions_parallel::binary_step_derivative(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_binary_step_derivative);
}

void activation_functions_parallel::sigmoid(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_sigmoid);
}

void activation_functions_parallel::sigmoid_derivative(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_sigmoid_derivative);
}

void activation_functions_parallel::relu(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_relu);
}

void activation_functions_parallel::relu_derivative(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_relu_derivative);
}

void activation_functions_parallel::tanh(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_tanh);
}

void activation_functions_parallel::tanh_derivative(std::vector<matrix *> m)
{
    __helper(*m[0], *m[1],__kernel_tanh_derivative);
}

void activation_functions_parallel::softmax(std::vector<matrix *> m)
{
    __helper_softmax(*m[0], *m[1],__kernel_softmax);
}

void activation_functions_parallel::softmax_derivative(std::vector<matrix *> m)
{
    __helper_softmax(*m[0], *m[1],__kernel_softmax_derivative);
}