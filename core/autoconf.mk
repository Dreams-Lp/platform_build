##
# LOCAL_MODULE
# LOCAL_CONFIG_ARGS
# LOCAL_PKG_BINARIES
# LOCAL_PKG_SHARED_LIBRARIES
# LOCAL_PKG_DATA_FILES
# LOCAL_CONFIG_ENV

TOPDIR:=$(shell pwd)/

_ac_outputs := $(LOCAL_PKG_BINARIES) $(LOCAL_PKG_SHARED_LIBRARIES) \
	$(LOCAL_PKG_DATA_FILES)
_ac_outputs :=$(strip $(_ac_outputs))
_my_prefix := $(LOCAL_MODULE)_

_ac_configure := $(LOCAL_PATH)/configure

_ac_first_module := $(word 1,$(_ac_outputs))

_saved_LOCAL_CONFIG_ARGS:=$(LOCAL_CONFIG_ARGS)
_saved_LOCAL_PKG_BINARIES:=$(LOCAL_PKG_BINARIES)
_saved_LOCAL_PKG_SHARED_LIBRARIES:=$(LOCAL_PKG_SHARED_LIBRARIES)
_saved_LOCAL_PKG_DATA_FILES:=$(LOCAL_PKG_DATA_FILES)
_saved_LOCAL_CONFIG_ENV:=$(LOCAL_CONFIG_ENV)

# $(1): binary name
# $(2): class
define _ac_init_module
$(eval include $(CLEAR_VARS))
$(eval _mod_bin:=$(1))
$(eval _mod_name:=$(_my_prefix)$(subst -,_,$(subst .,_,$(_mod_bin))))
$(eval LOCAL_MODULE:=$(_mod_name))
$(eval LOCAL_MODULE_CLASS:=$(2))
$(eval LOCAL_MODULE_STEM:=$(notdir $(_mod_bin)))
$(eval LOCAL_STRIP_MODULE:=false)

$(eval include $(BUILD_SYSTEM)/dynamic_binary.mk)
$(if $(filter-out $(_ac_first_module),$(_mod_bin)),,\
	$(eval _ac_work:=$(dir $(linked_module))work))

$(linked_module): $(_ac_work)/make_done
	$(hide) mkdir -p $(dir $(linked_module));\
	cp $(_ac_work)/$(_mod_bin) $(linked_module)

endef

$(eval $(foreach mod,$(_saved_LOCAL_PKG_BINARIES), \
	$(call _ac_init_module,$(mod),EXECUTABLES)))

$(eval $(foreach mod,$(_saved_LOCAL_PKG_SHARED_LIBRARIES), \
	$(call _ac_init_module,$(mod),SHARED_LIBRARIES)))

_ac_mk:= $(_ac_work)/Makefile

$(_ac_work)/make_done: $(_ac_mk)
	$(hide) make -C $(_ac_work); touch $(_ac_work)

$(_ac_mk): $(_ac_configure)
	$(hide) mkdir -p $(_ac_work); cd $(_ac_work); \
	$(_saved_LOCAL_CONFIG_ENV) $(TOPDIR)$(_ac_configure) \
	$(_saved_LOCAL_CONFIG_ARGS)
