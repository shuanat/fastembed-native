#include <jni.h>
#include "fastembed.h"

JNIEXPORT jint JNICALL
Java_com_fastembed_FastEmbed_nativeGenerateEmbedding(JNIEnv *env, jobject obj,
                                                     jstring text, jfloatArray output, jint dimension)
{
    const char *text_str = (*env)->GetStringUTFChars(env, text, NULL);
    if (text_str == NULL)
        return -1;

    jfloat *output_arr = (*env)->GetFloatArrayElements(env, output, NULL);
    if (output_arr == NULL)
    {
        (*env)->ReleaseStringUTFChars(env, text, text_str);
        return -1;
    }

    int result = fastembed_generate(text_str, output_arr, dimension);

    (*env)->ReleaseFloatArrayElements(env, output, output_arr, 0);
    (*env)->ReleaseStringUTFChars(env, text, text_str);

    return result;
}

JNIEXPORT jfloat JNICALL
Java_com_fastembed_FastEmbed_nativeCosineSimilarity(JNIEnv *env, jobject obj,
                                                    jfloatArray vectorA, jfloatArray vectorB, jint dimension)
{
    jfloat *arrA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *arrB = (*env)->GetFloatArrayElements(env, vectorB, NULL);
    if (arrA == NULL || arrB == NULL)
        return 0.0f;

    float result = fastembed_cosine_similarity(arrA, arrB, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, arrA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, arrB, JNI_ABORT);

    return result;
}

JNIEXPORT jfloat JNICALL
Java_com_fastembed_FastEmbed_nativeDotProduct(JNIEnv *env, jobject obj,
                                              jfloatArray vectorA, jfloatArray vectorB, jint dimension)
{
    jfloat *arrA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *arrB = (*env)->GetFloatArrayElements(env, vectorB, NULL);
    if (arrA == NULL || arrB == NULL)
        return 0.0f;

    float result = fastembed_dot_product(arrA, arrB, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, arrA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, arrB, JNI_ABORT);

    return result;
}

JNIEXPORT jfloat JNICALL
Java_com_fastembed_FastEmbed_nativeVectorNorm(JNIEnv *env, jobject obj,
                                              jfloatArray vector, jint dimension)
{
    jfloat *arr = (*env)->GetFloatArrayElements(env, vector, NULL);
    if (arr == NULL)
        return 0.0f;

    float result = fastembed_vector_norm(arr, dimension);

    (*env)->ReleaseFloatArrayElements(env, vector, arr, JNI_ABORT);

    return result;
}

JNIEXPORT void JNICALL
Java_com_fastembed_FastEmbed_nativeNormalizeVector(JNIEnv *env, jobject obj,
                                                   jfloatArray vector, jint dimension)
{
    jfloat *arr = (*env)->GetFloatArrayElements(env, vector, NULL);
    if (arr == NULL)
        return;

    fastembed_normalize(arr, dimension);

    (*env)->ReleaseFloatArrayElements(env, vector, arr, 0);
}

JNIEXPORT void JNICALL
Java_com_fastembed_FastEmbed_nativeAddVectors(JNIEnv *env, jobject obj,
                                              jfloatArray vectorA, jfloatArray vectorB,
                                              jfloatArray result, jint dimension)
{
    jfloat *arrA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *arrB = (*env)->GetFloatArrayElements(env, vectorB, NULL);
    jfloat *arrResult = (*env)->GetFloatArrayElements(env, result, NULL);
    if (arrA == NULL || arrB == NULL || arrResult == NULL)
        return;

    fastembed_add_vectors(arrA, arrB, arrResult, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, arrA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, arrB, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, result, arrResult, 0);
}

JNIEXPORT jint JNICALL
Java_com_fastembed_FastEmbed_nativeGenerateOnnxEmbedding(JNIEnv *env, jobject obj,
                                                         jstring modelPath, jstring text,
                                                         jfloatArray output, jint dimension)
{
    const char *model_path_str = (*env)->GetStringUTFChars(env, modelPath, NULL);
    if (model_path_str == NULL)
        return -1;

    const char *text_str = (*env)->GetStringUTFChars(env, text, NULL);
    if (text_str == NULL)
    {
        (*env)->ReleaseStringUTFChars(env, modelPath, model_path_str);
        return -1;
    }

    jfloat *output_arr = (*env)->GetFloatArrayElements(env, output, NULL);
    if (output_arr == NULL)
    {
        (*env)->ReleaseStringUTFChars(env, text, text_str);
        (*env)->ReleaseStringUTFChars(env, modelPath, model_path_str);
        return -1;
    }

    extern int fastembed_onnx_generate(const char *model_path, const char *text, float *output, int dimension);
    int result = fastembed_onnx_generate(model_path_str, text_str, output_arr, dimension);

    (*env)->ReleaseFloatArrayElements(env, output, output_arr, 0);
    (*env)->ReleaseStringUTFChars(env, text, text_str);
    (*env)->ReleaseStringUTFChars(env, modelPath, model_path_str);

    return result;
}

JNIEXPORT jint JNICALL
Java_com_fastembed_FastEmbed_nativeUnloadOnnxModel(JNIEnv *env, jobject obj)
{
    extern int fastembed_onnx_unload(void);
    return fastembed_onnx_unload();
}