# NixOS on Pinecube (Early work in progress)

Build an SD card image with `./build.sh`.
Prebuilt image [here]() (updated 2020-10-18)
Decompress and flash with:
```shell
$ zstd -d result/sd-image/nixos-sd-image-21.03pre-git-armv7l-linux.img.zst -o nixos-pinecube.img
$ dd if=./nixos-pinecube.img of=/dev/<sdcard> bs=1024
```

Should be accessible over UART2 pins (see pinout on wiki) or SSH.
- Username: `nixos`
- Password: `nixos`

# Additional Notes

## Recording from CSI camera:
 - https://linux-sunxi.org/CSI#CSI_on_mainline_Linux_with_v4l2
 - https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/subdev-formats.html
```shell
$ media-ctl --set-v4l2 '"ov5640 1-003c":0[fmt:YUYV8_2X8/640x480]'
$ ffmpeg -s 640x480 -r 10 -i /dev/video0 -vcodec libx264 -preset ultrafast -tune zerolatency -f flv rtmp://192.168.1.200/live/pinecube
```

## Activating LEDs:
https://elinux.org/CI20_GPIO_LED_Blink_Tutorial#Controlling_GPIOs_from_the_shell_.28Linux.27_sysfs_interface_for_GPIOs.29
```shell
$ echo 1 > /sys/class/leds/pine64\:ir\:led1/brightness
```
(Except they seem to be reversed. Setting 0 brightness turns them on, setting 1 turns them off)
Change it to `ACTIVE_HIGH` in dtb?

## GPIO:
https://linux-sunxi.org/GPIO
```shell
$ cat /sys/kernel/debug/pinctrl/1c20800.pinctrl/pinmux-pins
```
gives information about pin numbering and what pins already claimed for other things

Audio is not in currently in DTB at all.
Maybe use sun7i-a20 as example. It has a "codec" block.
See the S3 manual, grep for I2S/PCM.

## SPI NOR
dmesg error: `spi-nor spi0.0: unrecognized JEDEC id bytes: 0b 40 18 0b 40 18`

## WIFI
Not working

## Ethernet
Working fine in linux. U-boot needs support
