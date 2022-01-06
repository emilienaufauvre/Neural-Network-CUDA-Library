//
// Created by Emilien Aufauvre on 29/10/2021.
//

#include "dataset.h"


using namespace cudaNN;


dataset::dataset() = default;

dataset::dataset(std::vector<entry *> &entries):
        _entries(entries)
{
}

dataset::~dataset()
{
    util::DEBUG("dataset::~dataset", "---");

    for (auto e: _entries)
    {
        delete e;
    }
}

void dataset::add(const matrix *features, const matrix *labels)
{
    _entries.push_back(new entry(features, labels));
}

void dataset::add(entry *e)
{
    _entries.push_back(elem);
}

entry &dataset::get(const size_t i)
{
    return *_entries[i];
}

std::vector<entry *> &dataset::get_entries()
{
    return _entries;
}

size_t dataset::size() const
{
    return _entries.size();
}

matrix dataset::get_features() const
{
    matrix features(4, 4, "dataset::features");

    // TODO return all the features concatenated.
    return features;
}

matrix dataset::get_labels() const
{
    matrix labels(4, 4, "dataset::labels");

    // TODO return all the labels concatenated.
    return labels;
}

std::pair<dataset *, dataset *> dataset::train_test_split(const float train_size_ratio /*= 0.8f*/)
{
    if (train_size_ratio < 0 || 1 < train_size_ratio)
    {
        // Invalid.
        util::ERROR("dataset::train_test_split", "Invalid @training_size_ratio");
        util::ERROR_EXIT();
    }

    size_t size_ = size();

    if (size_ < 2)
    {
        // Invalid.
        util::ERROR("dataset::train_test_split", "Dataset is too small");
        util::ERROR_EXIT();
    }

    auto train = new dataset();
    auto test = new dataset;
    size_t train_size = size_ * train_size_ratio;

    // Fill array with [0, "MULT_SIZE"] sequence, and shuffle it.
    std::array<size_t, dataset::MULT_SIZE> numbers {};
    std::iota(numbers.begin(), numbers.end(), 0);
    std::random_device generator;
    std::mt19937 distribution = std::mt19937(generator());
    std::shuffle(numbers.begin(), numbers.end(), distribution);
    // Select the "train_size" first indexes for the training set.
    for (size_t i = 0; i < size_; i ++)
    {
        if (i < train_size)
        {
            train->add(&get(numbers[i]));
        }
        else
        {
            test->add(&get(numbers[i]));
        }
    }

    return { train, test };
}

dataset dataset::get_random_batch(const size_t batch_size)
{
    if (batch_size < 0 || size() < batch_size)
    {
        // Invalid.
        util::ERROR("dataset::get_random_batch", "Invalid @batch_size");
        util::ERROR_EXIT();
    }

    dataset batch;

    // Fill array with [0, "MULT_SIZE"] sequence, and shuffle it.
    std::array<size_t, dataset::MULT_SIZE> numbers {};
    std::iota(numbers.begin(), numbers.end(), 0);
    std::random_device generator;
    std::mt19937 distribution = std::mt19937(generator());
    std::shuffle(numbers.begin(), numbers.end(), distribution);
    // Select the "batch_size" first numbers as indexes.
    for (size_t i = 0; i < batch_size; i ++)
    {
        batch.add(&get(numbers[i]));
    }

    return batch;
}

dataset *dataset::load_mult()
{
    util::DEBUG("dataset::load_mult", "loading the mult dataset");

    auto data = new dataset();

    for (size_t i = 0; i < MULT_SIZE; i ++)
    {
        // TODO need to free pointers (entry be pointer).
        auto features = new matrix(1, MULT_NB_FEATURES,
                               "dataset::mult::features::" + std::to_string(i));
        auto labels = new matrix({ 1 }, 1, MULT_NB_LABELS,
                             "dataset::mult::labels::" + std::to_string(i));

        for (size_t j = 0; j < MULT_NB_FEATURES; j ++)
        {
            features->get_data()[j] = (int) (std::rand() % MULT_MAX);
            labels->get_data()[0] *= (int) features->get_data()[j];
        }

        data->add(features, labels);
    }

    return data;
}

void dataset::print(dataset &d)
{
    size_t i = 1;

    for (auto e: d.get_entries())
    {
        std::cout << ">>> n°" << (i ++) << " <<<" << std::endl; 
        entry::print(*e);
    }
}