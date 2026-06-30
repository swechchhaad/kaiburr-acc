/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * IND-CPA roundtrip test (no FO wrapper):
 *   indcpa_keypair(seed) -> pk, sk            (uses f8 noise for s, e)
 *   indcpa_enc(msg, pk, coins) -> ct          (uses f8 noise for r, e1, e2)
 *   indcpa_dec(ct, sk) -> msg'
 * check msg' == msg.
 *
 * This isolates the public-key encryption core from the Fujisaki-Okamoto
 * transform. The full KEM roundtrip fails (implicit reject => c' != c); the
 * only way that happens with correct, deterministic noise is a decryption
 * failure (msg' != msg). This test answers that directly:
 *   - passes  => decryption recovers the message; the bug is in the FO layer.
 *   - fails   => CPA decryption itself is broken with f8 noise.
 *
 * msg = 0xAA repeated (32 bytes); on success msg' equals it.
 */

.section .text.start

.globl main
main:
  /* ---- indcpa_keypair(seed=0^32) -> pk, sk ---- */
  la   x2, stack_end
  addi x3, x2, 0              /* fp = stack top (frames grow downward) */
  jal  x1, _init_state
  la   x10, kpseed
  la   x11, pk
  la   x12, sk
  li   x14, KYBER_K
  jal  x1, indcpa_keypair

  /* ---- indcpa_enc(msg, pk, coins=0^32) -> ct ---- */
  la   x2, stack_end
  addi x3, x2, 0
  jal  x1, _init_state
  la   x10, msg
  la   x11, pk
  la   x12, coins
  la   x13, ct
  li   x14, KYBER_K
  jal  x1, indcpa_enc

  /* ---- indcpa_dec(ct, sk) -> mout ---- */
  la   x2, stack_end
  addi x3, x2, 0
  jal  x1, _init_state
  la   x10, ct
  la   x11, sk
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
  .zero 32

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

/* KYBER_INDCPA_PUBLICKEYBYTES = K*384 + 32 = 9248 (K=24). */
.balign 32
pk:
  .zero 9248

/* KYBER_INDCPA_SECRETKEYBYTES = K*384 = 9216 (K=24). */
.balign 32
sk:
  .zero 9216

/* KYBER_INDCPA_BYTES (uncompressed) <= 9600; allocate with margin. */
.balign 32
ct:
  .zero 9728
