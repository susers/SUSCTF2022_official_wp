from Crypto.Util.number import *
import random

def getMyPrime(bits):
    while True:
        n = 4
        while n.bit_length()<bits:
            n*=random.choice(sieve_base)
        if isPrime(n-1):
            return n-1

flag='SUSCTF{Y0u_kNow_c0n1c_curv3_anD_discrete_l0g_vEry_we11~}'