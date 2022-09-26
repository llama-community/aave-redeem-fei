// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.11;

import {AaveV2Ethereum} from "aave-address-book/AaveV2Ethereum.sol";

interface IFixedPricePSM {
    function redeem(address to, uint256 amountFeiIn, uint256 minAmountOut) external returns (uint256 amountOut);

    function redeemFeeBasisPoints() external view returns (uint256);

    function getRedeemAmountOut(uint256 amountInFei) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ILendingPool {
    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     * wants to receive it on his own wallet, or a different address if the beneficiary is a
     * different wallet
     * @return The final amount withdrawn
     *
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     * is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     * 0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

/**
 * @author Llama
 * @dev This contract redeems all available aFEI in the Lending Pool for FEI, redeems FEI for DAI via Tribe DAO’s DAI Peg Stability Module (PSM), and deposits all DAI on Aave on behalf of AAVE_MAINNET_RESERVE_FACTOR.
 * Governance Forum Post: https://governance.aave.com/t/arc-ethereum-v2-reserve-factor-afei-holding-update/9401
 * Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0x88e896a245ffeda703e0b8f5494f3e66628be6e32a7243e3341b545c2972857f
 */
contract AFeiToDaiSwapper {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    IFixedPricePSM public constant DAI_FIXED_PRICE_PSM = IFixedPricePSM(0x2A188F9EB761F70ECEa083bA6c2A40145078dfc2);

    uint256 public constant MAX_BPS = 50;

    constructor() {
        IERC20(DAI).approve(address(AaveV2Ethereum.POOL), type(uint256).max);
        IERC20(FEI).approve(address(DAI_FIXED_PRICE_PSM), type(uint256).max);
    }

    function swapAllAvailable() external {
        uint256 redeemAmount = IERC20(FEI).balanceOf(address(AaveV2Ethereum.POOL));

        uint256 aFeiReserveBalance = IERC20(A_FEI).balanceOf(AaveV2Ethereum.COLLECTOR);
        if (aFeiReserveBalance < redeemAmount) {
            redeemAmount = aFeiReserveBalance;
        }

        IERC20(A_FEI).transferFrom(AaveV2Ethereum.COLLECTOR, address(this), redeemAmount);

        AaveV2Ethereum.POOL.withdraw(FEI, redeemAmount, address(this));

        uint256 feiBalance = IERC20(FEI).balanceOf(address(this));

        require(DAI_FIXED_PRICE_PSM.redeemFeeBasisPoints() <= MAX_BPS);

        uint256 minBalance = feiBalance - (feiBalance * MAX_BPS / 10_000);
        
        // https://docs.tribedao.xyz/docs/protocol/Mechanism/PegStabilityModule
        uint256 outBalance = DAI_FIXED_PRICE_PSM.redeem(address(this), feiBalance, minBalance);
        
        require(minBalance <= outBalance);

        AaveV2Ethereum.POOL.deposit(DAI, IERC20(DAI).balanceOf(address(this)), AaveV2Ethereum.COLLECTOR, 0);
    }
}
