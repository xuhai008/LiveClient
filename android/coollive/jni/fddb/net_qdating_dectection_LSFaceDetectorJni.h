/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class net_qdating_dectection_LSFaceDetectorJni */

#ifndef _Included_net_qdating_dectection_LSFaceDetectorJni
#define _Included_net_qdating_dectection_LSFaceDetectorJni
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     net_qdating_dectection_LSFaceDetectorJni
 * Method:    Create
 * Signature: (Lnet/qdating/dectection/ILSFaceDetectorCallbackJni;)J
 */
JNIEXPORT jlong JNICALL Java_net_qdating_dectection_LSFaceDetectorJni_Create
  (JNIEnv *, jobject, jobject);

/*
 * Class:     net_qdating_dectection_LSFaceDetectorJni
 * Method:    Destroy
 * Signature: (J)V
 */
JNIEXPORT void JNICALL Java_net_qdating_dectection_LSFaceDetectorJni_Destroy
  (JNIEnv *, jobject, jlong);

/*
 * Class:     net_qdating_dectection_LSFaceDetectorJni
 * Method:    DetectPicture
 * Signature: (JII[B)V
 */
JNIEXPORT void JNICALL Java_net_qdating_dectection_LSFaceDetectorJni_DetectPicture
  (JNIEnv *, jobject, jlong, jint, jint, jbyteArray);

#ifdef __cplusplus
}
#endif
#endif
