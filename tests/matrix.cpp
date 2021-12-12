//
// Created by Emilien Aufauvre on 10/12/2021.
//

#include "lib/datastructs/matrix/matrix.h"


using namespace cudaNN;
using namespace cudaNN::matrix_operators;


/**
 * Basic operations on matrices; operators + CUDA tests.
 */
int main(int argc, char *argv[])
{
    size_t x = 10; 
    size_t y = 10;

    // Simple matrix (mult table).
    matrix m1 = matrix(x, y);

    for (size_t i = 0; i < x; i ++)
    {
        for (size_t j= 0; j < y; j ++)
        {
            m1[i * y + j] = i * j;
        }
    }

    matrix::print(m1);

    // Copy.
    matrix m2 = m1;
    matrix::print(m2);

    // Cmp.
    std::cout << "m1 is equal to m2: " 
              << (m1 == m2 ? "true" : "false") 
              << std::endl;

    // Add.
    matrix::print(m1 + m2);
    m1 = m1 + m2;
    matrix::print(m1);

    // Mult.
    matrix::print(m1 * m2);
    m1 = m1 * m2;
    matrix::print(m1);

    // Cmp.
    std::cout << "m1 is not equal to m2: " 
              << (m1 != m2 ? "true" : "false") 
              << std::endl;

    matrix::print(matrix({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, 3, 3));

    return EXIT_SUCCESS;
}
