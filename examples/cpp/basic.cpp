/**
 * FastEmbed C++ Example - Basic Usage
 *
 * Compile:
 *   g++ -o basic basic.cpp -L../build -lfastembed -lm -I../include -std=c++11
 *
 * Run:
 *   LD_LIBRARY_PATH=.. ./basic
 */

#include <iostream>
#include <vector>
#include <iomanip>
#include "fastembed.h"

constexpr int DIMENSION = 768;

std::vector<float> generateEmbedding(const std::string &text)
{
    std::vector<float> embedding(DIMENSION);

    int result = fastembed_generate(
        text.c_str(),
        embedding.data(),
        DIMENSION);

    if (result != 0)
    {
        throw std::runtime_error("Failed to generate embedding (code: " + std::to_string(result) + ")");
    }

    return embedding;
}

float cosineSimilarity(const std::vector<float> &vec1, const std::vector<float> &vec2)
{
    if (vec1.size() != vec2.size())
    {
        throw std::invalid_argument("Vectors must have same dimension");
    }

    return fastembed_cosine_similarity(vec1.data(), vec2.data(), vec1.size());
}

float dotProduct(const std::vector<float> &vec1, const std::vector<float> &vec2)
{
    if (vec1.size() != vec2.size())
    {
        throw std::invalid_argument("Vectors must have same dimension");
    }

    return fastembed_dot_product(vec1.data(), vec2.data(), vec1.size());
}

int main()
{
    std::cout << "FastEmbed C++ Example" << std::endl;
    std::cout << "=====================" << std::endl
              << std::endl;

    try
    {
        // Generate embeddings
        std::cout << "1. Generating embeddings..." << std::endl;
        auto embedding1 = generateEmbedding("Hello, world! This is a test.");
        auto embedding2 = generateEmbedding("Goodbye, world! Another test.");

        std::cout << "   ✓ Generated embeddings (dimension: " << DIMENSION << ")" << std::endl;
        std::cout << "   First 5 values: [";
        for (size_t i = 0; i < 5; ++i)
        {
            std::cout << std::fixed << std::setprecision(4) << embedding1[i];
            if (i < 4)
                std::cout << ", ";
        }
        std::cout << "]" << std::endl;

        // Calculate similarity
        std::cout << "\n2. Calculating cosine similarity..." << std::endl;
        float similarity = cosineSimilarity(embedding1, embedding2);
        std::cout << "   ✓ Cosine similarity: " << std::fixed << std::setprecision(4) << similarity << std::endl;

        // Calculate dot product
        std::cout << "\n3. Calculating dot product..." << std::endl;
        float dot = dotProduct(embedding1, embedding2);
        std::cout << "   ✓ Dot product: " << std::fixed << std::setprecision(4) << dot << std::endl;

        std::cout << "\n✓ All operations completed successfully!" << std::endl;
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
