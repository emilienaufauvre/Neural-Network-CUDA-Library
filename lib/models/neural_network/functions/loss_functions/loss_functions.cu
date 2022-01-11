//
// Created by Emilien Aufauvre on 09/12/2021.
//

#include "loss_functions.h"


using namespace cudaNN;


/**
 * Kernel functions.
 */


__global__ void __kernel_mean_squared_error(float *errors,
                                            float *predictions, float *labels,
                                            size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = std::pow(labels[index] - predictions[index], 2.0f);
    }
}

__global__ void __kernel_mean_squared_error_derivative(float *errors,
                                            float *predictions, float *labels,
                                            size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = -2.f * (labels[index] - predictions[index]);
    }
}

__global__ void __kernel_mean_absolute_error(float *errors,
                                             float *predictions, float *labels,
                                             size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = std::abs(labels[index] - predictions[index]);
    }
}

__global__ void __kernel_mean_absolute_error_derivative(float *errors,
                                             float *predictions, float *labels,
                                             size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = predictions[index] > labels[index] ? +1.f : -1.f;
    }
}

__global__ void __kernel_mean_bias_error(float *errors,
                                         float *predictions, float *labels,
                                         size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = labels[index] - predictions[index];
    }
}

__global__ void __kernel_mean_bias_error_derivative(float *errors,
                                         float *predictions, float *labels,
                                         size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = -1.f;
    }
}

__global__ void __kernel_hinge_loss(float *errors,
                                    float *predictions, float *labels,
                                    size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = fmax(0.f, 1.f - labels[index] * predictions[index]);
    }
}

__global__ void __kernel_hinge_loss_derivative(float *errors,
                                    float *predictions, float *labels,
                                    size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = predictions[index] > 1.f ? 0.f : -labels[index] * 1.f; // TODO check
    }
}

__global__ void __kernel_binary_cross_entropy_loss(float *errors,
                                                   float *predictions, float *labels,
                                                   size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = -(labels[index] * logf(predictions[index])
                          + (1.f - labels[index]) * logf(1.f - predictions[index]));
    }
}

__global__ void __kernel_binary_cross_entropy_loss_derivative(float *errors,
                                                   float *predictions, float *labels,
                                                   size_t nb_rows, size_t nb_cols)
{
    size_t col = blockIdx.x * blockDim.x + threadIdx.x;
    size_t row = blockIdx.y * blockDim.y + threadIdx.y;
    size_t index = row * nb_cols + col;

    // Check if the thread is in the matrix dimensions.
    if (row < nb_rows && col < nb_cols)
    {
        errors[index] = -(labels[index] / predictions[index]
                          - (1.f - labels[index]) / (1.f - predictions[index]));
    }
}

void __helper(dim3 block_dims, dim3 thread_dims,
              const matrix &errors,
              const matrix &predictions, const matrix &labels,
              void (kernel)(float *errors, float *predictions, float *labels,
                            size_t nb_rows, size_t nb_cols))
{
    float *device_data0;
    float *device_data1;
    float *device_data2;

    // Prepare data on device.
    matrix_cuda::start_operation(errors, &device_data0);
    matrix_cuda::start_operation(predictions, &device_data1);
    matrix_cuda::start_operation(labels, &device_data2);
    // Do computations with CUDA threads.
    kernel<<<block_dims, thread_dims>>>(
            device_data0,
            device_data1, device_data2,
            errors.get_dimensions().first, errors.get_dimensions().second);
    // Wait for all threads.
    CUDA_CHECK(cudaDeviceSynchronize());
    // Retrieve/free data from device.
    matrix_cuda::end_operation(errors, &device_data0);
    matrix_cuda::end_operation(predictions, &device_data1);
    matrix_cuda::end_operation(labels, &device_data2);
}


/**
 * Wrappers for call on host.
 */


void loss_functions_cuda::mean_squared_error(dim3 block_dims, dim3 thread_dims,
                                             std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_squared_error);
}

void loss_functions_cuda::mean_squared_error_derivative(dim3 block_dims, dim3 thread_dims,
                                                        std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_squared_error_derivative);
}

void loss_functions_cuda::mean_absolute_error(dim3 block_dims, dim3 thread_dims,
                                              std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_absolute_error);
}

void loss_functions_cuda::mean_absolute_error_derivative(dim3 block_dims, dim3 thread_dims,
                                                         std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_absolute_error_derivative);
}

void loss_functions_cuda::mean_bias_error(dim3 block_dims, dim3 thread_dims,
                                          std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_bias_error);
}

void loss_functions_cuda::mean_bias_error_derivative(dim3 block_dims, dim3 thread_dims,
                                                     std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_mean_bias_error_derivative);
}

void loss_functions_cuda::hinge_loss(dim3 block_dims, dim3 thread_dims,
                                     std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_hinge_loss);
}

void loss_functions_cuda::hinge_loss_derivative(dim3 block_dims, dim3 thread_dims,
                                                std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_hinge_loss_derivative);
}

void loss_functions_cuda::binary_cross_entropy_loss(dim3 block_dims, dim3 thread_dims,
                                                    std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_binary_cross_entropy_loss);
}

void loss_functions_cuda::binary_cross_entropy_loss_derivative(dim3 block_dims, dim3 thread_dims,
                                                               std::vector<matrix *> m)
{
    __helper(block_dims, thread_dims,
             *m[0], *m[1], *m[2],
             __kernel_binary_cross_entropy_loss_derivative);
}