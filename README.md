# NixOS on Pinecube (Early work in progress)

Build an SD card image with `./build.sh`.
Prebuilt image [here](https://drive.google.com/file/d/1A3dreaxXnRpC_tdUey9V5ojnUXhLjLFd/view?usp=sharing) (last updated 2020-11-07).
Decompress and flash with:
```shell
$ cat ./result/sd-image/nixos-sd-image-21.03pre-git-armv7l-linux.img.zst | zstd -d | dd of=/dev/sdX bs=1024
```

It should be accessible over UART2 pins (see pinout on wiki) or SSH.
- Username: `nixos`
- Password: `nixos`

# Additional Notes

## Recording from CSI camera:
 - https://linux-sunxi.org/CSI#CSI_on_mainline_Linux_with_v4l2
 - https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/subdev-formats.html

Streaming via rtmp:

Run a RTMP server on a machine on the network (assuming at 192.168.1.200).

On pinecube
```shell
$ media-ctl --set-v4l2 '"ov5640 1-003c":0[fmt:UYVY8_2X8/640x480@1/15]'
$ ffmpeg -s 640x480 -r 15 -i /dev/video0 -vcodec flv -f flv rtmp://192.168.1.200/live/pinecube
```

On receiving machine:
```shell
$ mpv "rtmp://192.168.1.200/live/pinecube" --profile=low-latency --cache-secs=1
```

To enable audio in the stream: (see section below for further audio details)
```shell
$ media-ctl --set-v4l2 '"ov5640 1-003c":0[fmt:UYVY8_2X8/320x240@1/15]'
$ ffmpeg -s 320x240 -r 15 -i /dev/video0 -f alsa -ac 1 -ar 22050 -i hw:0,0 -acodec libmp3lame -vcodec flv  -f flv rtmp://192.168.1.200/live/pinecube
```
(Ensure that Mic1 is active and unmuted using `alsamixer`)
CPU usage while encoding required me to also lower camera resolution and also the audio sampling rate.
Let me know if you find ffmpeg settings that give a good balance between quality, CPU usage, and bitrate.

## Activating IR LEDs:
```shell
$ echo 1 > /sys/class/leds/pine64\:ir\:led1/brightness
$ echo 1 > /sys/class/leds/pine64\:ir\:led2/brightness
```

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
In Linux, dmesg error: `spi-nor spi0.0: unrecognized JEDEC id bytes: 0b 40 18 0b 40 18`
The published schematic says it's a `GD5F4GQ4UCYIG`, however the label on the pinecube I have is for an `XT25F128B`.
And this matches the JEDEC bytes reported in Linux.

### SPI Boot
Run `nix-build -A firmware-installer`. Then,
```shell
$ dd if=result/firmware-installer-image.img of=/dev/sdX bs=1024
```
Then, use the menu option available over UART2 to install u-boot to the SPI.

I initially flashed a bad u-boot, which caused me to be unable to boot from MMC or even FEL.
I was able to force the Pinecube to load into FEL by grounding the `SPI0_MISO` pin.
Then, I could boot into u-boot and erase the SPI, returning the Pinecube to factory condition.

## Ethernet
Working fine in linux, and now also u-boot with patch derived from: https://lists.denx.de/pipermail/u-boot/2020-May/413924.html
S3 datasheet says it supports up to 1000Mbit, but we only have a 100Mbit PHY: `H1601CG`
Maybe this is for easier PoE support?

## USB
Not working in linux or u-boot.
dmesg reports: `supply vcc not found, using dummy regulator`

## WIFI
`iwlist wlan0 scan` worked fine.
Stopped working after starting `wpa_supplicant`.
Dmesg errors:
```
Oct 19 06:11:31 nixos wpa_supplicant[926]: Successfully initialized wpa_supplicant
Oct 19 06:11:32 nixos kernel: sunxi-mmc 1c10000.mmc: data error, sending stop command
Oct 19 06:11:32 nixos kernel: sunxi-mmc 1c10000.mmc: send stop command failed
```

## Audio
S3 has significant differences when compared with V3s.
It has 4 audio inputs (3 mics, 1 line in), and 2 audio outputs (headphone and line out).
Currently, only the microphone is working. I tried to get audio output working but didn't have any luck.
Use `alsamixer` to ensure mic is active and unmuted.
```shell
$ ffmpeg -f alsa -ar 22050 -i hw:0,0 -acodec mp3 -f flv rtmp://192.168.1.200/live/pinecube
```

## Power Supply
See `/sys/class/power_supply/axp20x-ac`.
See `/sys/class/power_supply/axp20x-battery/{status,capacity}`.
Green LED if power is on.
Red LED if battery is charging.
