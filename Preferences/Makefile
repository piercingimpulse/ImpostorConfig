TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ImpostorConfigPrefs

ImpostorConfigPrefs_FILES = PXICPRootListController.m
ImpostorConfigPrefs_FRAMEWORKS = UIKit
ImpostorConfigPrefs_PRIVATE_FRAMEWORKS = Preferences
ImpostorConfigPrefs_INSTALL_PATH = /Library/PreferenceBundles
ImpostorConfigPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
