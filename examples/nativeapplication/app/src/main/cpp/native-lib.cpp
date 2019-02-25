#include <jni.h>
#include <string>
#include <Foundation/Foundation.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_nativeapplication_MainActivity_stringFromJNI(
        JNIEnv *env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    NSString *string = @"Hello from NSString";
    NSLog(@"%@",string);
    return env->NewStringUTF(hello.c_str());
}
