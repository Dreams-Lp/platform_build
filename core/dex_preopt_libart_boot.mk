# Rules to build boot.art
# Input variables:
#   my_2nd_arch_prefix: indicates if this is to build for the 2nd arch.

$(my_2nd_arch_prefix)LIBART_BOOT_IMAGE := /$(DEXPREOPT_BOOT_JAR_DIR)/boot-$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH).art
$(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_BUILT_IMAGE := $(DEXPREOPT_BOOT_JAR_DIR_FULL_PATH)/boot-$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH).art

# The .oat with symbols
$(my_2nd_arch_prefix)LIBART_TARGET_BOOT_OAT_UNSTRIPPED := $(TARGET_OUT_UNSTRIPPED)$(patsubst %.art,%.oat,$($(my_2nd_arch_prefix)LIBART_BOOT_IMAGE))

$(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_INSTALLED_IMAGE :=
ifneq ($(PRODUCT_DEX_PREOPT_IMAGE_IN_DATA),true)
$(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_INSTALLED_IMAGE := $(PRODUCT_OUT)$($(my_2nd_arch_prefix)LIBART_BOOT_IMAGE)
endif

my_skip_rules :=
ifdef my_2nd_arch_prefix
ifeq ($(DEX2OAT_TARGET_ARCH),$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH))
# Avoid duplicate rules if DEX2OAT_TARGET_ARCH has been defaulted to the 2nd arch.
my_skip_rules := true
endif
endif

ifndef my_skip_rules
# The rule to install boot.art and boot.oat
$($(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_INSTALLED_IMAGE) : $($(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_BUILT_IMAGE) | $(ACP)
	$(call copy-file-to-target)
	$(hide) $(ACP) -fp $(patsubst %.art,%.oat,$<) $(patsubst %.art,%.oat,$@)

$($(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_BUILT_IMAGE): PRIVATE_2ND_ARCH_VAR_PREFIX := $(my_2nd_arch_prefix)
# Use dex2oat debug version for better error reporting
$($(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_BUILT_IMAGE) : $(LIBART_TARGET_BOOT_DEX_FILES) $(DEX2OATD_DEPENDENCY)
	@echo "target dex2oat: $@ ($?)"
	@mkdir -p $(dir $@)
	@mkdir -p $(dir $($(PRIVATE_2ND_ARCH_VAR_PREFIX)LIBART_TARGET_BOOT_OAT_UNSTRIPPED))
	$(hide) $(DEX2OATD) --runtime-arg -Xms256m --runtime-arg -Xmx256m --image-classes=$(PRELOADED_CLASSES) \
		$(addprefix --dex-file=,$(LIBART_TARGET_BOOT_DEX_FILES)) \
		$(addprefix --dex-location=,$(LIBART_TARGET_BOOT_DEX_LOCATIONS)) \
		--oat-symbols=$($(PRIVATE_2ND_ARCH_VAR_PREFIX)LIBART_TARGET_BOOT_OAT_UNSTRIPPED) \
		--oat-file=$(patsubst %.art,%.oat,$@) \
		--oat-location=$(patsubst %.art,%.oat,$($(PRIVATE_2ND_ARCH_VAR_PREFIX)LIBART_BOOT_IMAGE)) \
		--image=$@ --base=$(LIBART_IMG_TARGET_BASE_ADDRESS) \
		--instruction-set=$($(PRIVATE_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH) \
		--instruction-set-features=$($(PRIVATE_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES) \
		--android-root=$(PRODUCT_OUT)/system

endif  # my_skip_rules
