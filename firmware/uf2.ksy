meta:
  id: uf2
  title: UF2 (USB Flashing Format)
  file-extension: uf2
  xref:
    wikidata: Q105856672
  license: CC0-1.0
  endian: le
doc: |
  UF2 is a file format, developed by Microsoft for PXT (also known as
  Microsoft MakeCode), that is particularly suitable for flashing
  microcontrollers over MSC (Mass Storage Class; aka removable flash drive).

  The list of family IDs is stored in a separate JSON file:

  <https://github.com/microsoft/uf2/blob/master/utils/uf2families.json>

  This JSON file is regularly updated. The `family_id` enum should be kept in
  sync with it. For simplicity and consistency, it's strongly recommended to
  auto-generate this enum from `uf2families.json` directly. This was last done
  using the following commands:

  ```bash
  $ curl -fsSLO https://github.com/microsoft/uf2/raw/90e9741f217f5a40c98ba74d663e408041037578/utils/uf2families.json
  $ jq -r '
    .[]
    | "    \(.id | ascii_downcase):\n"
    + "      id: \(.short_name | ascii_downcase | gsub("-"; "_"))\n"
    + "      doc: \(.description | tojson)"
  ' uf2families.json
  ```

  Test files can be found on the MicroPython website:

  <https://micropython.org/download/rp2-pico/>

doc-ref: https://github.com/microsoft/uf2/blob/90e9741f217f5a40c98ba74d663e408041037578/README.md
seq:
  - id: uf2_block_start
    type: uf2_block
  - id: uf2_blocks
    type: uf2_block
    repeat: expr
    repeat-expr: uf2_block_start.num_blocks - 1
types:
  uf2_block:
    -webide-representation: 'Block {block_number:dec} - {flags:flags}'
    seq:
      - id: magic
        -orig-id: magicStart0
        contents: "UF2\n"
      - id: second_magic
        -orig-id: magicStart1
        contents: [0x57, 0x51, 0x5d, 0x9e]
      - id: flags
        type: flags
      - id: target_address
        -orig-id: targetAddr
        type: u4
      - id: len_payload
        -orig-id: payloadSize
        type: u4
      - id: block_number
        -orig-id: blockNo
        type: u4
      - id: num_blocks
        -orig-id: numBlocks
        type: u4
      - id: file_size
        -orig-id: fileSize
        type: u4
        if: not flags.has_family_id
      - id: family_id
        -orig-id: familyID
        type: u4
        enum: family_id
        if: flags.has_family_id
      - id: data
        size: 476
      - id: final_magic
        -orig-id: magicEnd
        contents: [0x30, 0x6f, 0xb1, 0x0a]
  flags:
    doc-ref:
      - https://github.com/microsoft/uf2/blob/90e9741f217f5a40c98ba74d663e408041037578/uf2.h#L43-L47
      - https://github.com/raspberrypi/pico-sdk/blob/98a542c1a62fb549ffb5d66a3e5892b06276b670/src/common/boot_uf2_headers/include/boot/uf2.h#L23-L27 Git tag "2.3.0"
    seq:
      - id: value
        type: u4
    instances:
      not_main_flash:
        -orig-id:
          - UF2_FLAG_NOFLASH # microsoft/uf2
          - UF2_FLAG_NOT_MAIN_FLASH # raspberrypi/pico-sdk
        value: value & 0x0000_0001 != 0
        doc: |
          Indicates that this block should be skipped when writing the device
          flash. It can be used to store data that does not fit on the device,
          typically embedded source code or debug info.
      is_file_container:
        -orig-id:
          - UF2_FLAG_FILECONTAINER # microsoft/uf2
          - UF2_FLAG_FILE_CONTAINER # raspberrypi/pico-sdk
        value: value & 0x0000_1000 != 0
        doc: |
          When set, the UF2 format is used as a container for regular files
          (akin to a TAR file, or ZIP archive without compression).

          `target_address` is the offset within the current file where the
          payload should be written and `file_size` is the size of that file.
          The file name is stored in `data` right after the payload, terminated
          with a `0x00` byte.
      has_family_id:
        -orig-id:
          - UF2_FLAG_FAMILY_ID # microsoft/uf2
          - UF2_FLAG_FAMILY_ID_PRESENT # raspberrypi/pico-sdk
        value: value & 0x0000_2000 != 0
        doc: |
          The field at offset 28 is `family_id` instead of `file_size`.
      has_md5_checksum:
        -orig-id:
          - UF2_FLAG_MD5_CHKSUM # microsoft/uf2
          - UF2_FLAG_MD5_PRESENT # raspberrypi/pico-sdk
        value: value & 0x0000_4000 != 0
        doc: |
          The last 24 bytes of `data` hold the start address (`u4`), the length
          (`u4`) and the MD5 checksum (16 bytes) of a region that doesn't need
          to be flashed again if the checksum matches.
      has_extension_tags:
        -orig-id:
          - UF2_FLAG_EXTENSION_TAGS # microsoft/uf2
          - UF2_FLAG_EXTENSION_FLAGS_PRESENT # raspberrypi/pico-sdk
        value: value & 0x0000_8000 != 0
        doc: |
          A list of tags follows the payload, i.e. it starts at
          `data[len_payload]`. Every tag is 4-byte aligned and consists of its
          total size in bytes (`u1`), its type (3 bytes) and its value. The list
          is terminated by a tag of size 0 and type 0.
enums:
  family_id:
    0x16573617:
      id: atmega32
      doc: "Microchip (Atmel) ATmega32"
    0x1851780a:
      id: saml21
      doc: "Microchip (Atmel) SAML21"
    0x1b57745f:
      id: nrf52
      doc: "Nordic NRF52"
    0x1c5f21b0:
      id: esp32
      doc: "ESP32"
    0x1e1f432d:
      id: stm32l1
      doc: "ST STM32L1xx"
    0x202e3a91:
      id: stm32l0
      doc: "ST STM32L0xx"
    0x21460ff0:
      id: stm32wl
      doc: "ST STM32WLxx"
    0x22e0d6fc:
      id: rtl8710b
      doc: "Realtek AmebaZ RTL8710B"
    0x2abc77ec:
      id: lpc55
      doc: "NXP LPC55xx"
    0x300f5633:
      id: stm32g0
      doc: "ST STM32G0xx"
    0x31d228c6:
      id: gd32f350
      doc: "GD32F350"
    0x3379cfe2:
      id: rtl8720d
      doc: "Realtek AmebaD RTL8720D"
    0x04240bdf:
      id: stm32l5
      doc: "ST STM32L5xx"
    0x4c71240a:
      id: stm32g4
      doc: "ST STM32G4xx"
    0x4fb2d5bd:
      id: mimxrt10xx
      doc: "NXP i.MX RT10XX"
    0x51e903a8:
      id: xr809
      doc: "Xradiotech 809"
    0x53b80f00:
      id: stm32f7
      doc: "ST STM32F7xx"
    0x55114460:
      id: samd51
      doc: "Microchip (Atmel) SAMD51"
    0x57755a57:
      id: stm32f4
      doc: "ST STM32F4xx"
    0x5a18069b:
      id: fx2
      doc: "Cypress FX2"
    0x5d1a0a2e:
      id: stm32f2
      doc: "ST STM32F2xx"
    0x5ee21072:
      id: stm32f1
      doc: "ST STM32F103"
    0x621e937a:
      id: nrf52833
      doc: "Nordic NRF52833"
    0x647824b6:
      id: stm32f0
      doc: "ST STM32F0xx"
    0x675a40b0:
      id: bk7231u
      doc: "Beken 7231U/7231T"
    0x68ed2b88:
      id: samd21
      doc: "Microchip (Atmel) SAMD21"
    0x6a82cc42:
      id: bk7251
      doc: "Beken 7251/7252"
    0x6b846188:
      id: stm32f3
      doc: "ST STM32F3xx"
    0x6d0922fa:
      id: stm32f407
      doc: "ST STM32F407"
    0x4e8f1c5d:
      id: stm32h5
      doc: "ST STM32H5xx"
    0x6db66082:
      id: stm32h7
      doc: "ST STM32H7xx"
    0x70d16653:
      id: stm32wb
      doc: "ST STM32WBxx"
    0x7b3ef230:
      id: bk7231n
      doc: "Beken 7231N"
    0x7eab61ed:
      id: esp8266
      doc: "ESP8266"
    0x7f83e793:
      id: kl32l2
      doc: "NXP KL32L2x"
    0x8fb060fe:
      id: stm32f407vg
      doc: "ST STM32F407VG"
    0x9fffd543:
      id: rtl8710a
      doc: "Realtek Ameba1 RTL8710A"
    0xada52840:
      id: nrf52840
      doc: "Nordic NRF52840"
    0x820d9a5f:
      id: nrf52820
      doc: "Nordic NRF52820_xxAA"
    0xbfdd4eee:
      id: esp32s2
      doc: "ESP32-S2"
    0xc47e5767:
      id: esp32s3
      doc: "ESP32-S3"
    0xd42ba06c:
      id: esp32c3
      doc: "ESP32-C3"
    0x2b88d29c:
      id: esp32c2
      doc: "ESP32-C2"
    0x332726f6:
      id: esp32h2
      doc: "ESP32-H2"
    0x540ddf62:
      id: esp32c6
      doc: "ESP32-C6"
    0x3d308e94:
      id: esp32p4
      doc: "ESP32-P4"
    0xf71c0343:
      id: esp32c5
      doc: "ESP32-C5"
    0x77d850c4:
      id: esp32c61
      doc: "ESP32-C61"
    0xb6dd00af:
      id: esp32h21
      doc: "ESP32-H21"
    0x9e0baa8a:
      id: esp32h4
      doc: "ESP32-H4"
    0x3101f7c1:
      id: esp32s31
      doc: "ESP32-S31"
    0xde1270b7:
      id: bl602
      doc: "Boufallo 602"
    0xe08f7564:
      id: rtl8720c
      doc: "Realtek AmebaZ2 RTL8720C"
    0xe48bff56:
      id: rp2040
      doc: "Raspberry Pi RP2040"
    0xe48bff57:
      id: rp2xxx_absolute
      doc: "Raspberry Pi Microcontrollers: Absolute (unpartitioned) download"
    0xe48bff58:
      id: rp2xxx_data
      doc: "Raspberry Pi Microcontrollers: Data partition download"
    0xe48bff59:
      id: rp2350_arm_s
      doc: "Raspberry Pi RP2350, Secure Arm image"
    0xe48bff5a:
      id: rp2350_riscv
      doc: "Raspberry Pi RP2350, RISC-V image"
    0xe48bff5b:
      id: rp2350_arm_ns
      doc: "Raspberry Pi RP2350, Non-secure Arm image"
    0x00ff6919:
      id: stm32l4
      doc: "ST STM32L4xx"
    0x9af03e33:
      id: gd32vf103
      doc: "GigaDevice GD32VF103"
    0x4f6ace52:
      id: csk4
      doc: "LISTENAI CSK300x/400x"
    0x6e7348a8:
      id: csk6
      doc: "LISTENAI CSK60xx"
    0x11de784a:
      id: m0sense
      doc: "M0SENSE BL702"
    0x4b684d71:
      id: maixplay_u4
      doc: "Sipeed MaixPlay-U4(BL618)"
    0x9517422f:
      id: rza1lu
      doc: "Renesas RZ/A1LU (R7S7210xx)"
    0x2dc309c5:
      id: stm32f411xe
      doc: "ST STM32F411xE"
    0x06d1097b:
      id: stm32f411xc
      doc: "ST STM32F411xC"
    0x72721d4e:
      id: nrf52832xxaa
      doc: "Nordic NRF52832xxAA"
    0x6f752678:
      id: nrf52832xxab
      doc: "Nordic NRF52832xxAB"
    0xa0c97b8e:
      id: at32f415
      doc: "ArteryTek AT32F415"
    0x699b62ec:
      id: ch32v
      doc: "WCH CH32V2xx and CH32V3xx"
    0x7be8976d:
      id: ra4m1
      doc: "Renesas RA4M1"
    0x7410520a:
      id: max32690
      doc: "Analog Devices MAX32690"
    0xd63f8632:
      id: max32650
      doc: "Analog Devices MAX32650/1/2"
    0xf0c30d71:
      id: max32666
      doc: "Analog Devices MAX32665/6"
    0x91d3fd18:
      id: max78002
      doc: "Analog Devices MAX78002"
    0x7d7a66ef:
      id: py32f071_uvk5_v3
      doc: "Quansheng UV-K5 V3 amateur radio based on Puya Semiconductor PY32F071"
