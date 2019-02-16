# UPDATE THESE:
KEYSTORE=TheKeyStore.jks
KEYNAME=TheReleaseKeyName
STOREPASS=TheStorePassword
KEYPASS=TheKeyPassword
DNAME=CN=Hermann Digimon, OU=Software Building Department, O=Big Company ltd., L=Sometown, S=Somewhere, C=HR

APKNAME=CatchDroid
IDENTIFIER=net.vucica.catchdroid

#WITH_OUYA=apk/raw/key.der
WITH_OUYA=

ANDROID_REV=android-19
TEST_OBJC=true
PLATFORM=linux
BUILD_TOOLS_REV=19.0.3

# Pick one:
# regular install
INSTALLARGS=-r
# sdcard install
#INSTALLARGS=-r -s

# Don't touch these:
#CFLAGS=-isystem .
LDFLAGS=-shared -llog -landroid -lEGL -lGLESv1_CM


##############################
# PER-PLATFORM SETTINGS

ifeq ("$(PLATFORM)","linux")
#####
#UPDATE THESE:
ifeq ($(COMPILER_BIN),)
COMPILER_BIN=/tmp/my-android-toolchain/bin/
endif
ifeq ($(JAVA_BIN),)
JAVA_BIN=/usr/bin
endif
ifeq ($(ANDROID_SDK),)
ANDROID_SDK=$(HOME)/android-sdk-linux
endif
ifeq ($(ANDROID_NDK),)
ANDROID_NDK=$(HOME)/android-ndk-r9d
endif
ANDROID_SDK_WIN=$(ANDROID_SDK)
CC=$(COMPILER_BIN)clang
CXX=$(COMPILER_BIN)clang++

#####
# No need to touch below:
AAPT=$(ANDROID_SDK)/build-tools/$(BUILD_TOOLS_REV)/aapt
ADB=$(ANDROID_SDK)/platform-tools/adb
# -s emulator-5556
DX=$(ANDROID_SDK)/build-tools/$(BUILD_TOOLS_REV)/dx

PROJECT_PATH_WIN=`pwd`

JARSIGNER="$(JAVA_BIN)"/jarsigner
KEYTOOL="$(JAVA_BIN)"/keytool
JAVAC="$(JAVA_BIN)"/javac

endif
ifeq ("$(PLATFORM)","windows")
####
#UPDATE THESE:
ifeq ($(COMPILER_BIN),)
COMPILER_BIN=$(shell cygpath -u `cygpath -w android-sdk`)/../compiler/bin/
endif
ifeq ($(JAVA_BIN),)
JAVA_BIN=/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_25/bin
endif
CC=$(COMPILER_BIN)arm-linux-androideabi-gcc
CXX=$(COMPILER_BIN)arm-linux-androideabi-g++
ANDROID_SDK=$(shell cygpath -u `cygpath -w android-sdk`) # android-sdk is a symlink
ANDROID_SDK_WIN=$(shell cygpath -w android-sdk | sed 's_\\_/_g')

# Examples in case we don't use a symlink:
#ANDROID_SDK_PATH=Path/To/AndroidSDK/On/F/Drive
#ANDROID_SDK=/cygdrive/f/$(ANDROID_SDK_PATH)
#ANDROID_SDK_WIN=F:/$(ANDROID_SDK_PATH)

####
# No need to touch below:
PROJECT_PATH_WIN=$(shell cygpath -w `pwd` | sed 's_\\_/_g')

AAPT=$(ANDROID_SDK)/build-tools/$(BUILD_TOOLS_REV)/aapt.exe
ADB=$(ANDROID_SDK)/platform-tools/adb.exe
# -s emulator-5556
DX=$(ANDROID_SDK)/build-tools/$(BUILD_TOOLS_REV)/dx.bat

JARSIGNER="$(JAVA_BIN)"/jarsigner.exe
KEYTOOL="$(JAVA_BIN)"/keytool.exe
JAVAC="$(JAVA_BIN)"/javac.exe
endif

####
# No need to touch these:
ANDROID_JAR=$(ANDROID_SDK_WIN)/platforms/$(ANDROID_REV)/android.jar
AAPT_PACK=$(AAPT) package -v -f -I $(ANDROID_JAR)

#####################################

CFLAGS += -I $(COMPILER_BIN)/../include

#CP_SO=cp
CP_SO=$(COMPILER_BIN)/arm-linux-androideabi-objcopy -S 

ifeq ($(TEST_OBJC),true)
ifeq ($(GSCONFIG),)
GSCONFIG = gnustep-config
endif

CFLAGS += -x objective-c $(shell $(GSCONFIG) --objc-flags) # testing objc
LDFLAGS += $(shell $(GSCONFIG) --base-libs)
FOUNDATION_COPY = $(CP_SO) $(shell $(GSCONFIG) --variable=GNUSTEP_LOCAL_LIBRARIES)/libgnustep-base.so.1.*.* apk/lib/armeabi/libgnustep-base.so
OBJC_COPY = $(CP_SO) $(shell $(GSCONFIG) --variable=GNUSTEP_LOCAL_LIBRARIES)/libobjc.so.*.* apk/lib/armeabi/libobjc.so

# instead of rpl to replace .4.6 with null, we should do this: 
# http://www.opengis.ch/2011/11/23/creating-non-versioned-shared-libraries-for-android/
RPL = rpl -R -e libobjc.so.4.6 "libobjc.so\x00\x00\x00\x00" apk/lib/armeabi/

JAVA_CLASS = IVNativeActivity

ifeq ($(OBJC),)
OBJC=$(CC)
endif

else
FOUNDATION_COPY = 
OBJC_COPY =
RPL =

JAVA_CLASS = DummyClass
endif

CFLAGS += -Ilibpng-android/jni

OBJS=src/catchdroid.o src/Texture.o src/Asset.o src/Page.o src/Character.o src/Scene.o src/Font.o src/TextContainer.o src/NPC.o

all: $(APKNAME).apk

%.o: %.m
	$(OBJC) $(CFLAGS) $(OBJCFLAGS) $< -c -o $@

install: $(APKNAME).apk
	$(ADB) install $(INSTALLARGS) $(APKNAME).apk
uninstall:
	$(ADB) uninstall $(IDENTIFIER)

lib$(APKNAME).so: $(OBJS) android_native_app_glue.o libpng-android/obj/local/armeabi/libpng.a
	$(CC) $(LDFLAGS) $(OBJS) android_native_app_glue.o libpng-android/obj/local/armeabi/libpng.a -o lib$(APKNAME).so

$(APKNAME).unsigned.apk: lib$(APKNAME).so classes.dex AndroidManifest.xml
	rm -rf apk/
	rm -rf gen
	mkdir apk/
	mkdir gen/
	mkdir -p apk/lib/armeabi/

	$(CP_SO) lib$(APKNAME).so apk/lib/armeabi/lib$(APKNAME).so
	$(FOUNDATION_COPY)
	$(OBJC_COPY)

	$(RPL)

	cp classes.dex apk/
ifdef WITH_OUYA
	mkdir -p `dirname "$(WITH_OUYA)"`
	cp ouya/key.der "$(WITH_OUYA)"
endif
	$(AAPT_PACK) -M AndroidManifest.xml -S res -A assets -m -J gen -F $(APKNAME).unsigned.apk apk

$(APKNAME).apk: $(APKNAME).unsigned.apk $(KEYSTORE)
	$(JARSIGNER) -keystore $(KEYSTORE) -storepass $(STOREPASS) -keypass $(KEYPASS) -signedjar $(APKNAME).apk $(APKNAME).unsigned.apk "$(KEYNAME)" -sigalg MD5withRSA -digestalg SHA1


$(KEYSTORE):
	$(KEYTOOL) -genkey -v -keystore "$(KEYSTORE)" -alias "$(KEYNAME)" -keyalg RSA -keysize 2048 -validity 10000 -storepass "$(STOREPASS)" -keypass "$(KEYPASS)" -dname "$(DNAME)" -sigalg MD5withRSA

classes.dex: classes/net/vucica/catchdroid/$(JAVA_CLASS).class
	$(DX) --dex --output=$(PROJECT_PATH_WIN)/classes.dex --verbose $(PROJECT_PATH_WIN)/classes

classes/net/vucica/catchdroid/$(JAVA_CLASS).class: $(JAVA_CLASS).java
	mkdir -p classes/net/vucica/catchdroid/
	$(JAVAC) -bootclasspath $(ANDROID_JAR) -d classes/ $(JAVA_CLASS).java -source 1.6 -target 1.6

libpng-android/obj/local/armeabi/libpng.a:
	sh -c "export PATH=$(PATH):$(ANDROID_NDK) && cd libpng-android && ./build.sh"

clean:
	-rm *.o
	-rm lib$(APKNAME).so
	-rm $(APKNAME).apk
	-rm $(APKNAME).unsigned.apk
	-rm -rf apk/
	-rm -rf gen
	-rm -rf classes
	-rm classes.dex
distclean: clean
	-rm $(KEYSTORE)

run:
	$(ADB) shell am start -n $(IDENTIFIER)/net.vucica.catchdroid.IVNativeActivity

nginx: /usr/share/nginx/www/$(APKNAME).apk
/usr/share/nginx/www/$(APKNAME).apk: $(APKNAME).apk
	cp $(APKNAME).apk /usr/share/nginx/www/
	
