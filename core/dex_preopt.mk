####################################
# dexpreopt support - typically used on user builds to run dexopt (for Dalvik) or dex2oat (for ART) ahead of time
#
####################################

ifneq ($(DALVIK_VM_LIB),)

# list of boot classpath jars for dexpreopt
DEXPREOPT_BOOT_JARS := $(subst $(space),:,$(PRODUCT_BOOT_JARS))
DEXPREOPT_BOOT_JARS_MODULES := $(PRODUCT_BOOT_JARS)
PRODUCT_BOOTCLASSPATH := $(subst $(space),:,$(foreach m,$(DEXPREOPT_BOOT_JARS_MODULES),/system/framework/$(m).jar))

DEXPREOPT_BUILD_DIR := $(OUT_DIR)
DEXPREOPT_PRODUCT_DIR_FULL_PATH := $(PRODUCT_OUT)/dex_bootjars
DEXPREOPT_PRODUCT_DIR := $(patsubst $(DEXPREOPT_BUILD_DIR)/%,%,$(DEXPREOPT_PRODUCT_DIR_FULL_PATH))
DEXPREOPT_BOOT_JAR_DIR := system/framework
DEXPREOPT_BOOT_JAR_DIR_FULL_PATH := $(DEXPREOPT_PRODUCT_DIR_FULL_PATH)/$(DEXPREOPT_BOOT_JAR_DIR)

# $(1): the .jar or .apk to remove classes.dex
define dexpreopt-remove-classes.dex
$(hide) $(AAPT) remove $(1) classes.dex
endef

# Special rules for building stripped boot jars that override java_library.mk rules

# $(1): boot jar module name
define _dexpreopt-boot-jar-remove-classes.dex
_dbj_jar_no_dex := $(DEXPREOPT_BOOT_JAR_DIR_FULL_PATH)/$(1)_nodex.jar
_dbj_src_jar := $(call intermediates-dir-for,JAVA_LIBRARIES,$(1),,COMMON)/javalib.jar

$$(_dbj_jar_no_dex) : $$(_dbj_src_jar) | $(ACP) $(AAPT)
	$$(call copy-file-to-target)
ifneq ($(DEX_PREOPT_DEFAULT),nostripping)
	$$(call dexpreopt-remove-classes.dex,$$@)
endif

_dbj_jar_no_dex :=
_dbj_src_jar :=
endef

$(foreach b,$(DEXPREOPT_BOOT_JARS_MODULES),$(eval $(call _dexpreopt-boot-jar-remove-classes.dex,$(b))))

# Conditionally include Dalvik support.
ifeq ($(DALVIK_VM_LIB),libdvm.so)
include $(BUILD_SYSTEM)/dex_preopt_libdvm.mk
endif

# Unconditionally include ART support because its used run dex2oat on the host for tests.
include $(BUILD_SYSTEM)/dex_preopt_libart.mk

# Define dexpreopt-one-file based on current default runtime.
# $(1): the input .jar or .apk file
# $(2): the output .odex file
ifeq ($(DALVIK_VM_LIB),libdvm.so)
define dexpreopt-one-file
$(call dexopt-one-file,$(1),$(2))
endef

DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS := $(DEXOPT_DEPENDENCY)
DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT := $(DEXPREOPT_BOOT_ODEXS)
else
define dexpreopt-one-file
$(call dex2oat-one-file,$(1),$(2))
endef

DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS := $(DEX2OATD_DEPENDENCY)
DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT := $(DEFAULT_DEX_PREOPT_BUILT_IMAGE)
ifdef TARGET_2ND_ARCH
$(TARGET_2ND_ARCH_VAR_PREFIX)DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT := $($(TARGET_2ND_ARCH_VAR_PREFIX)DEFAULT_DEX_PREOPT_BUILT_IMAGE)
endif  # TARGET_2ND_ARCH
endif  # DALVIK_VM_LIB
else
$(warning No DALVIK_VM_LIB, disable dexpreopt.)
WITH_DEXPREOPT := false
endif  # DALVIK_VM_LIB is defined.
