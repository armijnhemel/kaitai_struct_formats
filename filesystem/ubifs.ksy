meta:
  id: ubifs
  title: UBIfs
  license: CC-1.0
  ks-version: 0.9
  endian: le
seq:
  - id: leb0
    type: leb0
  #- id: lebs
    #type: leb
    #size: leb0.sb_node.leb_size
    #repeat: expr
    #repeat-expr: leb0.sb_node.leb_cnt
types:
  leb0:
    seq:
      - id: sb_node
        type: sb_node
      - id: leb0_body
        type: leb
        size: sb_node.leb_size - sb_node._sizeof
  leb:
    seq:
      - id: nodes
        type: node
        #repeat: eos
        repeat: expr
        repeat-expr: 2
  common_header:
    seq:
      - id: magic
        contents: [0x31, 0x18, 0x10, 0x06]
      - id: crc
        type: u4
      - id: sqnum
        type: u8
      - id: len
        type: u4
      - id: node_type
        type: u1
        enum: node_types
      - id: group_type
        type: u1
      - id: reserved
        contents: [0, 0]
  node:
    seq:
      - id: header
        type: common_header
      - id: node_contents
        size: header.len - header._sizeof
        type:
          switch-on: header.node_type
          cases:
            #node_types::ino_node: ino_node
            node_types::data_node: data_node
            node_types::dent_node: dent_node
            node_types::xent_node: dent_node # identical to dent_node
            node_types::trun_node: trun_node
            node_types::pad_node: pad_node
            node_types::mst_node: mst_node
            node_types::ref_node: ref_node
            node_types::idx_node: idx_node
            node_types::cs_node: cs_node
            node_types::orph_node: orph_node
            node_types::auth_node: auth_node
            node_types::sig_node: sig_node
      - id: padding
        if: "header.node_type == node_types::pad_node"
        size: node_contents.pad_len
  ino_node:
    seq:
      - id: key
        size: 16
        doc: define UBIFS_MAX_KEY_LEN 16
      - id: creat_sqnum
        type: u8
      - id: size
        type: u8
      - id: atime_sec
        type: u8
      - id: ctime_sec
        type: u8
      - id: mtime_sec
        type: u8
      - id: atime_nsec
        type: u4
      - id: ctime_nsec
        type: u4
      - id: mtime_nsec
        type: u4
      - id: nlink
        type: u4
      - id: uid
        type: u4
      - id: gid
        type: u4
      - id: mode
        type: u4
      - id: flags
        type: u4
      - id: data_len
        type: u4
      - id: xattr_cnt
        type: u4
      - id: xattr_size
        type: u4
      - id: padding1
        size: 4
      - id: xattr_names
        type: u4
      - id: compr_type
        type: u2
        enum: compression
      - id: padding2
        size: 26
      - id: data
        size: data_len
  data_node:
    seq:
      - id: key
        size: 16
        doc: define UBIFS_MAX_KEY_LEN 16
      - id: size
        type: u4
      - id: compr_type
        type: u2
        enum: compression
      - id: compr_size
        type: u2
      - id: data
        size: size
  dent_node:
    seq:
      - id: key
        size: 16
        doc: define UBIFS_MAX_KEY_LEN 16
      - id: inum
        type: u8
      - id: padding
        size: 1
      - id: type
        type: u1
      - id: nlen
        type: u2
      - id: cookie
        type: u4
      - id: name
        size: nlen
  trun_node:
    seq:
      - id: inum
        type: u4
      - id: padding
        size: 12
      - id: old_size
        type: u8
      - id: new_size
        type: u8
  pad_node:
    seq:
      - id: pad_len
        type: u4
  sb_node:
    seq:
      - id: common_header
        type: common_header
      - id: padding1
        size: 2
      - id: key_hash
        type: u1
      - id: key_fmt
        type: u1
      - id: flags
        type: u4
      - id: min_io_size
        type: u4
      - id: leb_size
        type: u4
      - id: leb_cnt
        type: u4
      - id: max_leb_cnt
        type: u4
      - id: max_bud_bytes
        type: u8
      - id: log_lebs
        type: u4
      - id: lpt_lebs
        type: u4
      - id: orph_lebs
        type: u4
      - id: jhead_cnt
        type: u4
      - id: fanout
        type: u4
      - id: lsave_cnt
        type: u4
      - id: fmt_version
        type: u4
      - id: default_compr
        type: u2
        enum: compression
      - id: padding2
        size: 2
      - id: rp_uid
        type: u4
      - id: rp_gid
        type: u4
      - id: rp_size
        type: u8
      - id: time_gran
        type: u4
      - id: uuid
        size: 16
      - id: compat_version
        type: u4
      - id: hmac # only format version 5
        size: 64
        doc: define UBIFS_MAX_HMAC_LEN 64
      - id: hmac_wkm # only format version 5
        size: 64
        doc: define UBIFS_MAX_HMAC_LEN 64
      - id: hash_algo # only format version 5
        type: u2
      - id: hash_mst # only format version 5
        size: 64
        doc: define UBIFS_MAX_HASH_LEN 64
      - id: padding3
        size: 3774
  mst_node:
    seq:
      - id: highest_inum
        type: u8
      - id: cmt_no
        type: u8
      - id: flags
        type: u4
      - id: log_lnum
        type: u4
      - id: root_lnum
        type: u4
      - id: root_offs
        type: u4
      - id: root_len
        type: u4
      - id: gc_lnum
        type: u4
      - id: ihead_lnum
        type: u4
      - id: ihead_offs
        type: u4
      - id: index_size
        type: u8
      - id: total_free
        type: u8
      - id: total_dirty
        type: u8
      - id: total_used
        type: u8
      - id: total_dead
        type: u8
      - id: total_dark
        type: u8
      - id: lpt_lnum
        type: u4
      - id: lpt_offs
        type: u4
      - id: lpt_nhead_offs
        type: u4
      - id: ltab_lnum
        type: u4
      - id: ltab_offs
        type: u4
      - id: lsave_lnum
        type: u4
      - id: lsave_offs
        type: u4
      - id: lscan_lnum
        type: u4
      - id: empty_lebs
        type: u4
      - id: idx_lebs
        type: u4
      - id: leb_cnt
        type: u4
      - id: hash_root_idx
        size: 64
        doc: UBIFS_MAX_HASH_LEN
      - id: hash_lpt
        size: 64
        doc: UBIFS_MAX_HASH_LEN
      - id: hmac
        size: 64
        doc: UBIFS_MAX_HMAC_LEN
      - id: padding
        size: 152
  ref_node:
    seq:
      - id: lnum
        type: u4
      - id: offs
        type: u4
      - id: jhead
        type: u4
      - id: padding
        size: 28
  idx_node:
    seq:
      - id: child_cnt
        type: u2
      - id: level
        type: u2
      - id: branches
        type: u1
	#__u8 branches[];
        # TODO
  cs_node:
    seq:
      - id: cmt_no
        type: u8
  orph_node:
    seq:
      - id: cmt_no
        type: u8
      - id: inos
        type: u8
        repeat: eos
  auth_node:
    seq:
      - id: hmac
        type: u1
        repeat: eos
  sig_node:
    seq:
      - id: type
        type: u4
      - id: len
        type: u4
      - id: padding
        size: 32
      - id: sig
        size: len
enums:
  node_types:
    0: ino_node
    1: data_node
    2: dent_node
    3: xent_node
    4: trun_node
    5: pad_node
    6: sb_node
    7: mst_node
    8: ref_node
    9: idx_node
    10: cs_node
    11: orph_node
    12: auth_node
    13: sig_node
  compression:
    0: no_compression
    1: lzo
    2: zlib
    3: zstd
