This is a small example of how to bootstrap a so-called 'standalone' 
compiler. This is a compiler with a 'more standard' layout compared to
NDK directory layout; it's easier to build UNIX software with such a
'standalone' compiler.

Modify `ANDROID_NDK_RELEASE` based on ndk release you have, modify
`ANDROID_NDK_COMPILER_*` variables to specify which compiler you want,
and the remaining `ANDROID_NDK_*` variables to specify which ABI you want
to target on which host machine.

Having provided `android-ndk-r8e.zip` (or other release, as appropriate),
you'll end up with a requested 'standalone' compiler.

Note: It's just a toy bootstrap script that happens to work for me and
will be useful as research notes for me. YMMV.

-- Ivan Vučica
