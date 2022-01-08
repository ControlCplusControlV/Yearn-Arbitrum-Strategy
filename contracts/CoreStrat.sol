// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity 0.7.0;

import "./interfaces/CauldronV2.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISushi.sol";
import "./libraries/BoringMath.sol";
import "./libraries/FullMath.sol";
import "./libraries/Curve.sol";

// Designed to Test Core Componets
contract TestAbra {
    using BoringMath for uint256;
    // Define Addresses instead of using Arbitrary Values to Clean up the Code
    address immutable MIMToken = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address immutable MIM2pool = 0x30dF229cefa463e991e29D42DB0bae2e122B2AC7;
    address immutable SushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address immutable DegenBox = 0x74c764D41B77DBbb4fe771daB1939B00b146894A;
    address immutable CauldronV2MultiChainAddr = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address immutable WETHMIMCauldron = 0xC89958B03A55B5de2221aCB25B58B89A000215E6;
    address immutable CRVZapper = 0x7544Fe3d184b6B55D6B36c3FCA1157eE0Ba30287;
    address immutable Vault; // Fix this later

    constructor() payable {
        IERC20(MIMToken).approve(SushiRouter, uint256(-1));
        IERC20(MIM2pool).approve(CRVZapper, uint256(-1));
        // @TODO approve the Curve Gauge
        setBentoBoxApproval();

    }
    
    receive() external payable {}

    fallback() external payable {}


    function setBentoBoxApproval() internal {
        IBentoBox(DegenBox).setMasterContractApproval(address(this),CauldronV2MultiChainAddr, true, 0, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000000000000000000000000000);
    }

    function borrowMIMAgainstETH(uint256 _eth) internal returns (uint256){
        // https://arbiscan.io/tx/0xc92aaa94ec8e4426caf87042efb2c4ec0c19da689b84902650ee0ad4ed07ae7b 

        (, uint ShareOut) = IBentoBox(DegenBox).deposit{value : _eth}(IERC20(0), address(this), address(this), _eth, 0);

        CauldronV2(WETHMIMCauldron).addCollateral(address(this), false, ShareOut);

        (, uint256 rate) = CauldronV2(WETHMIMCauldron).updateExchangeRate();

        uint256 borrowMIM = FullMath.mulDiv(rate, 80, 100);

        (, uint256 shareMIM) = CauldronV2(WETHMIMCauldron).borrow(address(this), borrowMIM);

        (uint256 MIMBorrowed,) = IBentoBox(DegenBox).withdraw(IERC20(MIMToken), address(this), address(this),0, shareMIM);

        return MIMBorrowed;
    }

    function depositMIMtoCurve(uint256 _amount) public {
        address[3] depositAmounts = [_amount, 0, 0];
        // 0 Can be used as a min amount because this all occurs in 1 tx, so slippage isn't a concern
        uint256 mintedAmount = ICurveZapper(CRVZapper).add_liquidity(MIM2pool, depositAmounts, 0);

        // Once LP is minted, deposit into the gauge
        ICurveFi_Gauge(0x).deposit(mintedAmount); 
    }

    function investEther() public payable {
        uint256 depositedETH = msg.value;
        uint256 collateralEther = FullMath.mulDiv(depositedETH, 55, 100);
        uint256 borrowedMIM = borrowMIMAgainstETH(collateralEther);
        
        uint256 liquidEther = uint256(msg.value).sub(collateralEther);

        // better to have excess "want" tokens than MIM, fix to have 80% slippage tolerance though
        (uint amountToken, uint amountETH, uint liquidity) = ISushiRouter(SushiRouter).addLiquidityETH{value : liquidEther}(MIMToken, borrowedMIM, borrowedMIM, 1, address(this), block.timestamp+5);

    }

    function freeUpEther(uint256 amount) public {

        // Min out set as 1, IL would rarely cause such a loss, but there is no case where we want this fail, get out all funds whether there or not
        (uint MIMOut, uint amountETH) = ISushiRouter(SushiRouter).removeLiquidityETH(MIMToken, amount, 1, 1, address(this), block.timestamp + 5);

        // Next send MIM out to the BentboBox
        (uint amountOut, uint ShareOut) = IBentoBox(DegenBox).deposit(IERC20(MIMToken), address(this), address(this), MIMOut, 0);

        // Exchange rate so we know how much collateral to remove
        (, uint256 rate) = CauldronV2(WETHMIMCauldron).updateExchangeRate();

        // Repay MIM to free up collateral
        CauldronV2(WETHMIMCauldron).repay(address(this), false, ShareOut);

        uint256 ethOut = amountOut.div(rate);

        uint removeShares = IBentoBox(DegenBox).toShare(IERC20(0), ethOut, false);

        CauldronV2(WETHMIMCauldron).removeCollateral(address(this, removeShares));

        IBentoBox(DegenBox).withdraw(IERC20(0), address(this), address(this), 0, removeShares)
    } 

}