# Prisma
An experiment in fully transparent, immutable token distribution with miner-contributed liquidity.

![License](https://img.shields.io/github/license/FurryDrag0n/Prisma)

---

## 1. Introduction
Many tokens use a pre-mint distribution model, which requires neither any effort nor a strict liquidity target. This makes token promotion and liquidity provision only attractive to creators with a large initial supply. Concentrating large amounts of liquidity and tokens often leads to exit scams due to human greed. On the other hand, coins with fair distribution face the problem of insufficient liquidity, which makes it profitable to mine them only for sale, taking away liquidity and incurring losses for investors. We propose fair and transparent distribution model where miners will be forced by protocol to contribute token liquidity which potentially can resolve both problems.
## 2. Proof-of-Work
To fairly distribute tokens we'll implement a simple PoW system. This will ensure that no coin is obtained without solving a problem whose difficulty increases with the competition. Proposed PoW system is based on keccak256 hash algorhitm natively supported by EVM chains and is similar to Bitcoin's one.
