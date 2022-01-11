//
// Created by Emilien Aufauvre on 28/10/2021.
//

#include "neural_network.h"


using namespace cudaNN;


neural_network::neural_network(std::initializer_list<layer *> layers):
        _layers(layers)
{
}

void neural_network::fit(dataset &data,
                         const function_t loss_function,
                         const size_t epochs /*= 1*/,
                         const size_t batch_size /*= 1*/,
                         const float learning_rate /*= 0.01*/)
{
    if (loss_function == nullptr)
    {
        // Invalid.
        util::ERROR("neural_network::fit", "Invalid @loss_function");
        util::ERROR_EXIT();
    }

    for (size_t i = 1; i <= epochs; i ++)
    {
        size_t nb_batches = data.size() / batch_size;

        util::DEBUG("neural_network::fit", 
                    "Starting epoch " + std::to_string(i) 
                    + " with " + std::to_string(nb_batches) + " batches");

        // For each epoch, execute the training on batches:
        for (size_t j = 1; j <= nb_batches; j ++)
        {
            util::DEBUG("neural_network::fit", 
                        "- Starting batch " + std::to_string(j)); 

            // Get a sample of "batch size" (features + labels).
            auto batch = data.get_random_batch(batch_size);
            // Train with it.
            for (size_t k = 0; k < batch_size; k ++)
            {
                auto e = batch.get(k);
                // Forward + backward propagation.
                auto predictions = _feed_forward(e.get_features());
                //_backward_propagation(predictions, e->get_labels(), loss_function);
            }
        }
    }
}

matrix neural_network::predict(const matrix &features) const
{
    return _feed_forward(features);
}

std::vector<matrix> neural_network::predict(dataset &test) const
{
    auto predictions = std::vector<matrix>();

    for (const auto& e: test.get_entries())
    {
        predictions.push_back(_feed_forward(e.get_features()));
    }

    return predictions;
}

matrix neural_network::_feed_forward(const matrix &features) const
{
    auto predictions = matrix(features, "neural_network::_feed_forward::predictions");

    for (auto l: _layers)
    {
        predictions = l->feed_forward(predictions);
    }

    return predictions;
}

void neural_network::_backward_propagation(const matrix &predictions, 
                                           const matrix &labels,
                                           const function_t loss_function)
{
    //auto errors = loss_function(predictions, labels);

    for (size_t i = _layers.size() - 1; i >= 0; i --)
    {
        //errors = _layers.at(i)->backward_propagation(errors);
    }
}