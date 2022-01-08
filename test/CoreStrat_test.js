const CoreStrat = artifacts.require("TestAbra")
const CauldronV2 = artifacts.require("CauldronV2");
const SushiRouterV2 = artifacts.require("ISushiRouter")
const IERC20 = artifacts.require("IERC20")
const BentoBox = artifacts.require("IBentoBox")
const BN = require("bn.js");
const BigNumber = require('bignumber.js');


contract("Core Strategy", (accounts) => {
    // Initialized Contracts and all
    beforeEach(async () => {
        MIM = await IERC20.at("0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A")
        DegenBox = await BentoBox.at("0x74c764D41B77DBbb4fe771daB1939B00b146894A")
        SushiRouter = await SushiRouterV2.at("0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506")
        ETHMIMCauldron = await CauldronV2.at("0xC89958B03A55B5de2221aCB25B58B89A000215E6")

        AbraStrategy = await CoreStrat.new()

    })


    it("Should Enter the Strategy", async () => {
        const ETH_AMOUNT = new BigNumber("100323243266760199")
        let investment = await AbraStrategy.investEther({from : "0x5F799f365Fa8A2B60ac0429C48B153cA5a6f0Cf8", value: ETH_AMOUNT})
        // Next show dust remaining
    })

    it("Should Free up some ETH", async () => {
        const ETH_AMOUNT1 = new BigNumber("100323243266760199")
        let investment = await AbraStrategy.investEther({from : "0x5F799f365Fa8A2B60ac0429C48B153cA5a6f0Cf8", value: ETH_AMOUNT1})
        const ETH_AMOUNT = new BigNumber("1003232432")
        let freeUpEth = await AbraStrategy.freeUpEther({from : "0x5F799f365Fa8A2B60ac0429C48B153cA5a6f0Cf8"})
        // Next show dust remaining
    })
  })