/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * integrated test for the REAL poly_getnoise (init -> 256-byte squeeze -> f8),
 * exactly as the KEM calls it. Prior tests checked f8 and the squeeze
 * SEPARATELY; this wires them together with MOD = q set (as f8's bn.subvm
 * needs), for two nonces.
 *
 * reference: f8(shake_256(0^32 || nonce)), with f8's even/odd byte permutation,
 * computed in python. each output word holds 16 coefficients (16-bit lanes).
 *
 * if this passes, the whole noise path is correct in the realistic call and the
 * roundtrip failure is in the KEM glue, not the sampler. if it fails, the bug
 * is in how poly_getnoise wires the squeeze buffer to f8 (or the MOD state).
 */

.section .text.start

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state        /* MOD = r | q (low lane q), w31 = 0 */

  /* poly_getnoise(seed = 0^32, nonce = 0) -> out0 */
  la   x10, seed
  la   x13, nonce0
  jal  x1, poly_getnoise_init
  la   x6, sqbuf
  la   x11, out0
  jal  x1, poly_getnoise

  /* poly_getnoise(seed = 0^32, nonce = 1) -> out1 */
  la   x10, seed
  la   x13, nonce1
  jal  x1, poly_getnoise_init
  la   x6, sqbuf
  la   x11, out1
  jal  x1, poly_getnoise

  /* load representative output words (word w = coeffs 16w..16w+15, offset 32w). */
  la     x6, out0
  li     x4, 10
  bn.lid x4, 0(x6)            /* w10 = out0 word 0  (coeffs 0-15)   */
  la     x6, out0
  addi   x6, x6, 32
  li     x4, 11
  bn.lid x4, 0(x6)            /* w11 = out0 word 1  (coeffs 16-31)  */
  la     x6, out0
  addi   x6, x6, 480
  li     x4, 12
  bn.lid x4, 0(x6)            /* w12 = out0 word 15 (coeffs 240-255)*/
  la     x6, out1
  li     x4, 13
  bn.lid x4, 0(x6)            /* w13 = out1 word 0  (coeffs 0-15)   */

  ecall

/* set MOD = r | q and zero w31 (copied from the roundtrip test). */
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

/* 256-byte squeeze scratch (reused for both polys). */
.balign 32
sqbuf:
  .zero 256

/* 512-byte output polynomials (256 coeffs x 16 bits). */
.balign 32
out0:
  .zero 512
.balign 32
out1:
  .zero 512
