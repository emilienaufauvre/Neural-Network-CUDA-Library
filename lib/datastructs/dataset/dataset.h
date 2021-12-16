//
// Created by Emilien Aufauvre on 29/10/2021.
//

#ifndef CUDANN_DATASET_H
#define CUDANN_DATASET_H

#include "lib/datastructs/matrix/matrix.h"
#include "lib/datastructs/dataset/element/element.h"
#include "lib/util/util.h"

#include <cstddef>
#include <vector>
#include <utility>
#include <algorithm>
#include <random>


namespace cudaNN
{
    /**
     * Dataset representation.
     */
    class dataset
    {
        public:

            dataset();
            dataset(std::vector<element> &elements);

            void add(const matrix &features, const matrix &labels);
            void add(element &elem);

            void set(const size_t i, element &elem);

            void remove(element &elem);
            void remove(const size_t i);

            element &get(const size_t i);
            std::vector<element> &get_elements();

            size_t size() const;

            /**
             * @return a matrix that contains all the features concatenated.
             */
            const matrix &get_features() const;

            /**
             * @return a matrix that contains all the labels concatenated.
             */
            const matrix &get_labels() const;

            /**
             * @param train_size_ratio represent the proportion of the training dataset
             * (between 0.f and 1.f).
             * @return a dataset for training, and another to test.
             */
            std::pair<dataset, dataset> train_test_split(const float train_size_ratio = 0.8f);

            /**
             * @param batch_size
             * @return a random batch of size "batch_size".
             */
            dataset get_random_batch(const size_t batch_size);


            /**
             * > The "multiplication" dataset: 
             * for the "MULT_SIZE" elements,
             * generate "MULT_N" random numbers in [0, "MULT_MAX"[ (the features),
             * and associate them to the result of the multiplication between them (the label).
             */
            static const size_t MULT_SIZE = 100;
            static const size_t MULT_NB_FEATURES = 3;
            static const size_t MULT_NB_LABELS = 1;
            static const size_t MULT_MAX = 10;
            static dataset *load_mult();

            /**
             * Print the given dataset.
             * @d
             */
            static void print(dataset &d);

        private:

            std::vector<element> _elements;
    };
}


#endif //CUDANN_DATASET_H
