# Copyright zeroRISC Inc.
# Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192).
# Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors.
# Modified by Ruben Niederhagen and Hoang Nguyen Hien Pham - authors of
# "Improving ML-KEM & ML-DSA on OpenTitan - Efficient Multiplication Vector Instructions for OTBN"
# (https://eprint.iacr.org/2025/2028).
# Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@ot_python_deps//:requirements.bzl", "requirement")
load("//rules:acc.bzl", "acc_autogen_sim_test", "acc_binary", "acc_consttime_test", "acc_library", "acc_sim_test")

package(default_visibility = ["//visibility:public"])

MODE_FOR_PARAMS = {
    "kaiburr8": 24,
}

NTESTS = 3

STATS = True  # makes tests run slower but logs detailed execution stats

# Key generation tests
py_binary(
    name = "mlkem_keypair_testgen",
    srcs = ["mlkem_keypair_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_keypair_test" + str(i),
        srcs = ["mlkem_keypair_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_keypair_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# Encapsulation tests
py_binary(
    name = "mlkem_encap_testgen",
    srcs = ["mlkem_encap_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_encap_test" + str(i),
        srcs = ["mlkem_encap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_encap_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# Encapsulation tests
py_binary(
    name = "mlkem_decap_testgen",
    srcs = ["mlkem_decap_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_decap_test" + str(i),
        srcs = ["mlkem_decap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_decap_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

[
    acc_autogen_sim_test(
        name = params + "_false_decap_test" + str(i),
        srcs = ["mlkem_decap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_decap_testgen",
        testgen_args = [
            "-i",
            params,
        ],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# checks that the encapsulation and decapsulation shared secrets match
[
    acc_sim_test(
        name = params + "_roundtrip_test",
        srcs = ["mlkem_roundtrip_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        exp = "mlkem_roundtrip_test.exp",
        pqc = True,
        # raising the timeout
        stats = False,
        timeout = "eternal",
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for params in MODE_FOR_PARAMS
]

# Unit test for the f8 noise sampler in isolation (no full KEM, no kyber-py).
# Feeds known input bytes to f8 and checks the resulting coefficients.
acc_sim_test(
    name = "f8_test",
    srcs = ["f8_test.s"],
    exp = "f8_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
    ],
)

# NOISE CAPTURE (diagnostic): tees poly_getnoise output to dbg_noise during a
# real keygen, then dumps it. Forced-fail .exp prints the actual flow noise.
acc_sim_test(
    name = "noise_capture_test",
    srcs = ["noise_capture_test.s"],
    copts = ["-DKYBER_K=24"],
    exp = "noise_capture_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:basemul",
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
        "//sw/acc/crypto/mlkem:decap",
        "//sw/acc/crypto/mlkem:indcpa_enc",
        "//sw/acc/crypto/mlkem:intt",
        "//sw/acc/crypto/mlkem:keypair",
        "//sw/acc/crypto/mlkem:kmac_send_msg",
        "//sw/acc/crypto/mlkem:ntt",
        "//sw/acc/crypto/mlkem:pack_ciphertext",
        "//sw/acc/crypto/mlkem:pack_keys",
        "//sw/acc/crypto/mlkem:poly",
        "//sw/acc/crypto/mlkem:poly_gen_matrix",
    ],
)

# SHAKE256 256-byte squeeze AFTER a SHA3-512 op (mode switch) -- tests whether
# the second SHAKE256 block (which f8 reads, cbd2 doesn't) is corrupted.
acc_sim_test(
    name = "shake_after_sha3_test",
    srcs = ["shake_after_sha3_test.s"],
    exp = "shake_after_sha3_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
        "//sw/acc/crypto/mlkem:kmac_send_msg",
        "//sw/acc/crypto/mlkem:poly",
    ],
)

# poly_getnoise (f8) called from inside a hardware LOOP, like keygen/encap.
acc_sim_test(
    name = "poly_getnoise_loop_test",
    srcs = ["poly_getnoise_loop_test.s"],
    exp = "poly_getnoise_loop_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
        "//sw/acc/crypto/mlkem:poly",
    ],
)

# f8 under MOD = 2r|2q (the encap epp condition the MOD=q tests never covered).
acc_sim_test(
    name = "f8_mod2q_test",
    srcs = ["f8_mod2q_test.s"],
    exp = "f8_mod2q_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
    ],
)

# Isolates the 256-byte SHAKE256 squeeze that f8 requires (crosses the 136-byte
# rate boundary). Checks the raw squeezed bytes against a hashlib reference.
acc_sim_test(
    name = "shake_squeeze_test",
    srcs = ["shake_squeeze_test.s"],
    exp = "shake_squeeze_test.exp",
    pqc = True,
    stats = False,
    deps = [
        # poly.s provides poly_getnoise_init; it references f8 (in :cbd).
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:poly",
    ],
)

# Two 256-byte squeezes back-to-back: catches KMAC state leaking across
# operations (which a single isolated squeeze cannot reveal).
acc_sim_test(
    name = "shake_resqueeze_test",
    srcs = ["shake_resqueeze_test.s"],
    exp = "shake_resqueeze_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:poly",
    ],
)

# The REAL poly_getnoise (init -> squeeze -> f8) wired together, as the KEM
# calls it, with MOD set. The integration prior tests never exercised.
acc_sim_test(
    name = "poly_getnoise_test",
    srcs = ["poly_getnoise_test.s"],
    exp = "poly_getnoise_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
        "//sw/acc/crypto/mlkem:poly",
    ],
)

# IND-CPA roundtrip (keypair -> encrypt -> decrypt), bypassing the FO wrapper.
# Answers whether decryption recovers the message with f8 noise.
acc_sim_test(
    name = "indcpa_roundtrip_test",
    srcs = ["indcpa_roundtrip_test.s"],
    copts = ["-DKYBER_K=24"],
    exp = "indcpa_roundtrip_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:basemul",
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
        "//sw/acc/crypto/mlkem:decap",
        "//sw/acc/crypto/mlkem:indcpa_enc",
        "//sw/acc/crypto/mlkem:intt",
        "//sw/acc/crypto/mlkem:keypair",
        "//sw/acc/crypto/mlkem:kmac_send_msg",
        "//sw/acc/crypto/mlkem:ntt",
        "//sw/acc/crypto/mlkem:pack_ciphertext",
        "//sw/acc/crypto/mlkem:pack_keys",
        "//sw/acc/crypto/mlkem:poly",
        "//sw/acc/crypto/mlkem:poly_gen_matrix",
    ],
)
