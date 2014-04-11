# We don't automatically set up rules to build packages for both
# TARGET_ARCH and TARGET_2ND_ARCH.
# By default, an package is built for TARGET_ARCH.
# To build it for TARGET_2ND_ARCH in a 64bit product, use "LOCAL_MULTILIB := 32".

include $(BUILD_SYSTEM)/multilib.mk

ifeq ($(TARGET_SUPPORTS_32_BIT_APPS)|$(TARGET_SUPPORTS_64_BIT_APPS),true|true)
# packages default to building for either architecture,
# the preferred if its supported, otherwise the non-preferred.
else ifeq ($(TARGET_SUPPORTS_64_BIT_APPS),true)
ifeq (,$(filter 32 none,$(my_module_multilib)))
my_module_multilib := 64
else
my_module_multilib := none
endif
else
ifeq (,$(filter 64 first none,$(my_module_multilib)))
my_module_multilib := 32
else
my_module_multilib := none
endif
endif

LOCAL_NO_2ND_ARCH_MODULE_SUFFIX := true

# if TARGET_PREFER_32_BIT is set, try to build 32-bit first
ifdef TARGET_2ND_ARCH
ifeq ($(TARGET_PREFER_32_BIT),true)
LOCAL_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
else
LOCAL_2ND_ARCH_VAR_PREFIX :=
endif
endif

# check if preferred arch is supported
include $(BUILD_SYSTEM)/module_arch_supported.mk
ifeq ($(my_module_arch_supported),true)
# first arch is supported
include $(BUILD_SYSTEM)/package_internal.mk
else ifneq (,$(TARGET_2ND_ARCH))
# check if the non-preferred arch is the primary or secondary
ifeq ($(TARGET_PREFER_32_BIT),true)
LOCAL_2ND_ARCH_VAR_PREFIX :=
else
LOCAL_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
endif

# check if non-preferred arch is supported
include $(BUILD_SYSTEM)/module_arch_supported.mk
ifeq ($(my_module_arch_supported),true)
# secondary arch is supported
include $(BUILD_SYSTEM)/package_internal.mk
endif
endif # TARGET_2ND_ARCH

LOCAL_2ND_ARCH_VAR_PREFIX :=
LOCAL_NO_2ND_ARCH_MODULE_SUFFIX :=

my_module_arch_supported :=
