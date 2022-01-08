// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.0;

import "./IERC20.sol";

interface IMiniChef {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
}

interface ISushiRouter {
    // I am so sorry this function is so long
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IBentoBox {
    function deposit(IERC20 token_,address from,address to,uint256 amount,uint256 share) external payable returns (uint256 amountOut, uint256 shareOut);
    function withdraw(IERC20 token_,address from,address to,uint256 amount,uint256 share) external returns (uint256 amountOut, uint256 shareOut);
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
}