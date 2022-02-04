//
// Created by Emilien Aufauvre on 30/10/2021.
//

#include "util.h"


using namespace cudaNN;


void util::CUDA_ASSERT(cudaError_t code, const char *file, int line, bool abort /*= true*/)
{
    if (code != cudaSuccess)
    {
        util::ERROR(std::string(file), "at line " + std::to_string(line), code);

        if (abort)
        {
            util::ERROR_EXIT();
        }
    }
}

void util::DEBUG(const std::string &location, const std::string &message)
{
    if (_DEBUG)
    {
        std::cout << "[DEBUG] at " + location + " >> " + message << std::endl;
    }
}

void util::ERROR(const std::string &location, const std::string &message)
{
    if (_ERROR)
    {
        std::cerr << TERM_RED
                  << "[ERROR] at " + location + " >> " + message
                  << TERM_RESET
                  << std::endl;
    }
}

void util::ERROR(const std::string &location, const std::string &message, cudaError_t err)
{
    if (_ERROR)
    {
        std::cerr << TERM_RED
                  << "[ERROR] at " + location + " >> " + message + ": "
                     + std::string(cudaGetErrorName(err)) + " "
                     + std::string(cudaGetErrorString(err))
                  << TERM_RESET
                  << std::endl;
    }
}

void util::ERROR_EXIT()
{
    std::exit(EXIT_FAILURE);
}

std::pair<dim3, dim3> util::get_cuda_dims(std::pair<size_t, size_t> dimensions)
{
    size_t nb_rows = dimensions.first;
    size_t nb_cols = dimensions.second;

    dim3 blocks_per_grid(1, 1);
    dim3 threads_per_block = dim3(nb_cols, nb_rows);

    if (nb_rows * nb_cols > MAX_NB_THREADS_BLOCK)
    {
        auto side = (size_t) std::sqrt((float) MAX_NB_THREADS_BLOCK);

        blocks_per_grid.x = std::ceil((float) nb_cols / (float) side);
        blocks_per_grid.y = std::ceil((float) nb_rows / (float) side);
        threads_per_block.x = side;
        threads_per_block.y = side;
    }

    DEBUG("util::get_cuda_dims",
          "nb_cols=" + std::to_string(nb_cols)
          + " & nb_rows=" + std::to_string(nb_rows)
          + " => Grid=(" + std::to_string(blocks_per_grid.x)
          + ", " + std::to_string(blocks_per_grid.y)
          + ", " + std::to_string(blocks_per_grid.z)
          + ") & Block=(" + std::to_string(threads_per_block.x)
          + ", " + std::to_string(threads_per_block.y)
          + ", " + std::to_string(threads_per_block.z)
          + ")"
    );

    return { blocks_per_grid, threads_per_block };
}

void util::start_record(cudaEvent_t &start_event, cudaEvent_t &end_event)
{
    cudaEventCreate(&start_event);
    cudaEventCreate(&end_event);
    cudaEventRecord(start_event, 0);
}

void util::end_record(float *time_event, cudaEvent_t &start_event, cudaEvent_t &end_event)
{
    cudaEventRecord(end_event, 0);
    cudaEventSynchronize(end_event);
    cudaEventElapsedTime(time_event, start_event, end_event);
}