TARGET = iphone:clang:10.3
ARCHS = armv7 arm64
export TARGET ARCHS

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = susLAN

susLAN_FILES = Tweak.x
susLAN_CFLAGS = -fobjc-arc
susLAN_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
