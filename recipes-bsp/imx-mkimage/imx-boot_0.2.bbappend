FILESEXTRAPATHS_prepend := "${THISDIR}/files:"


IMXBOOT_TARGETS_append_mx8mq = " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'first_boot_loader', '', d)}"
IMXBOOT_TARGETS_append_mx8mm = " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'first_boot_loader_flexspi', '', d)}"
IMXBOOT_TARGETS_mx8mm = "flash_evk_flexspi"

UBOOT_CONFIG_mx8mm = "fspi"

SRC_URI_append =  " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'file://0001-imx8mq-Generate-fbl.bin-as-first-boot-loader.patch', '', d)}"
SRC_URI_append =  " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'file://0003-imx8mm-Generate-fbl.bin-for-QSPI-NOR-Flash-Boot.patch', '', d)}"
SRC_URI_append =  " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'file://0004-Add-the-script-to-generate-F-Q-SPI-FBL-Image.patch', '', d)}"
SRC_URI_append =  " ${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'file://0005-fspi_packer_fbl.sh-change-mod.patch', '', d)}"

OTA = "${@bb.utils.contains('DISTRO_FEATURES', 'ota', 'true', 'false', d)}"
#solution and bootstap need remove tee.bin
DEPLOY_OPTEE = "false"
do_compile () {
    if [[ "${SOC_TARGET}" == "iMX8M"* ]]; then
        #8MQ/8MM/8MN boot binary build
        echo "${SOC_TARGET} boot binary build"
        for ddr_firmware in ${DDR_FIRMWARE_NAME}; do
            echo "Copy ddr_firmware: ${ddr_firmware} from ${DEPLOY_DIR_IMAGE} -> ${BOOT_STAGING} "
            cp ${DEPLOY_DIR_IMAGE}/${ddr_firmware}               ${BOOT_STAGING}/
        done
        cp ${DEPLOY_DIR_IMAGE}/signed_*_imx8m.bin             ${BOOT_STAGING}/
        cp ${DEPLOY_DIR_IMAGE}/u-boot-spl.bin-${MACHINE}-${UBOOT_CONFIG} ${BOOT_STAGING}/u-boot-spl.bin
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${UBOOT_DTB_NAME}   ${BOOT_STAGING}/
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/u-boot-nodtb.bin-${MACHINE}-${UBOOT_CONFIG}    ${BOOT_STAGING}/u-boot-nodtb.bin
        ln -sf ${STAGING_DIR_NATIVE}${bindir}/mkimage              ${BOOT_STAGING}/mkimage_uboot
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${ATF_MACHINE_NAME} ${BOOT_STAGING}/bl31.bin
        cp ${DEPLOY_DIR_IMAGE}/${UBOOT_NAME}                     ${BOOT_STAGING}/u-boot.bin

    elif [ "${SOC_TARGET}" = "iMX8QM" ]; then
        echo 8QM boot binary build
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${SC_FIRMWARE_NAME} ${BOOT_STAGING}/scfw_tcm.bin
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${ATF_MACHINE_NAME} ${BOOT_STAGING}/bl31.bin
        cp ${DEPLOY_DIR_IMAGE}/${UBOOT_NAME}                     ${BOOT_STAGING}/u-boot.bin
        if [ -e ${DEPLOY_DIR_IMAGE}/u-boot-spl.bin-${MACHINE}-${UBOOT_CONFIG} ] ; then
            cp ${DEPLOY_DIR_IMAGE}/u-boot-spl.bin-${MACHINE}-${UBOOT_CONFIG} \
                                                             ${BOOT_STAGING}/u-boot-spl.bin
        fi

        cp ${DEPLOY_DIR_IMAGE}/imx8qm_m4_0_TCM_rpmsg_lite_pingpong_rtos_linux_remote_m40.bin ${BOOT_STAGING}/m4_image.bin
        cp ${DEPLOY_DIR_IMAGE}/imx8qm_m4_1_TCM_power_mode_switch_m41.bin ${BOOT_STAGING}/m4_1_image.bin
        cp ${DEPLOY_DIR_IMAGE}/${SECO_FIRMWARE} ${BOOT_STAGING}/
    
    else
        echo 8QX boot binary build
        cp ${DEPLOY_DIR_IMAGE}/${M4_DEFAULT_IMAGE}               ${BOOT_STAGING}/m4_image.bin
        cp ${DEPLOY_DIR_IMAGE}/${SECO_FIRMWARE}                  ${BOOT_STAGING}
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${SC_FIRMWARE_NAME} ${BOOT_STAGING}/scfw_tcm.bin
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${ATF_MACHINE_NAME} ${BOOT_STAGING}/bl31.bin
        cp ${DEPLOY_DIR_IMAGE}/${UBOOT_NAME}                     ${BOOT_STAGING}/u-boot.bin
        if [ -e ${DEPLOY_DIR_IMAGE}/u-boot-spl.bin-${MACHINE}-${UBOOT_CONFIG} ] ; then
            cp ${DEPLOY_DIR_IMAGE}/u-boot-spl.bin-${MACHINE}-${UBOOT_CONFIG} \
                                                             ${BOOT_STAGING}/u-boot-spl.bin
        fi
    fi

    # Copy TEE binary to SoC target folder to mkimage
    if ${DEPLOY_OPTEE}; then
        cp ${DEPLOY_DIR_IMAGE}/tee.bin             ${BOOT_STAGING}/
    fi

    # mkimage for i.MX8
    for target in ${IMXBOOT_TARGETS}; do
        echo "building ${SOC_TARGET} - ${target}"
        make SOC=${SOC_TARGET} ${target}
        if [ -e "${BOOT_STAGING}/flash.bin" ]; then
            cp ${BOOT_STAGING}/flash.bin ${S}/${BOOT_CONFIG_MACHINE}-${target}
        fi
    done
}



do_deploy_append () {
    if [ -e ${BOOT_STAGING}/u-boot.itb ]; then
       install -m 0644 ${BOOT_STAGING}/u-boot.itb ${DEPLOYDIR}/${BOOT_TOOLS}
    fi
    if [ "${OTA}" = "true" ];then 
        install -m 0644 ${BOOT_STAGING}/fbl.bin ${DEPLOYDIR}/${BOOT_TOOLS}
    fi
}
