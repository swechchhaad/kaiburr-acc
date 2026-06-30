/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * sequential 256-byte SHAKE256 squeeze test.
 *
 * The single-squeeze test passes, so a 256-byte squeeze is correct in
 * isolation. But the real KEM runs many poly_getnoise calls back-to-back, and
 * a 256-byte (two-block) squeeze leaves the Keccak core mid-stream in a way
 * cbd2's 128-byte (single-block) squeeze never did. This test checks whether a
 * second init+squeeze is corrupted by the first one's leftover state:
 *
 *   squeeze 1: SHAKE256(0^32 || nonce=0), 256 bytes -> buf1
 *   squeeze 2: SHAKE256(0^32 || nonce=1), 256 bytes -> buf2   (after squeeze 1)
 *
 * If buf2 diverges from its reference while buf1 matches, the bug is KMAC state
 * leaking across operations -- which would make noise inconsistent between
 * keygen/encap/decap and break the roundtrip exactly as observed.
 */

.section .text.start

.globl main
main:
  la x2, stack_end
  bn.xor w31, w31, w31

  /* ---- squeeze 1: nonce = 0 -> buf1 ---- */
  la   x10, seed
  la   x13, nonce0
  jal  x1, poly_getnoise_init
  la   x6, buf1
  li   x5, 8
  LOOPI 8, 2
    bn.wsrr w8, 0xA
    bn.sid  x5, 0(x6++)

  /* ---- squeeze 2: nonce = 1 -> buf2 (re-init after a two-block squeeze) ---- */
  la   x10, seed
  la   x13, nonce1
  jal  x1, poly_getnoise_init
  la   x6, buf2
  li   x5, 8
  LOOPI 8, 2
    bn.wsrr w8, 0xA
    bn.sid  x5, 0(x6++)

  /* ---- load words for checking ---- */
  /* buf1 (nonce 0): sanity, first and last word */
  la     x6, buf1
  li     x4, 10
  bn.lid x4, 0(x6)            /* w10 = buf1 word 0 */
  la     x6, buf1
  addi   x6, x6, 224
  li     x4, 11
  bn.lid x4, 0(x6)            /* w11 = buf1 word 7 */

  /* buf2 (nonce 1): the one that would be corrupted by leftover state */
  la     x6, buf2
  li     x4, 12
  bn.lid x4, 0(x6)            /* w12 = buf2 word 0 */
  la     x6, buf2
  addi   x6, x6, 128
  li     x4, 13
  bn.lid x4, 0(x6)            /* w13 = buf2 word 4 (post-rate) */
  la     x6, buf2
  addi   x6, x6, 224
  li     x4, 14
  bn.lid x4, 0(x6)            /* w14 = buf2 word 7 */

  ecall

.data
.balign 32
.global stack
stack:
  .zero 1024
stack_end:

.balign 32
seed:
  .zero 32

.balign 32
nonce0:
  .zero 32

.balign 32
nonce1:
  .word 0x00000001
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000

.balign 32
buf1:
  .zero 256
.balign 32
buf2:
  .zero 256
