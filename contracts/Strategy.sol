// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {StrategyLib} from "./libraries/StrategyLib.sol";
import {BaseStrategy} from "./YearnBaseStrategy.sol";

// Some Local Imports I used
import "./interfaces/CauldronV2.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISushi.sol";
import "./libraries/BoringMath.sol";
import "./libraries/FullMath.sol";
import "./libraries/Curve.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}


// Now the actual implementation of the strategy

contract ArbitrumETHStrategy is BaseStrategy {

    /* ------------------- CONSTANTS -------------------------------- */
    address immutable MIMToken = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address immutable MIM2pool = 0x30dF229cefa463e991e29D42DB0bae2e122B2AC7;
    address immutable SushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address immutable DegenBox = 0x74c764D41B77DBbb4fe771daB1939B00b146894A;
    address immutable CauldronV2MultiChainAddr = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address immutable WETHMIMCauldron = 0xC89958B03A55B5de2221aCB25B58B89A000215E6;
    address immutable CRVZapper = 0x7544Fe3d184b6B55D6B36c3FCA1157eE0Ba30287;
    address immutable Vault; // Fix this later

    /* -------------------  MODIFIERS ---------------------------------- */

    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance());
    }

    function _onlyEmergencyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management());
    }

    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyRewarder() internal {
        require(msg.sender == governance() || msg.sender == strategist);
    }

    function _onlyKeepers() internal {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    /* ---------------------- Events needed for Indexers ----------------- */

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    /* ---------------------- Other Functions ---------------------------- */

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);

        // Next Set Some Approvals
        IERC20(MIMToken).approve(SushiRouter, uint256(-1));
        IERC20(MIM2pool).approve(CRVZapper, uint256(-1));
        IBentoBox(DegenBox).setMasterContractApproval(address(this),CauldronV2MultiChainAddr, true, 0, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000000000000000000000000000);

    }

    function name() public view returns (string memory){
        return "StrategyArbitrumETH";
    }

    function vault() public view returns (address){

    }

    function want() public view returns (address){
        return address(0);
    }

    function apiVersion() public pure returns (string memory){
        return "0.4.3";
    }

    function ethToWant(uint256 _amtInWei) public view returns (uint256) {
        return _amtInWei; // Because Want is ETH
    }

    function keeper() public view returns (address){

    }

    function isActive() public view returns (bool){

    }

    function delegatedAssets() public view returns (uint256){

    }

    function estimatedTotalAssets() public view returns (uint256){

    }

    function tendTrigger(uint256 callCost) public view returns (bool){

    }

    function tend() public{
    }

    function harvestTrigger(uint256 callCost) public view returns (bool){

    }

    /* -------------------- The Fun Functions -------------- */

    function prepareReturn(uint256 _debtOutstanding) internal returns (uint256 _profit, uint256 _loss, uint256 _debtPayment){
        // Purpose is to free up _debtOutstanding of Ether
        // First step is to withdraw MIM from Curve LP and Gauge
        
        // Next send MIM out to the BentboBox
        (uint amountOut, uint ShareOut) = IBentoBox(DegenBox).deposit(IERC20(MIMToken), address(this), address(this), MIMOut, 0);

        // Exchange rate so we know how much collateral to remove
        (, uint256 rate) = CauldronV2(WETHMIMCauldron).updateExchangeRate();

        // Repay MIM to free up collateral
        CauldronV2(WETHMIMCauldron).repay(address(this), false, ShareOut);

        uint256 ethOut = amountOut.div(rate);

        uint removeShares = IBentoBox(DegenBox).toShare(IERC20(0), ethOut, false);

        CauldronV2(WETHMIMCauldron).removeCollateral(address(this, removeShares));

        IBentoBox(DegenBox).withdraw(IERC20(0), address(this), address(this), 0, removeShares);

        // Swap Excess Tokens for Want Tokens
        uint256 CRVSold;
        uint256 MIMFeesSold;
        uint256 CRV2poolSold;

        // Profit is the sum of all Want Tokens Sold
        _profit = CRVSold + MIMFeesSold + CRV2poolSold;

        if(_profit == 0) {
            // If there is no profit, then a loss must be reported
        } else {
            _loss = 0;
        }

    }

    function adjustPosition(uint256 _debtOutstanding) internal {{

    }

    function harvest() public {
        (uint256 _profit, uint256 _loss, uint256 _debtPayment) =  prepareReturn(_debtOutstanding);
        // Report to vault
        VaultAPI().report(_profit, _loss, _debtPayment);

        adjustPosition(_debtOutstanding);
    }

    /* ------------------- Unwinding Functions -------------------- */
    function liquidatePosition(uint256 _amountNeeded) internal returns (uint256 _liquidatedAmount, uint256 _loss) {

    }

    function liquidateAllPositions() internal returns (uint256 _amountFreed){

    }

    /* -------------------- Emergency Vault Functions ------------------------ */

    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        SafeERC20.safeTransfer(want, msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    function setEmergencyExit() external {
        _onlyEmergencyAuthorized();
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }
}