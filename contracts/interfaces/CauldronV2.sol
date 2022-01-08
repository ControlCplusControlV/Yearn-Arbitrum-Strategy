// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

interface CauldronV2 {
    function addCollateral(address to,bool skim,uint256 share) external; 
    // Amount is in Shares for borrow, idk why this isn't better named
    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function removeCollateral(address to, uint256 share) external;
}