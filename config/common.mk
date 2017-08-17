
# Custom off-mode charger
ifneq ($(WITH_XOS_CHARGER),false)
PRODUCT_PACKAGES += \
    charger_res_images \
    xos_charger_res_images \
    font_log.png \
    libhealthd.xos
endif
