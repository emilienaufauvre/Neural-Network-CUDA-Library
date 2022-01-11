//
// Created by Emilien Aufauvre on 28/10/2021.
//

#include "layer.h"

#include <utility>


using namespace cudaNN;


layer::layer(const size_t input_size, const size_t nb_neurons,
             function activation_function):
        _size(nb_neurons),
        _biases(1, nb_neurons, "layer::biases"),
        _weights(input_size, nb_neurons, "layer::weights"),
        _activation_function(std::move(activation_function))
{
    _init_biases();
    _init_weights();
}

void layer::_init_biases()
{
    for (int x = 0; x < _biases.get_dimensions().second; x ++)
    {
        _biases[x] = 0.f;
    }
}

void layer::_init_weights()
{
    std::random_device generator;
    std::normal_distribution<float> distribution = std::normal_distribution<float>(0.f, 1.f);

    for (int i = 0; i < _weights.get_length(); i ++)
    {
        _weights[i] = distribution(generator);
    }
}

matrix layer::feed_forward(matrix &inputs) const
{
    if (inputs.get_dimensions().second != _weights.get_dimensions().first)
    {
        // Invalid.
        util::ERROR("layer::_feed_forward",
                    "Invalid @inputs size ("
                    + std::to_string(inputs.get_dimensions().second)
                    + " instead of "
                    + std::to_string(_weights.get_dimensions().first)
                    + ")");
        util::ERROR_EXIT();
    }

    // Compute the output of each neuron.
    auto sum = inputs * _weights + _biases;
    return _activation_function.compute({ &sum });
}

matrix layer::backward_propagation(const matrix &errors)
{
    //TODO
    auto new_errors = matrix(errors.get_dimensions(), "layer::backward_propagation::errors");
    auto cuda_dims = util::get_cuda_dims({ 1, 1 }); // TODO choose dims

    /*
    layer_cuda::backward_propagation(cuda_dims.first, cuda_dims.second, new_errors.get_device_data());
*/
    return new_errors;
}

size_t layer::size() const
{
    return _size;
}