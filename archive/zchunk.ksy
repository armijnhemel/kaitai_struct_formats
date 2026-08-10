meta:
  id: zchunk
  title: Zchunk
  file-extension:
    - zck # magic '\0ZCK1' (`lead.is_detached_header` is `false`)
    - zhr # magic '\0ZHR1' (`lead.is_detached_header` is `true`)
  xref:
    justsolve: Zchunk
  license: CC0-1.0
  ks-version: '0.10'
  endian: le
doc-ref: https://github.com/zchunk/zchunk/blob/99e51afa38c723e7c25834c2c3b305d20ef55d04/zchunk_format.txt
seq:
  - id: lead
    type: header_lead
  - id: header_rest
    size: lead.len_header_rest.value
    type: header_without_lead
  - id: dict
    size: header_rest.index.len_dict.value
    doc: |
      Custom dictionary used when compressing each chunk. It's compressed itself
      without a dictionary.

      The official zchunk specification calls this section "Compressed Dict".
      It's also called a "dictionary chunk". `zck_read_header -c` presents it as
      "chunk 0" (which is always shown in the chunk table, but can have size 0
      if the dictionary is not in use).
  - id: chunks
    size: chunk_metadata[_index].len_chunk.value
    repeat: expr
    repeat-expr: num_chunks
    if: not lead.is_detached_header
    doc: |
      Chunks of data, each compressed with the custom dictionary `dict` (if
      applicable).

      They are not included in a detached header (`.zhr`) file. Detached headers
      contain the dictionary, but none of the data chunks.
instances:
  num_chunks:
    value: header_rest.index.num_chunks.value - 1
    doc: the number of chunks includes the header, so -1
  chunk_metadata:
    value: header_rest.index.chunks_metadata
types:
  header_lead:
    seq:
      - id: magic
        size: 5
        valid:
          any-of:
            - '[0x00, 0x5a, 0x43, 0x4b, 0x31]' # '\0ZCK1'
            - '[0x00, 0x5a, 0x48, 0x52, 0x31]' # '\0ZHR1'
        doc: |
          There are two valid magic numbers for zchunk files:

          * `'\0ZCK1'` identifies a zchunk version 1 file (`.zck`)
          * `'\0ZHR1'` identifies a zchunk version 1 detached header file (`.zhr`)
      - id: overall_checksum_type
        type: checksum_type
        doc: |
          Type of the checksum used for `header_checksum` and
          `_root.header_rest.preface.data_checksum`.
      - id: len_header_rest
        type: compressed_integer
        doc: Size of the header, not including the lead
      - id: header_checksum
        size: overall_checksum_type.len_checksum
        doc: |
          Checksum of the entire header, which consists of `_root.lead` and
          `_root.header_rest` (i.e. everything from the beginning of the file to
          the end of `_root.header_rest`), not including the `header_checksum`
          field itself (i.e. the input for the checksum algorithm is a
          concatenation of the bytes preceding the `header_checksum` field with
          the bytes following it).

          For detached headers, the checksum is calculated as if the `magic`
          field were set to `'\0ZCK1'`, so that it matches the checksum in the
          full zchunk file.
    instances:
      is_detached_header:
        value: magic[2] == 0x48
        doc: |
          Determines whether this file is a zchunk detached header (`.zhr`). If
          not, it is a complete zchunk file (`.zck`).
  header_without_lead:
    seq:
      - id: preface
        type: preface
      - id: len_index
        type: compressed_integer
      - id: index
        size: len_index.value
        type: index
      - id: num_signatures
        type: compressed_integer
        valid:
          expr: _.value == 0
        doc: |
          Must be 0. The reference implementation also rejects any file with a
          non-zero "Signature count", throwing a fatal error stating "Signatures
          aren't supported yet" - see
          [`src/lib/header.c:259-264`](https://github.com/zchunk/zchunk/blob/99e51afa38c723e7c25834c2c3b305d20ef55d04/src/lib/header.c#L259-L264).

          Although the structure of signatures is defined [in the official
          textual
          specification](https://github.com/zchunk/zchunk/blob/99e51afa38c723e7c25834c2c3b305d20ef55d04/zchunk_format.txt#L219-L252),
          no signature types are defined, and as of this writing no publicly
          known implementation generates or interprets these signatures.
          Therefore, we've decided not to implement them here either.

          For more details, see
          <https://github.com/kaitai-io/kaitai_struct_formats/pull/539#discussion_r3713109887>.
  preface:
    seq:
      - id: data_checksum
        size: _root.lead.overall_checksum_type.len_checksum
        doc: |
          Total data checksum. Checksum of everything after the header,
          including the compressed dictionary (`_root.dict`) and all compressed
          chunks (`_root.chunks`). The type of this checksum is
          `_root.lead.overall_checksum_type.value`.

          If `has_uncompressed_source` is true, this checksum must not be
          checked and should not be generated. In that case, the reference
          implementation writes it as all zeros - see the sample file
          [`mini-uncomp-cksums.zck`](https://github.com/kaitai-io/kaitai_struct_samples/blob/1d2fe11c971fb7e86f343b77a1ed341a0217e86a/archive/zchunk/README.md#mini-uncomp-cksumszck).
      - id: flags
        type: compressed_integer
      - id: compression_type
        type: compressed_integer
      - id: num_optional_elements
        type: compressed_integer
        if: has_optional_elements
      - id: optional_elements
        type: optional_element
        repeat: expr
        repeat-expr: num_optional_elements.value
        if: has_optional_elements
    instances:
      has_data_streams:
        value: flags.value & 0b1 == 0b1
      has_optional_elements:
        value: flags.value & 0b10 == 0b10
      has_uncompressed_source:
        value: flags.value & 0b100 == 0b100
        doc: |
          The file may be applied against an uncompressed source. This adds an
          uncompressed checksum to every index entry, including the dictionary.
      compression:
        value: compression_type.value
        enum: compression
  optional_element:
    -webide-representation: 'ID {element_id.value:dec}'
    seq:
      - id: element_id
        type: compressed_integer
      - id: len_data
        type: compressed_integer
      - id: data
        size: len_data.value
  index:
    seq:
      - id: chunk_checksum_type
        type: checksum_type
        doc: |
          Type of the checksum used for `dict_checksum` and for all
          `chunks_metadata[...].chunk_checksum` and
          `chunks_metadata[...].uncompressed_chunk_checksum`.
      - id: num_chunks
        type: compressed_integer
      - id: dict_stream
        type: compressed_integer
        if: _parent.preface.has_data_streams
      - id: dict_checksum
        size: chunk_checksum_type.len_checksum
      - id: uncompressed_dict_checksum
        size: chunk_checksum_type.len_checksum
        if: _parent.preface.has_uncompressed_source
        doc: |
          Checksum of the uncompressed dictionary. It has no real use, as the
          uncompressed source won't have a dictionary.
      - id: len_dict
        type: compressed_integer
      - id: len_uncompressed_dict
        type: compressed_integer
      - id: chunks_metadata
        type: |
          chunk(
            chunk_checksum_type.len_checksum,
            _parent.preface.has_data_streams,
            _parent.preface.has_uncompressed_source
          )
        repeat: expr
        repeat-expr: num_chunks.value - 1
        doc: the number of chunks includes the header, so -1
  chunk:
    params:
      - id: len_checksum
        type: u4
      - id: has_data_streams
        type: bool
      - id: has_uncompressed_source
        type: bool
    seq:
      - id: chunk_stream
        type: compressed_integer
        if: has_data_streams
      - id: chunk_checksum
        size: len_checksum
      - id: uncompressed_chunk_checksum
        size: len_checksum
        if: has_uncompressed_source
        doc: |
          Checksum of the uncompressed chunk. Used to detect whether a chunk
          from an uncompressed source is identical to the compressed chunk.
      - id: len_chunk
        type: compressed_integer
      - id: len_uncompressed_chunk
        type: compressed_integer
  # Common types
  checksum_type:
    -webide-representation: '{value}'
    seq:
      - id: raw
        type: compressed_integer
        doc: |
          Raw integer, don't read this field - access `value` instead.
    instances:
      value:
        value: raw.value
        enum: checksum_types
      len_checksum:
        value: |
          value == checksum_types::sha1 ? 20 :
          value == checksum_types::sha256 ? 32 :
          value == checksum_types::sha512 ? 64 :
          value == checksum_types::sha512_128 ? 16 :
          0
  compressed_integer:
    doc: |
      Like `/common/vlq_base128_le` (LEB128), but the logic of the
      "continuation" flag in the most significant bit is inverted, so `has_next`
      is implemented the opposite way (if the highest bit is set to zero, it
      means "continue", whereas in standard LEB128, the highest bit set to
      **one** means "continue"). Therefore, we cannot simply import
      `/common/vlq_base128_le` and use it, because it is incompatible.
    -webide-representation: '{value:hex} = {value:dec}'
    seq:
      - id: groups
        type: group
        repeat: until
        repeat-until: not _.has_next
    types:
      group:
        doc: |
          One byte group, clearly divided into 7-bit "value" chunk and 1-bit "continuation" flag.
        -webide-representation: '{value}'
        seq:
          - id: b
            type: u1
        instances:
          has_next:
            value: (b & 0b1000_0000) == 0
            doc: If true, then we have more bytes to read
          value:
            value: b & 0b0111_1111
            doc: The 7-bit (base128) numeric value chunk of this group
    instances:
      len:
        value: groups.size
      value:
        value: >-
          groups[0].value
          + (len >= 2 ? (groups[1].value << 7) : 0)
          + (len >= 3 ? (groups[2].value << 14) : 0)
          + (len >= 4 ? (groups[3].value << 21) : 0)
          + (len >= 5 ? (groups[4].value << 28) : 0)
          + (len >= 6 ? (groups[5].value << 35) : 0)
          + (len >= 7 ? (groups[6].value << 42) : 0)
          + (len >= 8 ? (groups[7].value << 49) : 0)
        doc: Resulting unsigned value as normal integer
enums:
  checksum_types:
    0: sha1
    1: sha256
    2: sha512
    3: sha512_128 # first 128 bits of sha512 checksum
  compression:
    0: none
    2: zstd
