# NixOS on Pinecube (Early work in progress)

Build an SD card image with `./build.sh`.
Prebuilt image [here](https://drive.google.com/file/d/11mBzfGHeLLP26nse0ntxUWxuBqUYKiIK/view?usp=sharing). (updated 2020-10-18)
Decompress and flash with:
```shell
$ cat ./result/sd-image/nixos-sd-image-21.03pre-git-armv7l-linux.img.zst | zstd -d | dd of=/dev/<sdcard> bs=1024
```

Should be accessible over UART2 pins (see pinout on wiki) or SSH.
- Username: `nixos`
- Password: `nixos`

# Additional Notes

## Recording from CSI camera:
 - https://linux-sunxi.org/CSI#CSI_on_mainline_Linux_with_v4l2
 - https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/subdev-formats.html

Streaming via rtmp:
```shell
$ media-ctl --set-v4l2 '"ov5640 1-003c":0[fmt:UYVY8_2X8/640x480@1/15]'
$ ffmpeg -s 640x480 -r 15 -i /dev/video0 -vcodec flv -f flv rtmp://192.168.1.200/live/pinecube
```

On receiving machine:
```shell
$ mpv "rtmp://192.168.1.200/live/pinecube" --profile=low-latency --cache-secs=1
```

## Activating IR LEDs:
```shell
$ echo 1 > /sys/class/leds/pine64\:ir\:led1/brightness
$ echo 1 > /sys/class/leds/pine64\:ir\:led2/brightness
```
(Except they seem to be reversed. Setting 0 brightness turns them on, setting 1 turns them off)
Change it to `ACTIVE_HIGH` in dtb?

## GPIO:
https://linux-sunxi.org/GPIO
```shell
$ cat /sys/kernel/debug/pinctrl/1c20800.pinctrl/pinmux-pins
```
gives information about pin numbering and what pins already claimed for other things

### Enabling/disabling IR-cut filter
```shell
# Export gpio, set direction
$ echo 45 > /sys/class/gpio/export
$ echo out > /sys/class/gpio/gpio45/direction

# 1 to enable, 0 to disable
$ echo 1 > /sys/class/gpio/gpio45/value
```

### Passive IR detection
```shell
# Export gpio, set direction
$ echo 199 > /sys/class/gpio/export
$ echo in > /sys/class/gpio/gpio199/direction

# Returns 1 for presence, 0 for none
$ cat /sys/class/gpio/gpio199/value
```

## SPI NOR
dmesg error: `spi-nor spi0.0: unrecognized JEDEC id bytes: 0b 40 18 0b 40 18`

## Ethernet
Working fine in linux, and now also u-boot with patch derived from: https://lists.denx.de/pipermail/u-boot/2020-May/413924.html

## USB
Not working in linux or u-boot
dmesg reports: `supply vcc not found, using dummy regulator`

## WIFI
Dmesg errors:
```
Oct 19 06:11:31 nixos wpa_supplicant[926]: Successfully initialized wpa_supplicant
Oct 19 06:11:32 nixos kernel: sunxi-mmc 1c10000.mmc: data error, sending stop command
Oct 19 06:11:32 nixos kernel: sunxi-mmc 1c10000.mmc: send stop command failed
```

## Audio
Is not in currently in DTB at all.
Maybe use sun7i-a20 as example. It has a "codec" block.
See the S3 manual, grep for I2S/PCM.
