/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * SHAKE256 256-byte squeeze AFTER a different-mode Keccak op (SHA3-512).
 *
 * This replicates the real keygen prologue: hash_g (SHA3-512) runs, then the
 * skpv noise is sampled with SHAKE256. Every prior squeeze test ran SHAKE256 on
 * a clean core, or SHAKE256 after SHAKE256 (shake_resqueeze) -- never after a
 * mode switch. f8 reads all 256 squeezed bytes (into the SHAKE256 SECOND block,
 * bytes 136+); cbd2 reads only the first 128 (first block). So if a mode switch
 * corrupts the second block, f8 gets bad noise and cbd2 does not -- exactly the
 * observed pattern.
 *
 * Reference: shake_256(0^33), same as shake_squeeze_test.
 *   w0 = word 0   (bytes 0-31,    first block -- should always be right)
 *   w4 = word 4   (bytes 128-159, STRADDLES the 136-byte rate boundary)
 *   w5 = word 5   (bytes 160-191, SECOND block)
 *   w7 = word 7   (bytes 224-255, SECOND block)
 * If w0 matches but w4/w5/w7 do not, the mode switch corrupts the 2nd block.
 */

.section .text.start

#define KECCAK_CFG_REG 0x7d9
#define SHA3_512_CFG   0x10

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state

  /* ---- prior op: SHA3-512 over 32 bytes (a stand-in for hash_g) ----
     a0=x10 (msg ptr), a1=x11 (len), t0=x5 (temp) -- numeric names only. */
  addi  x11, x0, 32
  slli  x5, x11, 5
  addi  x5, x5, SHA3_512_CFG
  csrrw x0, KECCAK_CFG_REG, x5
  la    x10, msg32
  addi  x11, x0, 32
  jal   x1, keccak_send_message
  /* read the 64-byte SHA3-512 digest, like hash_g does */
  la    x12, hbuf
  li    x5, 8
  LOOPI 2, 2
    bn.wsrr w8, 0xA
    bn.sid  x5, 0(x12++)

  /* ---- now SHAKE256(seed=0^32 || nonce=0) and squeeze 256 bytes ---- */
  la   x10, seed
  la   x13, nonce
  jal  x1, poly_getnoise_init
  la   x6, buf
  li   x5, 8
  LOOPI 8, 2
    bn.wsrr w8, 0xA
    bn.sid  x5, 0(x6++)

  /* load word 0 (block 1) and words 4,5,7 (block 2) */
  la     x6, buf
  li     x4, 0
  bn.lid x4, 0(x6)            /* w0 = bytes 0-31 */
  la     x6, buf
  addi   x6, x6, 128
  li     x4, 4
  bn.lid x4, 0(x6)            /* w4 = bytes 128-159 */
  la     x6, buf
  addi   x6, x6, 160
  li     x4, 5
  bn.lid x4, 0(x6)            /* w5 = bytes 160-191 */
  la     x6, buf
  addi   x6, x6, 224
  li     x4, 7
  bn.lid x4, 0(x6)            /* w7 = bytes 224-255 */

  ecall

_init_state:
  bn.xor  w31, w31, w31
  li      x5, 2
  la      x6, modulus
  bn.lid  x5++, 0(x6)
  la      x6, modulus_inv
  bn.lid  x5, 0(x6)
  bn.or   w2, w2, w3 << 32
  bn.wsrw 0x0, w2
  ret

.data
.balign 32
.global stack
stack:
  .zero 1024
stack_end:

.balign 32
msg32:
  .zero 32
.balign 32
seed:
  .zero 32
.balign 32
nonce:
  .zero 32
.balign 32
hbuf:
  .zero 64
.balign 32
buf:
  .zero 256
