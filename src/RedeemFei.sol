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

interface IProposalGenericExecutor {
    function execute() external;
}

interface ILendingPoolConfigurator {
    function freezeReserve(
        address asset
    ) external;
}

interface IFixedPricePSM {
    function redeem(
        address to,
        uint256 amountFeiIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);

    function getRedeemAmountOut(
        uint256 amountFeiIn
    ) external view returns (uint256 amountTokenOut);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external;
}

interface ILendingPool {
    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

interface IEcosystemReserveController {
    /**
     * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     **/
    function approve(
        address collector,
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function for ERC20's transfer(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Transfer's recipient
     * @param amount Amount to transfer
     **/
    function transfer(
        address collector,
        address token,
        address recipient,
        uint256 amount
    ) external;
}

contract RedeemFei is IProposalGenericExecutor {

    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    address public constant AAVE_MAINNET_RESERVE_FACTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    IFixedPricePSM public constant DAI_FIXED_PRICE_PSM = IFixedPricePSM(0x2A188F9EB761F70ECEa083bA6c2A40145078dfc2);

    IEcosystemReserveController public constant AAVE_ECOSYSTEM_RESERVE_CONTROLLER =
        IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    ILendingPool public constant AAVE_LENDING_POOL = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    function execute() external override {
        uint256 aFeiBalance = IERC20(A_FEI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);

        AAVE_ECOSYSTEM_RESERVE_CONTROLLER.transfer(
            AAVE_MAINNET_RESERVE_FACTOR,
            A_FEI,
            address(this),
            aFeiBalance
        );

        AAVE_LENDING_POOL.withdraw(FEI, aFeiBalance, address(this));
        
        uint256 feiBalance = IERC20(FEI).balanceOf(address(this));

        // The minimum amount of DAI we are willing to receive after redeeming all our FEI.
        // PSM hardcodes 1 DAI = 1 FEI & takes a 3 bps redeem fee
        // so we subtract a 3bps fee from our FEI balance
        // https://etherscan.io/address/0x2A188F9EB761F70ECEa083bA6c2A40145078dfc2#readContract function 31. redeemFeeBasisPoints 
        uint256 minBalance = feiBalance - (feiBalance / 1000 * 3);

        if (DAI_FIXED_PRICE_PSM.getRedeemAmountOut(feiBalance) < minBalance) {
            // TODO figure out what to do with FEI if we cant redeem it
            // for now it transfers the FEI back to the AAVE_MAINNET_RESERVE_FACTOR for another payload to deal with
            IERC20(FEI).transfer(AAVE_MAINNET_RESERVE_FACTOR, feiBalance);
        } else {
            // we can redeem directly from PSM
            IERC20(FEI).approve(address(DAI_FIXED_PRICE_PSM), feiBalance);

            // https://docs.tribedao.xyz/docs/protocol/Mechanism/PegStabilityModule
            DAI_FIXED_PRICE_PSM.redeem(AAVE_MAINNET_RESERVE_FACTOR, feiBalance, minBalance);
        }
    }
}
