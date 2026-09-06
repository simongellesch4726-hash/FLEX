ARCHS = arm64e
TARGET = iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLEXLoader

FLEX_COMMON_FILES = $(wildcard ../Classes/**/*.m) $(wildcard ../Classes/*.m)
FLEX_COMMON_FILES := $(filter-out ../Classes/Network/FLEXNetworkObserver.m ../Classes/Network/FLEXNetworkMITMViewController.m,$(FLEX_COMMON_FILES))

FLEXLoader_FILES = FLEXLoader.xm FLEXColorizer.m FLEXColorEditorViewController.m FLEXColorStore.m $(FLEX_COMMON_FILES)
FLEXLoader_CFLAGS = -fobjc-arc -I../Classes -I../Classes/Utility -I../Classes/Editing/ArgumentInputViews
FLEXLoader_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
FLEXLoader_PRIVATE_FRAMEWORKS = Foundation
FLEXLoader_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)$(COPY) layout/DEBIAN/control $(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)
