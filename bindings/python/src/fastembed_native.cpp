/**
 * FastEmbed Native Python Extension Module
 *
 * Python bindings using pybind11 for high-performance embedding generation
 * and vector operations.
 */

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <vector>
#include <string>
#include <stdexcept>

namespace py = pybind11;

// Forward declarations of FastEmbed C functions
extern "C"
{
    int fastembed_generate(const char *text, float *output, int dimension);
    int fastembed_onnx_generate(const char *model_path, const char *text, float *output, int dimension);
    int fastembed_onnx_unload(void);
    float fastembed_cosine_similarity(const float *vector_a, const float *vector_b, int dimension);
    float fastembed_dot_product(const float *vector_a, const float *vector_b, int dimension);
    float fastembed_vector_norm(const float *vector, int dimension);
    void fastembed_normalize(float *vector, int dimension);
    void fastembed_add_vectors(const float *vector_a, const float *vector_b, float *result, int dimension);
}

/**
 * Generate embedding from text
 *
 * @param text Input text string
 * @param dimension Embedding dimension (default: 768)
 * @return NumPy array with embedding vector
 */
py::array_t<float> generate_embedding(const std::string &text, int dimension = 768)
{
    // Allocate output buffer
    auto result = py::array_t<float>(dimension);
    py::buffer_info buf = result.request();
    float *ptr = static_cast<float *>(buf.ptr);

    // Call C function
    int status = fastembed_generate(text.c_str(), ptr, dimension);

    if (status != 0)
    {
        throw std::runtime_error("Failed to generate embedding");
    }

    return result;
}

/**
 * Generate ONNX embedding from text
 *
 * @param model_path Path to ONNX model file
 * @param text Input text string
 * @param dimension Embedding dimension (default: 768)
 * @return NumPy array with embedding vector
 */
py::array_t<float> generate_onnx_embedding(const std::string &model_path, const std::string &text, int dimension = 768)
{
    // Allocate output buffer
    auto result = py::array_t<float>(dimension);
    py::buffer_info buf = result.request();
    float *ptr = static_cast<float *>(buf.ptr);

    // Call C function
    int status = fastembed_onnx_generate(model_path.c_str(), text.c_str(), ptr, dimension);

    if (status != 0)
    {
        throw std::runtime_error("Failed to generate ONNX embedding");
    }

    return result;
}

/**
 * Unload ONNX model from memory
 *
 * @return 0 on success, -1 on error
 */
int unload_onnx_model()
{
    return fastembed_onnx_unload();
}

/**
 * Calculate cosine similarity between two vectors
 *
 * @param vector_a First vector (NumPy array or list)
 * @param vector_b Second vector (NumPy array or list)
 * @return Cosine similarity value
 */
float cosine_similarity(py::array_t<float> vector_a, py::array_t<float> vector_b)
{
    py::buffer_info buf_a = vector_a.request();
    py::buffer_info buf_b = vector_b.request();

    if (buf_a.ndim != 1 || buf_b.ndim != 1)
    {
        throw std::runtime_error("Vectors must be 1-dimensional arrays");
    }

    if (buf_a.size != buf_b.size)
    {
        throw std::runtime_error("Vectors must have the same length");
    }

    float *ptr_a = static_cast<float *>(buf_a.ptr);
    float *ptr_b = static_cast<float *>(buf_b.ptr);
    int dimension = static_cast<int>(buf_a.size);

    return fastembed_cosine_similarity(ptr_a, ptr_b, dimension);
}

/**
 * Calculate dot product of two vectors
 *
 * @param vector_a First vector
 * @param vector_b Second vector
 * @return Dot product value
 */
float dot_product(py::array_t<float> vector_a, py::array_t<float> vector_b)
{
    py::buffer_info buf_a = vector_a.request();
    py::buffer_info buf_b = vector_b.request();

    if (buf_a.ndim != 1 || buf_b.ndim != 1)
    {
        throw std::runtime_error("Vectors must be 1-dimensional arrays");
    }

    if (buf_a.size != buf_b.size)
    {
        throw std::runtime_error("Vectors must have the same length");
    }

    float *ptr_a = static_cast<float *>(buf_a.ptr);
    float *ptr_b = static_cast<float *>(buf_b.ptr);
    int dimension = static_cast<int>(buf_a.size);

    return fastembed_dot_product(ptr_a, ptr_b, dimension);
}

/**
 * Calculate L2 norm of a vector
 *
 * @param vector Input vector
 * @return Norm value
 */
float vector_norm(py::array_t<float> vector)
{
    py::buffer_info buf = vector.request();

    if (buf.ndim != 1)
    {
        throw std::runtime_error("Vector must be a 1-dimensional array");
    }

    float *ptr = static_cast<float *>(buf.ptr);
    int dimension = static_cast<int>(buf.size);

    return fastembed_vector_norm(ptr, dimension);
}

/**
 * Normalize vector (L2 normalization)
 *
 * @param vector Input vector
 * @return Normalized vector (NumPy array)
 */
py::array_t<float> normalize_vector(py::array_t<float> vector)
{
    py::buffer_info buf = vector.request();

    if (buf.ndim != 1)
    {
        throw std::runtime_error("Vector must be a 1-dimensional array");
    }

    int dimension = static_cast<int>(buf.size);

    // Create output array
    auto result = py::array_t<float>(dimension);
    py::buffer_info result_buf = result.request();
    float *result_ptr = static_cast<float *>(result_buf.ptr);

    // Copy input to output
    float *input_ptr = static_cast<float *>(buf.ptr);
    std::copy(input_ptr, input_ptr + dimension, result_ptr);

    // Normalize in-place
    fastembed_normalize(result_ptr, dimension);

    return result;
}

/**
 * Add two vectors element-wise
 *
 * @param vector_a First vector
 * @param vector_b Second vector
 * @return Result vector (NumPy array)
 */
py::array_t<float> add_vectors(py::array_t<float> vector_a, py::array_t<float> vector_b)
{
    py::buffer_info buf_a = vector_a.request();
    py::buffer_info buf_b = vector_b.request();

    if (buf_a.ndim != 1 || buf_b.ndim != 1)
    {
        throw std::runtime_error("Vectors must be 1-dimensional arrays");
    }

    if (buf_a.size != buf_b.size)
    {
        throw std::runtime_error("Vectors must have the same length");
    }

    int dimension = static_cast<int>(buf_a.size);

    // Create output array
    auto result = py::array_t<float>(dimension);
    py::buffer_info result_buf = result.request();

    float *ptr_a = static_cast<float *>(buf_a.ptr);
    float *ptr_b = static_cast<float *>(buf_b.ptr);
    float *result_ptr = static_cast<float *>(result_buf.ptr);

    fastembed_add_vectors(ptr_a, ptr_b, result_ptr, dimension);

    return result;
}

/**
 * FastEmbedNative class for high-level API
 */
class FastEmbedNative
{
private:
    int dimension_;

public:
    FastEmbedNative(int dimension = 768) : dimension_(dimension)
    {
        if (dimension <= 0)
        {
            throw std::invalid_argument("Dimension must be positive");
        }
    }

    py::array_t<float> generate_embedding(const std::string &text)
    {
        return ::generate_embedding(text, dimension_);
    }

    float cosine_similarity(py::array_t<float> vector_a, py::array_t<float> vector_b)
    {
        return ::cosine_similarity(vector_a, vector_b);
    }

    float dot_product(py::array_t<float> vector_a, py::array_t<float> vector_b)
    {
        return ::dot_product(vector_a, vector_b);
    }

    float vector_norm(py::array_t<float> vector)
    {
        return ::vector_norm(vector);
    }

    py::array_t<float> normalize_vector(py::array_t<float> vector)
    {
        return ::normalize_vector(vector);
    }

    py::array_t<float> add_vectors(py::array_t<float> vector_a, py::array_t<float> vector_b)
    {
        return ::add_vectors(vector_a, vector_b);
    }

    py::array_t<float> generate_onnx_embedding(const std::string &model_path, const std::string &text)
    {
        return ::generate_onnx_embedding(model_path, text, dimension_);
    }

    int unload_onnx_model()
    {
        return ::unload_onnx_model();
    }

    int get_dimension() const
    {
        return dimension_;
    }
};

// Python module definition
PYBIND11_MODULE(fastembed_native, m)
{
    m.doc() = "FastEmbed native extension module for high-performance embedding generation";

    // Module-level functions
    m.def("generate_embedding", &generate_embedding,
          "Generate embedding from text",
          py::arg("text"),
          py::arg("dimension") = 768);

    m.def("cosine_similarity", &cosine_similarity,
          "Calculate cosine similarity between two vectors",
          py::arg("vector_a"),
          py::arg("vector_b"));

    m.def("dot_product", &dot_product,
          "Calculate dot product of two vectors",
          py::arg("vector_a"),
          py::arg("vector_b"));

    m.def("vector_norm", &vector_norm,
          "Calculate L2 norm of a vector",
          py::arg("vector"));

    m.def("normalize_vector", &normalize_vector,
          "Normalize vector (L2 normalization)",
          py::arg("vector"));

    m.def("add_vectors", &add_vectors,
          "Add two vectors element-wise",
          py::arg("vector_a"),
          py::arg("vector_b"));

    m.def("generate_onnx_embedding", &generate_onnx_embedding,
          "Generate ONNX embedding from text",
          py::arg("model_path"),
          py::arg("text"),
          py::arg("dimension") = 768);

    m.def("unload_onnx_model", &unload_onnx_model,
          "Unload ONNX model from memory");

    // FastEmbedNative class
    py::class_<FastEmbedNative>(m, "FastEmbedNative")
        .def(py::init<int>(),
             "Initialize FastEmbed with specified dimension",
             py::arg("dimension") = 768)
        .def("generate_embedding", &FastEmbedNative::generate_embedding,
             "Generate embedding from text",
             py::arg("text"))
        .def("cosine_similarity", &FastEmbedNative::cosine_similarity,
             "Calculate cosine similarity",
             py::arg("vector_a"),
             py::arg("vector_b"))
        .def("dot_product", &FastEmbedNative::dot_product,
             "Calculate dot product",
             py::arg("vector_a"),
             py::arg("vector_b"))
        .def("vector_norm", &FastEmbedNative::vector_norm,
             "Calculate vector norm",
             py::arg("vector"))
        .def("normalize_vector", &FastEmbedNative::normalize_vector,
             "Normalize vector",
             py::arg("vector"))
        .def("add_vectors", &FastEmbedNative::add_vectors,
             "Add two vectors",
             py::arg("vector_a"),
             py::arg("vector_b"))
        .def("generate_onnx_embedding", &FastEmbedNative::generate_onnx_embedding,
             "Generate ONNX embedding from text",
             py::arg("model_path"),
             py::arg("text"))
        .def("unload_onnx_model", &FastEmbedNative::unload_onnx_model,
             "Unload ONNX model from memory")
        .def_property_readonly("dimension", &FastEmbedNative::get_dimension,
                               "Get embedding dimension");

    // Version info
    m.attr("__version__") = "1.0.0";
}
