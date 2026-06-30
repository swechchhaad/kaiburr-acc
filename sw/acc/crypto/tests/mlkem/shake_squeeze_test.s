/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * unit test for the 256-byte SHAKE256 squeeze used by poly_getnoise.
 *
 * cbd2 only ever squeezed 128 bytes (one SHAKE256 block; rate = 136). f8 needs
 * 256 bytes, which crosses the rate boundary and forces a mid-squeeze Keccak
 * permutation. This test isolates that squeeze: it sets up SHAKE256 with a
 * known message (32-byte zero seed || 1-byte zero nonce = 33 zero bytes, the
 * standard ML-KEM PRF input) via poly_getnoise_init, then squeezes 256 bytes
 * exactly like poly_getnoise does, and pins all 8 output words.
 *
 * reference: hashlib.shake_256(b'\x00'*33).digest(256), each 32-byte word
 * shown little-endian (load order) as a 256-bit value.
 *
 *   words 0-3 (bytes 0-127)   : first block, must be correct
 *   word  4   (bytes 128-159) : straddles the rate boundary (136)
 *   words 5-7 (bytes 160-255) : second block, after the permutation
 *
 * if words 0-3 pass but 4-7 fail, the multi-block squeeze is the bug. if all 8
 * fail uniformly it is just a byte-order mismatch in this test (flip the .exp).
 */

.section .text.start

.globl main
main:
  la x2, stack_end
  bn.xor w31, w31, w31

  /* set up SHAKE256 over seed(32 zero bytes) || nonce(1 zero byte). */
  la   x10, seed
  la   x13, nonce
  jal  x1, poly_getnoise_init

  /* squeeze 256 bytes exactly as poly_getnoise does (8 x 32-byte words). */
  la   x6, buf
  li   x5, 8                 /* bn.sid index -> w8 */
  LOOPI 8, 2
    bn.wsrr w8, 0xA          /* KECCAK_DIGEST */
    bn.sid  x5, 0(x6++)

  /* load all 8 squeezed words into w0..w7 for checking. */
  la x6, buf
  li x4, 0
  bn.lid x4, 0(x6++)
  li x4, 1
  bn.lid x4, 0(x6++)
  li x4, 2
  bn.lid x4, 0(x6++)
  li x4, 3
  bn.lid x4, 0(x6++)
  li x4, 4
  bn.lid x4, 0(x6++)
  li x4, 5
  bn.lid x4, 0(x6++)
  li x4, 6
  bn.lid x4, 0(x6++)
  li x4, 7
  bn.lid x4, 0(x6++)

  ecall

.data
.balign 32
.global stack
stack:
  .zero 1024
stack_end:

/* 32-byte zero seed (the noise seed). */
.balign 32
seed:
  .zero 32

/* nonce word: low byte is the 1-byte nonce (0), rest ignored. */
.balign 32
nonce:
  .zero 32

/* squeeze destination: 256 bytes. */
.balign 32
buf:
  .zero 256
