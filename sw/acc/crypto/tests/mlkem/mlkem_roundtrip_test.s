/* Copyright zeroRISC Inc. */
/* Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192). */
/* Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors. */
/* Modified by Ruben Niederhagen and Hoang Nguyen Hien Pham - authors of */
/* "Improving ML-KEM & ML-DSA on OpenTitan - Efficient Multiplication Vector Instructions for OTBN" */
/* (https://eprint.iacr.org/2025/2028). */
/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * self-contained roundtrip test for kaiburr8 (k=24, uncompressed ciphertext).
 *
 * runs keypair -> encaps -> decaps in a single elf and checks that the shared
 * secret produced by encapsulation matches the one recovered by decapsulation.
 * this needs no external reference (no kyber-py): it validates the
 * implementation against itself. the "encapsulate then decapsulate yields the
 * same shared secret" property holds for any keypair and any randomness, so we
 * feed fixed all-zero coins.
 *
 * pass/fail follows the acc_sim_test convention: w0 = 0 means the two shared
 * secrets are equal (success); any non-zero w0 means they differ.
 */

.section .text.start

/* must be large enough for the deepest frame used below. crypto_kem_dec needs
 * 34880 bytes and crypto_kem_keypair needs 25216; the frames are used one at a
 * time, so the larger of the two governs. */
#define STACK_SIZE 40960
#define CRYPTO_BYTES 32

#if KYBER_K == 24
  #define CRYPTO_PUBLICKEYBYTES  9248
  #define CRYPTO_SECRETKEYBYTES  18528
  #define CRYPTO_CIPHERTEXTBYTES 9600
#endif

/* entry point. */
.globl main
main:
  /* zero all wide registers when running under the rtl/iss test harness. */
#ifdef RTL_ISS_TEST
  bn.xor  w0, w0, w0
  bn.xor  w1, w1, w1
  bn.xor  w2, w2, w2
  bn.xor  w3, w3, w3
  bn.xor  w4, w4, w4
  bn.xor  w5, w5, w5
  bn.xor  w6, w6, w6
  bn.xor  w7, w7, w7
  bn.xor  w8, w8, w8
  bn.xor  w9, w9, w9
  bn.xor  w10, w10, w10
  bn.xor  w11, w11, w11
  bn.xor  w12, w12, w12
  bn.xor  w13, w13, w13
  bn.xor  w14, w14, w14
  bn.xor  w15, w15, w15
  bn.xor  w16, w16, w16
  bn.xor  w17, w17, w17
  bn.xor  w18, w18, w18
  bn.xor  w19, w19, w19
  bn.xor  w20, w20, w20
  bn.xor  w21, w21, w21
  bn.xor  w22, w22, w22
  bn.xor  w23, w23, w23
  bn.xor  w24, w24, w24
  bn.xor  w25, w25, w25
  bn.xor  w26, w26, w26
  bn.xor  w27, w27, w27
  bn.xor  w28, w28, w28
  bn.xor  w29, w29, w29
  bn.xor  w30, w30, w30
#endif
  bn.xor  w31, w31, w31

  /* step 1: key generation. coins (seed) -> ek (public key), dk (secret key). */
  la   x2, stack_end
  jal  x1, _init_state
  la   x10, coins
  la   x11, ek
  la   x12, dk
  li   x14, KYBER_K
  jal  x1, crypto_kem_keypair

  /* step 2: encapsulation. reads ek and coins, writes ct and ss (= ss_enc).
   * crypto_kem_enc takes its inputs/outputs via the global labels, so we only
   * need to (re)set the parameter k. */
  jal  x1, _init_state
  li   x14, KYBER_K
  jal  x1, crypto_kem_enc

  /* step 3: decapsulation. ct + dk -> ss_dec (= ss recovered from ciphertext). */
  la   x2, stack_end
  jal  x1, _init_state
  la   x10, ct
  la   x11, dk
  la   x12, ss_dec
  li   x14, KYBER_K
  jal  x1, crypto_kem_dec

  /* compare the two 32-byte shared secrets. each fits in one wide register, so
   * xor-ing them gives all-zero exactly when they are equal. leaving that in w0
   * makes w0 = 0 on success. */
  li     x4, 1
  la     x6, ss
  bn.lid x4, 0(x6)        /* w1 = ss_enc (from encapsulation) */
  li     x5, 2
  la     x6, ss_dec
  bn.lid x5, 0(x6)        /* w2 = ss_dec (from decapsulation) */
  bn.xor w0, w1, w2       /* w0 = 0 iff the shared secrets match */

  ecall

/* set the modulus wsr (mod = r | q) and zero w31, the entry state every kem
 * operation expects. clobbers x5, x6, w2, w3, w31. */
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
  .zero STACK_SIZE
stack_end:

/* randomness: serves as the keypair seed (64 bytes) and the encaps coins (first
 * 32 bytes). fixed all-zero is fine for a roundtrip. */
.balign 32
.globl coins
coins:
  .zero 64

/* public key: written by keypair, read by encaps. */
.balign 32
.globl ek
ek:
  .zero CRYPTO_PUBLICKEYBYTES

/* secret key: written by keypair, read by decaps. */
.balign 32
.globl dk
dk:
  .zero CRYPTO_SECRETKEYBYTES

/* ciphertext: written by encaps, read by decaps. */
.balign 32
.globl ct
ct:
  .zero CRYPTO_CIPHERTEXTBYTES

/* shared secret from encapsulation. */
.balign 32
.globl ss
ss:
  .zero CRYPTO_BYTES

/* shared secret recovered by decapsulation. */
.balign 32
.globl ss_dec
ss_dec:
  .zero CRYPTO_BYTES
