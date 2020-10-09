TARGET := iphone:clang:latest:7.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ImpostorConfig

ImpostorConfig_FILES = Tweak.x
ImpostorConfig_CFLAGS = -fobjc-arc
ImpostorConfig_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
