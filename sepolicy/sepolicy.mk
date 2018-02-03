include external/xos/sepolicy/common/sepolicy.mk
ifeq ($(BOARD_USES_QCOM_HARDWARE), true)
include external/xos/sepolicy/qcom/sepolicy.mk
endif