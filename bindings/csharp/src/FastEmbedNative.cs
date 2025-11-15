using System;
using System.Runtime.InteropServices;
using System.IO;

namespace FastEmbed
{
    /// <summary>
    /// Low-level P/Invoke declarations for FastEmbed native library
    /// </summary>
    internal static class FastEmbedNative
    {
        // Platform-specific library names
        private const string LibraryName = "fastembed_native";

#if WINDOWS
        private const string DllName = "fastembed_native.dll";
#elif LINUX
        private const string DllName = "libfastembed_native.so";
#elif OSX
        private const string DllName = "libfastembed_native.dylib";
#else
        private const string DllName = "fastembed_native";
#endif

        static FastEmbedNative()
        {
            // Set up DllImport resolver for all platforms
            NativeLibrary.SetDllImportResolver(typeof(FastEmbedNative).Assembly, (libraryName, assembly, searchPath) =>
            {
                if (libraryName == DllName || libraryName == LibraryName)
                {
                    // Try loading from the same directory as the assembly (output directory)
                    var assemblyDir = Path.GetDirectoryName(assembly.Location);
                    if (!string.IsNullOrEmpty(assemblyDir))
                    {
                        var localPath = Path.Combine(assemblyDir, DllName);
                        if (File.Exists(localPath))
                        {
                            try
                            {
                                return NativeLibrary.Load(localPath);
                            }
                            catch { }
                        }
                    }

                    // On Linux, also try LD_LIBRARY_PATH
                    if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                    {
                        var libPath = Environment.GetEnvironmentVariable("LD_LIBRARY_PATH");
                        if (!string.IsNullOrEmpty(libPath))
                        {
                            foreach (var path in libPath.Split(':', StringSplitOptions.RemoveEmptyEntries))
                            {
                                var fullPath = Path.Combine(path, DllName);
                                if (File.Exists(fullPath))
                                {
                                    try
                                    {
                                        return NativeLibrary.Load(fullPath);
                                    }
                                    catch { }
                                }
                            }
                        }
                    }

                    // Try default library search
                    try
                    {
                        return NativeLibrary.Load(DllName);
                    }
                    catch
                    {
                        return IntPtr.Zero;
                    }
                }
                return IntPtr.Zero;
            });
        }

        /// <summary>
        /// Generate hash-based embedding for text
        /// </summary>
        /// <param name="text">Input text (UTF-8)</param>
        /// <param name="output">Output buffer for embedding</param>
        /// <param name="dimension">Embedding dimension</param>
        /// <returns>0 on success, non-zero on error</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern int fastembed_generate(
            [MarshalAs(UnmanagedType.LPStr)] string text,
            [Out] float[] output,
            int dimension
        );

        /// <summary>
        /// Calculate cosine similarity between two vectors
        /// </summary>
        /// <param name="vector_a">First vector</param>
        /// <param name="vector_b">Second vector</param>
        /// <param name="dimension">Vector dimension</param>
        /// <returns>Cosine similarity (float)</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern float fastembed_cosine_similarity(
            [In] float[] vector_a,
            [In] float[] vector_b,
            int dimension
        );

        /// <summary>
        /// Calculate dot product of two vectors
        /// </summary>
        /// <param name="vector_a">First vector</param>
        /// <param name="vector_b">Second vector</param>
        /// <param name="dimension">Vector dimension</param>
        /// <returns>Dot product (float)</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern float fastembed_dot_product(
            [In] float[] vector_a,
            [In] float[] vector_b,
            int dimension
        );

        /// <summary>
        /// Calculate L2 norm of a vector
        /// </summary>
        /// <param name="vector">Input vector</param>
        /// <param name="dimension">Vector dimension</param>
        /// <returns>L2 norm (float)</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern float fastembed_vector_norm(
            [In] float[] vector,
            int dimension
        );

        /// <summary>
        /// Normalize a vector in-place (L2 normalization)
        /// </summary>
        /// <param name="vector">Vector to normalize (modified in-place)</param>
        /// <param name="dimension">Vector dimension</param>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void fastembed_normalize(
            [In, Out] float[] vector,
            int dimension
        );

        /// <summary>
        /// Add two vectors element-wise
        /// </summary>
        /// <param name="vector_a">First vector</param>
        /// <param name="vector_b">Second vector</param>
        /// <param name="result">Output buffer for result</param>
        /// <param name="dimension">Vector dimension</param>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void fastembed_add_vectors(
            [In] float[] vector_a,
            [In] float[] vector_b,
            [Out] float[] result,
            int dimension
        );

        /// <summary>
        /// Generate ONNX-based embedding for text using ML model
        /// </summary>
        /// <param name="modelPath">Path to ONNX model file</param>
        /// <param name="text">Input text (UTF-8)</param>
        /// <param name="output">Output buffer for embedding</param>
        /// <param name="dimension">Embedding dimension (must match model output)</param>
        /// <returns>0 on success, non-zero on error</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern int fastembed_onnx_generate(
            [MarshalAs(UnmanagedType.LPStr)] string modelPath,
            [MarshalAs(UnmanagedType.LPStr)] string text,
            [Out] float[] output,
            int dimension
        );

        /// <summary>
        /// Unload ONNX model from memory
        /// </summary>
        /// <returns>0 on success, -1 on error</returns>
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern int fastembed_onnx_unload();
    }
}

