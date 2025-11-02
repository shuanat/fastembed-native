#include <jni.h>
#include <string.h>
#include <stdlib.h>

#include "fastembed.h"

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeGenerateEmbedding
 * Signature: (Ljava/lang/String;[FI)I
 */
JNIEXPORT jint JNICALL Java_com_fastembed_FastEmbed_nativeGenerateEmbedding(JNIEnv *env, jobject obj, jstring text, jfloatArray output, jint dimension)
{
    // Convert Java string to C string
    const char *text_c = (*env)->GetStringUTFChars(env, text, NULL);
    if (text_c == NULL)
    {
        return -1; // OutOfMemoryError already thrown
    }

    // Get output array
    jfloat *output_c = (*env)->GetFloatArrayElements(env, output, NULL);
    if (output_c == NULL)
    {
        (*env)->ReleaseStringUTFChars(env, text, text_c);
        return -1; // OutOfMemoryError already thrown
    }

    // Call native function
    int result = fastembed_generate(text_c, output_c, dimension);

    // Release resources
    (*env)->ReleaseFloatArrayElements(env, output, output_c, 0);
    (*env)->ReleaseStringUTFChars(env, text, text_c);

    return result;
}

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeCosineSimilarity
 * Signature: ([F[FI)F
 */
JNIEXPORT jfloat JNICALL Java_com_fastembed_FastEmbed_nativeCosineSimilarity(JNIEnv *env, jobject obj, jfloatArray vectorA, jfloatArray vectorB, jint dimension)
{
    jfloat *vecA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *vecB = (*env)->GetFloatArrayElements(env, vectorB, NULL);

    if (vecA == NULL || vecB == NULL)
    {
        if (vecA)
            (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
        if (vecB)
            (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);
        return 0.0f;
    }

    float result = fastembed_cosine_similarity(vecA, vecB, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);

    return result;
}

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeDotProduct
 * Signature: ([F[FI)F
 */
JNIEXPORT jfloat JNICALL Java_com_fastembed_FastEmbed_nativeDotProduct(JNIEnv *env, jobject obj, jfloatArray vectorA, jfloatArray vectorB, jint dimension)
{
    jfloat *vecA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *vecB = (*env)->GetFloatArrayElements(env, vectorB, NULL);

    if (vecA == NULL || vecB == NULL)
    {
        if (vecA)
            (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
        if (vecB)
            (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);
        return 0.0f;
    }

    float result = fastembed_dot_product(vecA, vecB, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);

    return result;
}

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeVectorNorm
 * Signature: ([FI)F
 */
JNIEXPORT jfloat JNICALL Java_com_fastembed_FastEmbed_nativeVectorNorm(JNIEnv *env, jobject obj, jfloatArray vector, jint dimension)
{
    jfloat *vec = (*env)->GetFloatArrayElements(env, vector, NULL);
    if (vec == NULL)
    {
        return 0.0f;
    }

    float result = fastembed_vector_norm(vec, dimension);

    (*env)->ReleaseFloatArrayElements(env, vector, vec, JNI_ABORT);

    return result;
}

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeNormalizeVector
 * Signature: ([FI)V
 */
JNIEXPORT void JNICALL Java_com_fastembed_FastEmbed_nativeNormalizeVector(JNIEnv *env, jobject obj, jfloatArray vector, jint dimension)
{
    jfloat *vec = (*env)->GetFloatArrayElements(env, vector, NULL);
    if (vec == NULL)
    {
        return;
    }

    fastembed_normalize(vec, dimension);

    (*env)->ReleaseFloatArrayElements(env, vector, vec, 0);
}

/*
 * Class:     com_fastembed_FastEmbed
 * Method:    nativeAddVectors
 * Signature: ([F[F[FI)V
 */
JNIEXPORT void JNICALL Java_com_fastembed_FastEmbed_nativeAddVectors(JNIEnv *env, jobject obj, jfloatArray vectorA, jfloatArray vectorB, jfloatArray result, jint dimension)
{
    jfloat *vecA = (*env)->GetFloatArrayElements(env, vectorA, NULL);
    jfloat *vecB = (*env)->GetFloatArrayElements(env, vectorB, NULL);
    jfloat *vecResult = (*env)->GetFloatArrayElements(env, result, NULL);

    if (vecA == NULL || vecB == NULL || vecResult == NULL)
    {
        if (vecA)
            (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
        if (vecB)
            (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);
        if (vecResult)
            (*env)->ReleaseFloatArrayElements(env, result, vecResult, JNI_ABORT);
        return;
    }

    fastembed_add_vectors(vecA, vecB, vecResult, dimension);

    (*env)->ReleaseFloatArrayElements(env, vectorA, vecA, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, vectorB, vecB, JNI_ABORT);
    (*env)->ReleaseFloatArrayElements(env, result, vecResult, 0);
}
