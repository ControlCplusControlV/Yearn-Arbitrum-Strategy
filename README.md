# Yearn-Arbitrum-Strategy

A Strategy to Maximize Yield for ETH on Arbitrum utilising Abracadabra and Curve

## High Level Overview

So a quick high level overview of the strategy goes as follows -

1. The Strategy Recieves ETH
2. ETH is supplied on Abracadabra as collateral
3. MIM is borrowed against the ETH
4. ETH and MIM are supplied to a Curve LP Pool
5. Then Harvest CRV and sell

## Environment Setup

I know Yearn mostly uses brownie but I am much better in truffle and don't mind rewriting their tests. Will add more as codebase matures.
