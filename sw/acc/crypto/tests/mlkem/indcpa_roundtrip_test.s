/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * IND-CPA roundtrip test (no FO wrapper):
 *   crypto_kem_keypair(seed) -> ek, dk        (uses f8 noise for s, e)
 *   indcpa_enc(msg, ek, coins) -> ct          (uses f8 noise for r, e1, e2)
 *   indcpa_dec(ct, dk) -> msg'
 * check msg' == msg.

.section .text.start

.globl main
main:
  /* ---- crypto_kem_keypair(seed = 0^64) -> ek, dk (sets up its own fp) ---- */
  la   x2, stack_end
  jal  x1, _init_state
  la   x10, kpseed
  la   x11, ek
  la   x12, dk
  li   x14, KYBER_K
  jal  x1, crypto_kem_keypair

  /* ---- indcpa_enc(msg, ek, coins = 0^32) -> ct ---- */
  la   x2, stack_end
  addi x3, x2, 0              /* fp = stack top */
  jal  x1, _init_state
  la   x10, msg
  la   x11, ek                /* ek = IND-CPA pk */
  la   x12, coins
  la   x13, ct
  li   x14, KYBER_K
  jal  x1, indcpa_enc

  /* ---- indcpa_dec(ct, dk) -> mout (dk starts with the IND-CPA sk) ---- */
  la   x2, stack_end
  addi x3, x2, 0
  jal  x1, _init_state
  la   x10, ct
  la   x11, dk
  la   x13, mout
  li   x14, KYBER_K
  jal  x1, indcpa_dec

  /* load decrypted message for checking (32 bytes -> one wide reg). */
  la     x6, mout
  li     x4, 0
  bn.lid x4, 0(x6)
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
  .zero 40960
stack_end:

.balign 32
kpseed:
  .zero 64

.balign 32
coins:
  .zero 32

/* message = 0xAA in every byte. */
.balign 32
msg:
.rept 8
  .word 0xaaaaaaaa
.endr

.balign 32
mout:
  .zero 32

/* KYBER_PUBLICKEYBYTES = K*384 + 32 = 9248 (K=24); ek == IND-CPA pk. */
.balign 32
ek:
  .zero 9248

/* KYBER_SECRETKEYBYTES = 2*K*384 + 96 = 18528 (K=24); starts with IND-CPA sk. */
.balign 32
dk:
  .zero 18528

/* KYBER_INDCPA_BYTES (uncompressed) <= 9600; allocate with margin. */
.balign 32
ct:
  .zero 9728
