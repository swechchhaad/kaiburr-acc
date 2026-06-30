/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * f8 under MOD = 2r|2q (the modulus state encap's epp sampling runs in).
 *
 * The earlier f8 unit test ran with MOD = r|q. The full encap path samples some
 * noise polynomials with MOD = 2r|2q (set up for the NTT and not restored before
 * the CBD). f8's one modulus-dependent instruction is `bn.subvm w7, w31, w8`
 * (neg = (0 - mag) mod MOD). Under MOD = 2q the negative coefficients should
 * come out as 2q - mag (congruent to -mag mod q), i.e. 0x1A01 and 0x1A00.
 *
 * If f8 produces those, it is correct under 2q (and the bug is elsewhere); if it
 * produces anything else, f8 is wrong under 2q -- which would finally explain
 * why encap (but not keygen, which uses MOD=q) breaks.
 *   in 0x00 -> +1      = 0x0001            (positive, modulus-independent)
 *   in 0x80 -> -1      = 2q-1 = 0x1A01
 *   in 0xff -> -2      = 2q-2 = 0x1A00
 */

.section .text.start

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state        /* MOD = r | q, w31 = 0 */

  /* raise MOD to 2r | 2q, exactly as the KEM does before the NTT. */
  bn.wsrr   w16, 0x0
  bn.shv.8S w0, w16 << 1
  bn.wsrw   0x0, w0

  la x10, in_00 ; la x11, out_00 ; jal x1, f8
  la x10, in_80 ; la x11, out_80 ; jal x1, f8
  la x10, in_ff ; la x11, out_ff ; jal x1, f8

  li     x4, 1
  la     x6, out_00
  bn.lid x4, 0(x6)            /* w1 = +1 x16          */
  li     x4, 2
  la     x6, out_80
  bn.lid x4, 0(x6)            /* w2 = (2q-1) x16 ?    */
  li     x4, 3
  la     x6, out_ff
  bn.lid x4, 0(x6)            /* w3 = (2q-2) x16 ?    */

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
in_00:
  .zero 256
.balign 32
in_80:
.rept 64
  .word 0x80808080
.endr
.balign 32
in_ff:
.rept 64
  .word 0xffffffff
.endr

.balign 32
out_00:
  .zero 512
.balign 32
out_80:
  .zero 512
.balign 32
out_ff:
  .zero 512
