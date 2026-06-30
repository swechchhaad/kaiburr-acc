/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * NOISE CAPTURE (diagnostic). poly_getnoise was instrumented (poly.s) to tee
 * every f8 output into the global `dbg_noise`. After a full crypto_kem_keypair,
 * dbg_noise holds the LAST noise polynomial actually produced in the real
 * interleaved flow (keygen's e[K-1], raw f8 output BEFORE the NTT).
 *
 * This is the one thing never observed directly: the noise as it exists in DMEM
 * during the failing run. We dump its first 64 coefficients.
 *
 * VALID f(8) coefficients (MOD = r|q) are exactly {0,1,2,q-2,q-1}, i.e. each
 * 16-bit lane must be one of: 0x0000, 0x0001, 0x0002, 0x0cff, 0x0d00.
 *   - If every lane is in that set  -> the flow noise is correct f(8); the bug
 *     is NOT corruption of the noise (look downstream / at enc).
 *   - If any lane is something else -> the interleaved flow corrupts f8's
 *     output; that corruption is the bug.
 *
 * The .exp deliberately expects zero so the run FAILS and prints the actual
 * captured values for inspection.
 */

.section .text.start

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state
  la   x10, kpseed
  la   x11, ek
  la   x12, dk
  li   x14, KYBER_K
  jal  x1, crypto_kem_keypair

  /* dump dbg_noise (last keygen e poly, raw f8 noise, pre-NTT) */
  la     x6, dbg_noise
  li     x4, 0
  bn.lid x4, 0(x6)            /* w0 = coeffs 0-15  */
  la     x6, dbg_noise
  addi   x6, x6, 32
  li     x4, 1
  bn.lid x4, 0(x6)            /* w1 = coeffs 16-31 */
  la     x6, dbg_noise
  addi   x6, x6, 64
  li     x4, 2
  bn.lid x4, 0(x6)            /* w2 = coeffs 32-47 */
  la     x6, dbg_noise
  addi   x6, x6, 96
  li     x4, 3
  bn.lid x4, 0(x6)            /* w3 = coeffs 48-63 */
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
  .zero 40960
stack_end:

.balign 32
kpseed:
  .zero 64

.balign 32
ek:
  .zero 9248

.balign 32
dk:
  .zero 18528
