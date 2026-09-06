ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLEXLoader

FLEX_COMMON_FILES := $(shell find ../Classes -type f \( -name '*.m' -o -name '*.mm' \) ! -path '../Classes/Network/FLEXNetworkObserver.m' ! -path '../Classes/Network/FLEXNetworkMITMViewController.m')

FLEXLoader_FILES = FLEXLoader.xm FLEXColorEditorViewController.m FLEXColorStore.m $(FLEX_COMMON_FILES)
FLEXLoader_CFLAGS = -fobjc-arc -fblocks -I../Classes -I../Classes/Manager -I../Classes/Toolbar -I../Classes/Utility -I../Classes/Editing/ArgumentInputViews
FLEXLoader_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics ImageIO WebKit Security SceneKit
FLEXLoader_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
