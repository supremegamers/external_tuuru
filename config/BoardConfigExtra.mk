# Charger
ifneq ($(WITH_XOS_CHARGER),false)
    BOARD_HAL_STATIC_LIBRARIES := libhealthd.xos
endif
