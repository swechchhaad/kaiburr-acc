/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * DECRYPTION-ERROR CAPTURE (diagnostic).
 *
 * Runs the full IND-CPA roundtrip with f8 noise:
 *   crypto_kem_keypair -> ek, dk
 *   indcpa_enc(msg=0xAA, ek) -> ct
 *   indcpa_dec(ct, dk) -> mout
 *
 * indcpa_dec is instrumented (mlkem_decap.s) to tee the PRE-THRESHOLD message
 * polynomial  mp = v - s^T u  into the global `dbg_mp` before poly_tomsg runs.
 * We also keep the noise tee, so dbg_noise holds the last f8 noise poly.
 *
 * Interpreting mp (MOD = r|q, q = 3329, q/2 ~ 1664):
 *   msg = 0xAA -> message bits alternate, so a CORRECT mp has coefficients
 *   tightly clustered at two values: ~0x0000 (bit 0) and ~0x0680 (1664, bit 1),
 *   each +/- a small error (< q/4 = 832 = 0x340). Lanes near 0 or near 0x0680
 *   => decryption math is fine (bug is in message decode).
 *   Lanes scattered across the whole range [0, q) => the secret/ciphertext
 *   reaching decrypt is structurally wrong (the real bug).
 *
 * w0..w3 = mp coeffs 0..63 ; w4 = dbg_noise word 0 (sanity: noise still f(8)).
 * .exp forces zero so the run FAILS and prints the actual captured values.
 */

.section .text.start

.globl main
main:
  /* ---- crypto_kem_keypair(seed = 0^64) -> ek, dk ---- */
  la   x2, stack_end
  jal  x1, _init_state
  la   x10, kpseed
  la   x11, ek
  la   x12, dk
  li   x14, KYBER_K
  jal  x1, crypto_kem_keypair

  /* ---- indcpa_enc(msg = 0xAA, ek, coins = 0^32) -> ct ---- */
  la   x2, stack_end
  addi x3, x2, 0
  jal  x1, _init_state
  la   x10, msg
  la   x11, ek
  la   x12, coins
  la   x13, ct
  li   x14, KYBER_K
  jal  x1, indcpa_enc

  /* ---- indcpa_dec(ct, dk) -> mout (tees mp to dbg_mp) ---- */
  la   x2, stack_end
  addi x3, x2, 0
  jal  x1, _init_state
  la   x10, ct
  la   x11, dk
  la   x13, mout
  li   x14, KYBER_K
  jal  x1, indcpa_dec

  /* dump the decryption error poly mp (coeffs 0..63) */
  la     x6, dbg_mp
  li     x4, 0
  bn.lid x4, 0(x6)            /* w0 = mp coeffs 0-15  */
  la     x6, dbg_mp
  addi   x6, x6, 32
  li     x4, 1
  bn.lid x4, 0(x6)            /* w1 = mp coeffs 16-31 */
  la     x6, dbg_mp
  addi   x6, x6, 64
  li     x4, 2
  bn.lid x4, 0(x6)            /* w2 = mp coeffs 32-47 */
  la     x6, dbg_mp
  addi   x6, x6, 96
  li     x4, 3
  bn.lid x4, 0(x6)            /* w3 = mp coeffs 48-63 */
  la     x6, dbg_noise
  li     x4, 4
  bn.lid x4, 0(x6)            /* w4 = last noise poly word 0 (sanity) */
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
coins:
  .zero 32

.balign 32
msg:
.rept 8
  .word 0xaaaaaaaa
.endr

.balign 32
mout:
  .zero 32

.balign 32
ek:
  .zero 9248

.balign 32
dk:
  .zero 18528

.balign 32
ct:
  .zero 9728
