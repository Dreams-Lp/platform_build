# Configuration for Linux on SuperH.
# Included by combo/select.make

# You can set TARGET_TOOLS_PREFIX to get gcc from somewhere else
ifeq ($(strip $($(combo_target)TOOLS_PREFIX)),)
$(combo_target)TOOLS_PREFIX := \
	prebuilt/$(HOST_PREBUILT_TAG)/toolchain/sh-4.3.3/bin/sh-linux-gnu-
endif

$(combo_target)CC := $($(combo_target)TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)CXX := $($(combo_target)TOOLS_PREFIX)c++$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)AR := $($(combo_target)TOOLS_PREFIX)ar$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)OBJCOPY := $($(combo_target)TOOLS_PREFIX)objcopy$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)LD := $($(combo_target)TOOLS_PREFIX)ld$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)STRIP := $($(combo_target)TOOLS_PREFIX)strip$(HOST_EXECUTABLE_SUFFIX)
$(combo_target)STRIP_COMMAND = $($(combo_target)STRIP) --strip-debug $< -o $@

$(combo_target)NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined

TARGET_sh_release_CFLAGS :=     -O2 \
                                -fomit-frame-pointer \
                                -fstrict-aliasing    \
                                -funswitch-loops     \
                                -finline-limit=300

# When building for debug, compile everything as superh.
TARGET_sh_debug_CFLAGS := $(TARGET_sh_release_CFLAGS) -fno-omit-frame-pointer -fno-strict-aliasing

$(combo_target)GLOBAL_CFLAGS += \
			-fpic \
			-ffunction-sections \
			-funwind-tables \
			-fstack-protector \
			-include $(call select-android-config-h,linux-sh)

$(combo_target)GLOBAL_CPPFLAGS += \
			-fno-use-cxa-atexit \
			-fvisibility-inlines-hidden

$(combo_target)RELEASE_CFLAGS := \
			-DSK_RELEASE -DNDEBUG \
			-O2 -g \
			-Wstrict-aliasing=2 \
			-finline-functions \
			-fno-inline-functions-called-once \
			-fgcse-after-reload \
			-frerun-cse-after-loop \
			-frename-registers \
			-fno-builtin

libc_root := bionic/libc
libm_root := bionic/libm
libstdc++_root := bionic/libstdc++
libthread_db_root := bionic/libthread_db


## on some hosts, the target cross-compiler is not available so do not run this command
ifneq ($(wildcard $($(combo_target)CC)),)
# We compile with the global cflags to ensure that
# any flags which affect libgcc are correctly taken
# into account.
LIBGCC_FILENAME := $(shell $($(combo_target)CC) $($(combo_target)GLOBAL_CFLAGS) -print-libgcc-file-name)
LIBGCC_EH_FILENAME := $(subst libgcc,libgcc_eh,$(LIBGCC_FILENAME))
$(combo_target)LIBGCC := $(LIBGCC_EH_FILENAME) $(LIBGCC_FILENAME)
endif

# unless CUSTOM_KERNEL_HEADERS is defined, we're going to use
# symlinks located in out/ to point to the appropriate kernel
# headers. see 'config/kernel_headers.make' for more details
#
ifneq ($(CUSTOM_KERNEL_HEADERS),)
    KERNEL_HEADERS_COMMON := $(CUSTOM_KERNEL_HEADERS)
    KERNEL_HEADERS_ARCH   := $(CUSTOM_KERNEL_HEADERS)
else
    KERNEL_HEADERS_COMMON := $(libc_root)/kernel/common
    KERNEL_HEADERS_ARCH   := $(libc_root)/kernel/arch-$(TARGET_ARCH)
endif
KERNEL_HEADERS := $(KERNEL_HEADERS_COMMON) $(KERNEL_HEADERS_ARCH)

$(combo_target)C_INCLUDES := \
	$(libc_root)/arch-sh/include \
	$(libc_root)/include \
	$(libstdc++_root)/include \
	$(KERNEL_HEADERS) \
	$(libm_root)/include \
	$(libm_root)/include/arch/sh \
	$(libthread_db_root)/include

TARGET_CRTBEGIN_STATIC_O := $(TARGET_OUT_STATIC_LIBRARIES)/crtbegin_static.o
TARGET_CRTBEGIN_DYNAMIC_O := $(TARGET_OUT_STATIC_LIBRARIES)/crtbegin_dynamic.o
TARGET_CRTEND_O := $(TARGET_OUT_STATIC_LIBRARIES)/crtend_android.o
TARGET_SOBEGIN := $(TARGET_OUT_STATIC_LIBRARIES)/sobegin.o
TARGET_SOEND := $(TARGET_OUT_STATIC_LIBRARIES)/soend.o

TARGET_STRIP_MODULE:=true

$(combo_target)DEFAULT_SYSTEM_SHARED_LIBRARIES := libc libstdc++ libm

$(combo_target)CUSTOM_LD_COMMAND := true
define transform-o-to-shared-lib-inner
$(TARGET_CXX) \
	-nostdlib -Wl,-soname,$(notdir $@) -Wl,-T,$(BUILD_SYSTEM)/shlelf.xsc \
	-Wl,--gc-sections -Wl,-z,norelro \
	-Wl,-shared,-Bsymbolic \
	$(TARGET_GLOBAL_LD_DIRS) \
	$(TARGET_SOBEGIN) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-host-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_LDFLAGS) \
	$(subst -lrt,, $(subst -lpthread,,$(PRIVATE_LDLIBS))) \
	$(TARGET_LIBGCC) \
	$(TARGET_SOEND)
endef

define transform-o-to-executable-inner
$(TARGET_CXX) -nostdlib -Bdynamic  -Wl,-T,$(BUILD_SYSTEM)/shlelf.x \
	-Wl,-dynamic-linker,/system/bin/linker \
	-Wl,--gc-sections -Wl,-z,norelro \
	-Wl,-z,nocopyreloc \
	-o $@ \
	$(TARGET_GLOBAL_LD_DIRS) \
	-Wl,-rpath-link=$(TARGET_OUT_INTERMEDIATE_LIBRARIES) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	$(TARGET_CRTBEGIN_DYNAMIC_O) \
	$(PRIVATE_ALL_OBJECTS) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(PRIVATE_LDFLAGS) \
	$(TARGET_LIBGCC) \
	$(subst -lrt,, $(subst -lpthread,,$(PRIVATE_LDLIBS))) \
	$(TARGET_CRTEND_O)
endef

define transform-o-to-static-executable-inner
$(TARGET_CXX) -nostdlib -Bstatic  -Wl,-T,$(BUILD_SYSTEM)/shlelf.x \
	-Wl,--gc-sections -Wl,-z,norelro \
	-o $@ \
	$(TARGET_GLOBAL_LD_DIRS) \
	$(TARGET_CRTBEGIN_STATIC_O) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(TARGET_LIBGCC) \
	$(subst -lrt,, $(subst -lpthread,,$(PRIVATE_LDLIBS))) \
	$(TARGET_CRTEND_O)
endef
