meta:
  id: f2fs
  title: F2FS
  license: CC-1.0
  ks-version: 0.9
  endian: le
types:
  superblock:
    seq:
      - id: magic
        contents: [0x10, 0x20, 0xf5, 0xf2]
      - id: major_version
        type: u2
      - id: minor_version
        type: u2
      - id: log_sectorsize
        type: u4
      - id: log_sectors_per_block
        type: u4
      - id: log_blocksize
        type: u4
      - id: log_blocks_per_seg
        type: u4
      - id: segs_per_sec
        type: u4
      - id: secs_per_zone
        type: u4
      - id: checksum_offset
        type: u4
      - id: block_count
        type: u8
      - id: section_count
        type: u4
      - id: segment_count
        type: u4
      - id: segment_count_ckpt
        type: u4
      - id: segment_count_sit
        type: u4
      - id: segment_count_nat
        type: u4
      - id: segment_count_ssa
        type: u4
      - id: segment_count_main
        type: u4
      - id: segment0_blkaddr
        type: u4
      - id: cp_blkaddr
        type: u4
      - id: sit_blkaddr
        type: u4
      - id: nat_blkaddr
        type: u4
      - id: ssa_blkaddr
        type: u4
      - id: main_blkaddr
        type: u4
      - id: root_ino
        type: u4
      - id: node_ino
        type: u4
      - id: meta_ino
        type: u4
      - id: uuid
        size: 16
      - id: volume_name
        type: strz
        encoding: UTF-8
        size: 2*512
        doc: define MAX_VOLUME_NAME 512
      - id: extension_count
        type: u4
      - id: extension_list
        size: 64
        repeat: expr
        repeat-expr: 8
        doc: define F2FS_MAX_EXTENSION 64
      - id: cp_payload
        type: u4
      - id: version
        type: strz
        encoding: UTF-8
        size: 256
        doc: define VERSION_LEN 256
      - id: init_version
        type: strz
        encoding: UTF-8
        size: 256
        doc: define VERSION_LEN 256
      - id: feature
        type: u4
      - id: encryption_level
        type: u1
      - id: encrypt_pw_salt
        size: 16
      - id: devs
        type: f2fs_device
        repeat: expr
        repeat-expr: 8
        doc: MAX_DEVICES 8
      - id: qf_ino
        type: u4
        repeat: expr
        repeat-expr: 3
        doc: F2FS_MAX_QUOTAS 3
      - id: hot_ext_count
        type: u1
      - id: s_encoding
        type: u2
      - id: s_encoding_flags
        type: u2
      - id: reserved
        size: 306
      - id: crc
        type: u4
  f2fs_device:
    seq:
      - id: path
        size: 64
        doc: MAX_PATH_LEN 64
      - id: total_segments
        type: u4
  checkpoint:
    seq:
      - id: checkpoint_ver
        type: u8
      - id: user_block_count
        type: u8
      - id: valid_block_count
        type: u8
      - id: rsvd_segment_count
        type: u4
      - id: overprov_segment_count
        type: u4
      - id: free_segment_count
        type: u4
      - id: cur_node_segno
        type: u4
        repeat: 8
        doc: define MAX_ACTIVE_NODE_LOG 8
      - id: cur_node_blkoff
        type: u4
        repeat: expr
        repeat-expr: 8
        doc: define MAX_ACTIVE_NODE_LOG 8
      - id: cur_data_segno
        tpe: u4
        repeat: expr
        repeat-expr: 8
        doc: define MAX_ACTIVE_DATA_LOGS 8
      - id: cur_data_blkoff
        tpe: u2
        repeat: expr
        repeat-expr: 8
        doc: define MAX_ACTIVE_DATA_LOGS 8
      - id: ckpt_flags
        type: u4
      - id: cp_pack_total_block_count
        type: u4
      - id: cp_pack_start_sum
        type: u4
      - id: valid_node_count
        type: u4
      - id: valid_inode_count
        type: u4
      - id: next_free_nid
        type: u4
      - id: sit_ver_bitmap_bytesize
        type: u4
      - id: nat_ver_bitmap_bytesize
        type: u4
      - id: checksum_offset
        type: u4
      - id: elapsed_time
        type: u8
      - id: alloc_type
        size: 16
        doc: define MAX_ACTIVE_LOGS 16
      - id: sit_nat_version_bitmap
        size: 1
instances:
  f2fs_superblock:
    type: superblock
    pos: 1024
    doc: define F2FS_SUPER_OFFSET 1024
  f2fs_superblock_backup:
    type: superblock
    pos: 4096+1024
    doc: |
      define F2FS_SUPER_OFFSET 1024
      define PAGE_SIZE 4096
