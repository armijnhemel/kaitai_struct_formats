meta:
  id: rpm
  file-extension:
    - rpm
    - srpm
    - src.rpm
    - drpm
  xref:
    pronom: fmt/795 # v3
    wikidata: Q492650
  license: CC0-1.0
  ks-version: 0.9
  endian: be
doc: |
  This parser isr for RPM version 3 which is the current version of RPM. There
  are historical versions of RPM, as well as a currently abandoned fork (rpm5).
  These formats are not covered by this specification.
doc-ref:
  - https://github.com/rpm-software-management/rpm/blob/master/doc/manual/format.md
  - https://github.com/rpm-software-management/rpm/blob/master/doc/manual/tags.md
  - https://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/pkgformat.html
  - http://ftp.rpm.org/max-rpm/
seq:
  - id: lead
    type: lead
  - id: signature
    type: signature
  - id: boundary_padding
    size: (- _io.pos) % 8
  - id: header
    type: header
  #- id: payload
    # size: ??
    # doc: if signature has a SIZE value, then it is:
    # signature[SIZE][0] - sizeof<header>
types:
  dummy: {}
  lead:
    seq:
      - id: magic
        contents: [0xed, 0xab, 0xee, 0xdb]
      - id: version
        type: rpm_version
      - id: type
        type: u2
        enum: rpm_types
      - id: architecture
        -orig-id: archnum
        type: u2
        enum: architectures
      - id: package_name
        type: strz
        encoding: UTF-8
        size: 66
      - id: os
        -orig-id: osnum
        type: u2
        enum: operating_systems
      - id: signature_type
        -orig-id: signature_type
        type: u2
        valid: 5
      - id: reserved
        size: 16
  rpm_version:
    seq:
      - id: major
        type: u1
        valid: 0x3
      - id: minor
        type: u1
  # signature, which is almost identical to header
  # except that some of the tags have a different
  # meaning in signature and header.
  signature:
    seq:
      - id: header_record
        type: header_record
      - id: index_records
        type: signature_index_record
        repeat: expr
        repeat-expr: header_record.index_record_count
      - id: storage_section
        type: dummy
        size: header_record.index_storage_size
  signature_index_record:
    seq:
      - id: tag
        type: u4
        enum: signature_tags
      - id: record_type
        type: u4
        enum: header_types
      - id: record_offset
        type: u4
      - id: count
        type: u4
    instances:
       body:
          io: _parent.storage_section._io
          pos: record_offset
          type:
            switch-on: record_type
            cases:
              header_types::int8: record_type_int8(count)
              header_types::int16: record_type_int16(count)
              header_types::int32: record_type_int32(count)
              header_types::string: record_type_string
              header_types::bin: record_type_bin(count)
              header_types::string_array: record_type_string_array(count)
              header_types::i18nstring: record_type_string_array(count)
  record_type_int8:
    params:
      - id: count
        type: u4
    seq:
      - id: values
        type: u2
        repeat: expr
        repeat-expr: count
  record_type_int16:
    params:
      - id: count
        type: u4
    seq:
      - id: values
        type: u2
        repeat: expr
        repeat-expr: count
  record_type_int32:
    params:
      - id: count
        type: u4
    seq:
      - id: values
        type: u4
        repeat: expr
        repeat-expr: count
  record_type_string:
    seq:
      - id: values
        type: strz
        encoding: UTF-8
        repeat: expr
        repeat-expr: 1
  record_type_bin:
    params:
      - id: count
        type: u4
    seq:
      - id: values
        size: count
        repeat: expr
        repeat-expr: 1
  record_type_string_array:
    params:
      - id: count
        type: u4
    seq:
      - id: values
        type: strz
        encoding: UTF-8
        repeat: expr
        repeat-expr: count
  # header, which is almost identical to signature
  # except that some of the tags have a different
  # meaning in signature and header.
  header:
    seq:
      - id: header_record
        type: header_record
      - id: index_records
        type: header_index_record
        repeat: expr
        repeat-expr: header_record.index_record_count
      - id: storage_section
        type: dummy
        size: header_record.index_storage_size
  header_index_record:
    seq:
      - id: tag
        type: u4
        enum: header_tags
      - id: record_type
        type: u4
        enum: header_types
      - id: record_offset
        type: u4
      - id: count
        type: u4
    instances:
       body:
          io: _parent.storage_section._io
          pos: record_offset
          type:
            switch-on: record_type
            cases:
              header_types::int8: record_type_int8(count)
              header_types::int16: record_type_int16(count)
              header_types::int32: record_type_int32(count)
              header_types::string: record_type_string
              header_types::bin: record_type_bin(count)
              header_types::string_array: record_type_string_array(count)
              header_types::i18nstring: record_type_string_array(count)
  header_record:
    seq:
      - id: magic
        contents: [0x8e, 0xad, 0xe8, 0x01]
      - id: reserved
        contents: [0, 0, 0, 0]
      - id: index_record_count
        -orig-id: nindex
        type: u4
        valid:
          min: 1
      - id: index_storage_size
        -orig-id: hsize
        type: u4
        doc: |
          Size of the storage area for the data
          pointed to by the Index Records.
enums:
  rpm_types:
    0: binary
    1: source
  architectures:
    # these come (mostly) from rpmrc.in
    1: x86
    3: sparc
    4: mips
    5: ppc
    9: ia64
    11: mips64
    12: arm
    14: s390
    15: s390x
    16: ppc64
    17: sh
    18: xtensa
    19: aarch64
    22: riscv
    255: noarch
  operating_systems:
    # these come from rpmrc.in
    # in practice it will almost always be 1
    1: linux
    2: irix
  signature_tags:
    # Tags from LSB.
    # the first three are shared with header_tags
    62: signatures
    63: headerimmutable
    100: i18ntable
    # RPMSIGTAG_*
    267: dsa
    268: rsa
    269: sha1
    270: longsigsize
    273: sha256
    1000: size
    1002: pgp
    1004: md5
    1005: gpg
    1007: payloadsize
    1008: reservedspace
  header_tags:
    # Tags from LSB, some from lib/rpmtag.h
    # RPMTAG_*
    62: signatures
    63: headerimmutable
    100: i18ntable
    1000: name
    1001: version
    1002: release
    1004: summary
    1005: description
    1006: buildtime
    1007: buildhost
    1008: installtime # from lib/rpmtag.h
    1009: size
    1010: distribution
    1011: vendor
    1012: gif # from lib/rpmtag.h
    1013: xpm # from lib/rpmtag.h
    1014: license
    1015: packager
    1016: group
    1018: source # from lib/rpmtag.h
    1019: patch # from lib/rpmtag.h
    1020: url
    1021: os
    1022: arch
    1023: preinstall
    1024: postinstall
    1025: preuninstall
    1026: postuninstall
    1027: oldfilenames
    1028: filesizes
    1029: filestates # from lib/rpmtag.h
    1030: filemodes
    1033: rdevs
    1034: mtimes
    1035: md5s
    1036: linktos
    1037: fileflags
    1039: fileusername
    1040: filegroupname
    1044: sourcerpm
    1045: fileverifyflags
    1046: archivesize
    1047: providename
    1048: requireflags
    1049: requirename
    1050: requirename
    1053: conflictflags
    1054: conflictname
    1055: conflictversion
    1059: excludearch # from lib/rpmtag.h
    1060: excludeos # from lib/rpmtag.h
    1061: exclusivearch # from lib/rpmtag.h
    1062: exclusiveos # from lib/rpmtag.h
    1064: rpmversion
    1065: triggerscripts # from lib/rpmtag.h
    1066: triggername # from lib/rpmtag.h
    1067: triggerversion # from lib/rpmtag.h
    1068: triggerflags # from lib/rpmtag.h
    1069: triggerindex # from lib/rpmtag.h
    1080: changelogtime
    1081: changelogname
    1082: changelogtext
    1085: preinstall_interpreter # /bin/sh
    1086: postinstall_interpreter # /bin/sh
    1087: preuninstall_interpreter # /bin/sh
    1088: postuninstall_interpreter # /bin/sh
    1089: buildarchs # from lib/rpmtag.h
    1090: obsoletename
    1092: triggerscriptprog # from lib/rpmtag.h
    1094: cookie
    1095: filedevices
    1096: fileinodes
    1097: filelangs
    1106: sourcepackage # from lib/rpmtag.h
    1112: provideflags
    1113: provideversion
    1114: obsoleteflags
    1115: obsoleteversion
    1116: dirindexes
    1117: basenames
    1118: dirnames
    1122: optflags
    1123: disturl
    1124: payload_format
    1125: payload_compressor
    1126: payload_flags
    1127: installcolor # from lib/rpmtag.h
    1128: installtid # from lib/rpmtag.h
    1129: removetid # from lib/rpmtag.h
    1131: rhnplatform
    1132: platform
    # below are all from lib/rpmtag.h
    1140: filecolors
    1141: fileclass
    1142: classdict
    1143: filedependsx
    1144: filedependsn
    1145: dependsdict
    1146: sourcepkgid
    1148: fscontexts
    1149: recontexts
    1150: policies
    1151: pretrans
    1152: posttrans
    1153: pretransprog
    1154: posttransprog
    1155: disttag
    1195: dbinstance
    1196: nvra
    5000: filenames
    5001: fileprovide
    5002: filerequire
    5005: triggerconds
    5006: triggertype
    5007: origfilenames
    5008: longfilesizes
    5009: longsize
    5010: filecaps
    5011: filedigestalgo
    5012: bugurl
    5013: evr
    5014: nvr
    5015: nevr
    5016: nevra
    5017: headercolor
    5018: verbose
    5019: epochnum
    5020: preinflags
    5021: postinflags
    5022: preunflags
    5023: postunflags
    5024: pretransflags
    5025: posttransflags
    5026: verifyscriptflags
    5027: triggerscriptflags
    5030: policynames
    5031: policytypes
    5032: policytypesindexes
    5033: policyflags
    5034: vcs
    5035: ordername
    5036: orderversion
    5037: orderflags
    5040: instfilenames
    5041: requirenevrs
    5042: providenevrs
    5043: obsoletenevrs
    5044: conflictnevrs
    5045: filenlinks
    5046: recommendname
    5047: recommendversion
    5048: recommendflags
    5049: suggestname
    5050: suggestversion
    5051: suggestname
    5052: supplementname
    5053: supplementversion
    5054: supplementflags
    5055: enhancename
    5056: enhanceversion
    5057: enhanceflags
    5058: recommendnevrs
    5059: suggestnevrs
    5060: supplementnevrs
    5061: enhancenevrs
    5062: encoding
    5066: filetriggerscripts
    5067: filetriggerscriptprog
    5068: filetriggerscriptflags
    5069: filetriggername
    5070: filetriggerindex
    5071: filetriggerversion
    5072: filetriggerflags
    5076: transfiletriggerscripts
    5077: transfiletriggerscriptprog
    5078: transfiletriggerscriptflags
    5079: transfiletriggername
    5080: transfiletriggerindex
    5081: transfiletriggerversion
    5082: transfiletriggerflags
    5084: filetriggerpriorities
    5085: transfiletriggerpriorities
    5086: filetriggerconds
    5087: filetriggertype
    5088: transfiletriggerconds
    5089: transfiletriggertype
    5090: filesignatures
    5091: filesignaturelength
    5092: payloaddigest
    5093: payloadddigestalgo
    5096: modularitylabel
    5097: payloaddigestalt
  header_types:
    # from LSB
    0: not_implemented
    1: char
    2: int8
    3: int16
    4: int32
    5: int64 # reserved
    6: string # NUL terminated
    7: bin
    8: string_array # NUL terminated strings
    9: i18nstring # NUL terminated strings
