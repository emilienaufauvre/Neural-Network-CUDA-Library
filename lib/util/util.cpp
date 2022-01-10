//
// Created by Emilien Aufauvre on 30/10/2021.
//

#include "util.h"

#include <cmath>


using namespace cudaNN;


void util::GPU_ASSERT(cudaError_t code, const char *file, int line, bool abort /*= true*/)
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

    if (nb_rows * nb_cols > MAX_NB_THREADS)
    {
        blocks_per_grid.x = std::ceil((float) nb_cols / (float) MAX_NB_THREADS);
        blocks_per_grid.y = std::ceil((float) nb_rows / (float) MAX_NB_THREADS);
        threads_per_block.x = MAX_NB_THREADS;
        threads_per_block.y = MAX_NB_THREADS;
    }

    return { blocks_per_grid, threads_per_block };
}

uint32_t util::swap_endian(uint32_t val)
{
    val = ((val << 8) & 0xFF00FF00) | ((val >> 8) & 0xFF00FF);
    return (val << 16) | (val >> 16);
}