"""kyber-py adapted for kaiburr"""
from hashlib import shake_256
from kyber_py.ml_kem.ml_kem import ML_KEM

KAIBURR_PARAMS = {
    # eta_1/eta_2 are unused
    "kaiburr8": {"k": 24, "eta_1": 2, "eta_2": 2, "du": 12, "dv": 12},
    "kaiburr6": {"k": 18, "eta_1": 2, "eta_2": 2, "du": 12, "dv": 12},
    "kaiburr4": {"k": 7, "eta_1": 2, "eta_2": 2, "du": 12, "dv": 12},
}


class KaiburrKEM(ML_KEM):
    # noise sampler
    def _squeeze_len(self):
        return {7: 128, 18: 192, 24: 256}[self.k]    # bytes consumed per poly

    def _sample_noise(self, buf):
        return {7: self._f4, 18: self._f6, 24: self._f8}[self.k](buf)

    def _f8(self, buf):                   
        coeffs = [0] * 256
        for i in range(256):
            c = buf[i]
            mag = (1 - (c & 1)) + 2 * ((c & 0x7F) == 0x7F)
            coeffs[i] = (mag if (c >> 7) & 1 else -mag) % 3329 
        return self.R(coeffs)

    def _f6(self, buf):
        b = int.from_bytes(buf[:192], "little")
        coeffs = [0] * 256
        for i in range(256):
            c = b & 0x3F
            b >>= 6
            mag = (1 - (c & 1)) + 2 * ((c & 0x1F) == 0x1F)
            coeffs[i] = (mag if (c >> 5) & 1 else -mag) % 3329
        return self.R(coeffs)

    def _f4(self, buf):
        b = int.from_bytes(buf[:128], "little")
        coeffs = [0] * 256
        for i in range(256):
            c = b & 0x0F
            b >>= 4
            mag = (1 - (c & 1)) + 2 * ((c & 0x07) == 0x07)
            coeffs[i] = (mag if (c >> 3) & 1 else -mag) % 3329
        return self.R(coeffs)

    def _kaiburr_prf(self, sigma, N):
        return shake_256(sigma + bytes([N])).digest(self._squeeze_len())

    def _generate_error_vector(self, sigma, eta, N):
        elts = []
        for _ in range(self.k):
            elts.append(self._sample_noise(self._kaiburr_prf(sigma, N)))
            N += 1
        return self.M.vector(elts), N

    def _generate_polynomial(self, sigma, eta, N):
        return self._sample_noise(self._kaiburr_prf(sigma, N)), N + 1

    def _k_pke_encrypt(self, ek_pke, m, r):
        if len(ek_pke) != 384 * self.k + 32:
            raise ValueError("ek_pke wrong length")
        t_hat_bytes, rho = ek_pke[:-32], ek_pke[-32:]
        t_hat = self.M.decode_vector(t_hat_bytes, self.k, 12, is_ntt=True)
        if t_hat.encode(12) != t_hat_bytes:
            raise ValueError("modulus check failed")
        A_hat_T = self._generate_matrix_from_seed(rho, transpose=True)
        N = 0
        y, N = self._generate_error_vector(r, self.eta_1, N)
        e1, N = self._generate_error_vector(r, self.eta_2, N)
        e2, N = self._generate_polynomial(r, self.eta_2, N)
        y_hat = y.to_ntt()
        u = (A_hat_T @ y_hat).from_ntt() + e1
        mu = self.R.decode(m, 1).decompress(1)
        v = t_hat.dot(y_hat).from_ntt() + e2 + mu
        return u.encode(12) + v.encode(12)           # no compression

    def _k_pke_decrypt(self, dk_pke, c):
        n = self.k * 12 * 32
        c1, c2 = c[:n], c[n:]
        u = self.M.decode_vector(c1, self.k, 12)     # no decompression
        v = self.R.decode(c2, 12)
        s_hat = self.M.decode_vector(dk_pke, self.k, 12, is_ntt=True)
        w = v - (s_hat.dot(u.to_ntt())).from_ntt()
        return w.compress(1).encode(1)


INSTANCE_FOR_PARAMS = {n: KaiburrKEM(p) for n, p in KAIBURR_PARAMS.items()}

if __name__ == "__main__":
    for name, kem in INSTANCE_FOR_PARAMS.items():
        ok = True
        for _ in range(10):
            ek, dk = kem.keygen()
            ss, ct = kem.encaps(ek)
            ok &= (kem.decaps(dk, ct) == ss)
        print(f"{name}: 10/10 roundtrip={'PASS' if ok else 'FAIL'} "
              f"ek={len(ek)} dk={len(dk)} ct={len(ct)}")
        ek2, dk2 = kem.key_derive(bytes(64))
        ss2, ct2 = kem._encaps_internal(ek2, bytes(32))
        print(f"  key_derive/_encaps_internal ok: ss={len(ss2)} ct={len(ct2)}")
