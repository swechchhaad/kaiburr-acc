/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * unit test for the f8 noise sampler (cbd.s).
 *
 * runs f8 directly on known 256-byte input buffers and checks the resulting
 * coefficients, isolating the sampler from the rest of the kem. f8 maps each
 * input byte c (bits b0..b7) to:
 *     mag  = (1 - b0) + 2*[b0..b6 all ones]   in {0,1,2}
 *     sign = b7 ? negate : keep              (symmetric, so f(8) up to sign)
 *     coeff = sign(mag) reduced into [0,q),  q = 3329.
 *
 * value map used below (one coeff per 16-bit lane):
 *     0x00 -> +1 = 0x0001       0x80 -> -1 = q-1 = 0x0d00
 *     0x7f -> +2 = 0x0002       0xff -> -2 = q-2 = 0x0cff
 *     0x01 ->  0 = 0x0000
 *
 * for a uniform input byte every lane is identical, so the checks are
 * independent of f8's internal even/odd byte permutation. the final "mixed"
 * vector (lane = 0xff00: even byte 0x00, odd byte 0xff) additionally checks
 * that the even/odd split works and that adjacent lanes do not bleed.
 *
 * pass/fail follows the acc_sim_test convention: the .exp file pins w1..w7.
 */

.section .text.start

.globl main
main:
  bn.xor w31, w31, w31        /* w31 = 0 (f8 precondition) */
  la   x2, stack_end
  jal  x1, _init_state        /* MOD = r | q (low lane = q, for bn.subvm) */

  /* run f8 on each input buffer (x10 = input, x11 = output). */
  la  x10, in_00
  la  x11, out_00
  jal x1, f8
  la  x10, in_80
  la  x11, out_80
  jal x1, f8
  la  x10, in_7f
  la  x11, out_7f
  jal x1, f8
  la  x10, in_ff
  la  x11, out_ff
  jal x1, f8
  la  x10, in_01
  la  x11, out_01
  jal x1, f8
  la  x10, in_mixed
  la  x11, out_mixed
  jal x1, f8

  /* load one representative output register from each result for checking.
     uniform inputs -> every lane equal, so out[0] characterises the buffer. */
  li     x4, 1
  la     x6, out_00
  bn.lid x4, 0(x6)            /* w1 = +1 x16 */
  li     x4, 2
  la     x6, out_80
  bn.lid x4, 0(x6)            /* w2 = -1 x16 */
  li     x4, 3
  la     x6, out_7f
  bn.lid x4, 0(x6)            /* w3 = +2 x16 */
  li     x4, 4
  la     x6, out_ff
  bn.lid x4, 0(x6)            /* w4 = -2 x16 */
  li     x4, 5
  la     x6, out_01
  bn.lid x4, 0(x6)            /* w5 =  0 x16 */

  /* mixed: out[0] = even bytes (0x00 -> +1), out[1] = odd bytes (0xff -> -2). */
  li     x4, 6
  la     x6, out_mixed
  bn.lid x4, 0(x6)            /* w6 = +1 x16 (even path) */
  li     x4, 7
  la     x6, out_mixed
  addi   x6, x6, 32
  bn.lid x4, 0(x6)            /* w7 = -2 x16 (odd path) */

  ecall

/* set the modulus wsr (mod = r | q) and zero w31, the state f8 expects.
 * clobbers x5, x6, w2, w3, w31. (copied from the roundtrip test.) */
_init_state:
  bn.xor  w31, w31, w31
  li      x5, 2
  la      x6, modulus
  bn.lid  x5++, 0(x6)
  la      x6, modulus_inv
  bn.lid  x5, 0(x6)
  bn.or   w2, w2, w3 << 32 /* mod = r | q */
  bn.wsrw 0x0, w2
  ret

.data
.balign 32
.global stack
stack:
  .zero 1024
stack_end:

/* ---- input buffers: 256 bytes each (f8 reads 8 wide regs) ---- */

.balign 32
in_00:
  .zero 256

.balign 32
in_80:
.rept 64
  .word 0x80808080
.endr

.balign 32
in_7f:
.rept 64
  .word 0x7f7f7f7f
.endr

.balign 32
in_ff:
.rept 64
  .word 0xffffffff
.endr

.balign 32
in_01:
.rept 64
  .word 0x01010101
.endr

/* each 16-bit lane = 0xff00 -> even byte 0x00, odd byte 0xff */
.balign 32
in_mixed:
.rept 64
  .word 0xff00ff00
.endr

/* ---- output buffers: 512 bytes each (256 coeffs x 16 bits) ---- */
.balign 32
out_00:
  .zero 512
.balign 32
out_80:
  .zero 512
.balign 32
out_7f:
  .zero 512
.balign 32
out_ff:
  .zero 512
.balign 32
out_01:
  .zero 512
.balign 32
out_mixed:
  .zero 512
