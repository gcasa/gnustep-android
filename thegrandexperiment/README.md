TheGrandExperiment
==================

This is an exercise in building Android native activities with GNU Make.
And it's the smallest possible project I could come up with.

Windows
-------

Expectations to build out of the box:

* build with cygwin
* build on windows
* have JDK in `/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_25/bin`
* create a symlink to your Android SDK and call it `[root]/android-sdk`
* bootstrap a 'standalone' compiler in `[Path to Android SDK]/../compiler`; 
  see folder 'bootstrap/' for an example of how to do this

Any system that does not match these expectations will require slight 
changes to environment variables set up in `Makefile`. Not building on
Windows will also require changes to any rules that call Win32 binaries
such as binaries from JDK and Android SDK.

Some of the requirements are obvious hacks so I don't have to expose my
personal working environment to the world.

Ouya deployment key is obviously not included. Include your own and
set the `WITH_OUYA` variable properly.

`android_native_app_glue.c/h` are coming from 
`[android_ndk]/sources/android/native_app_glue`.

There are references to build tools version 19.0.3. There are references
to particular API revision. `PLATFORM` needs to be set to `windows`.
There may be other assumptions.

Update `BUILD_TOOLS_REV` to change build tools version. Update `JAVA_BIN`
to set path to JDK's `bin/`.

Linux
-----
Makefile now actually contains code to build under Linux, as long as:

* JDK is in `/usr/bin/`
* Android SDK is in `${HOME}/android-sdk-linux`
* standalone NDK compiler is in `/tmp/my-android-toolchain`

Build tools are presumed to be 19.0.3. `PLATFORM` needs to be set to
`linux`. There may be other assumptions.

The sections that can and should be overridden are marked.

Without modifying, you can update `COMPILER_BIN`, `ANDROID_SDK`,
and `JAVA_BIN` which are path to `bin/` of the standalone compiler,
path to Android SDK, and path to JDK's `bin/`.

Update `BUILD_TOOLS_REV` to change build tools version. Update `JAVA_BIN`
to set path to JDK's `bin/`.

Objective-C test
----------------
This code is also used to test Objective-C, and hence is no longer
as minimal as it could be.

`TGENativeActivity`, a subclass of `android.app.NativeActivity` is used.
This is done so we can load additional libraries in correct order, instead
of just the native activity code. Previously `DummyClass`, an empty class, 
was used to produce `classes.dex`, required by Android; now
`TGENativeActivity` is good enough for that.

Also, when `TEST_OBJC=true` is set in `Makefile`, .c files are compiled
as if they are Objective-C files. Using `#if __OBJC__`, extra code is used
to test Objective-C functionality.

Finally, when `TEST_OBJC=true`, additional libraries are copied into the
apk (libobjc2 runtime, gnustep-base).

Set `GSCONFIG` to full path to `gnustep-config` file in case the
Android-specific `gnustep-config` is not in `PATH` or is not the first one
appearing in `PATH`. For example:

    GSCONFIG=~/gnustep-android/build/gs-install/bin/gnustep-config make

You will need to install `rpl` package under Ubuntu, as we use it to
tweak the binaries produced by the build process.

hasCode
-------
Instead of DummyClass, we could use `android:hasCode="false"`.
