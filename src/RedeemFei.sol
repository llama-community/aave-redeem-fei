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
}

interface ISwapper {
    function swapAllAvailable() external;
}

/**
 * @author Llama
 * @dev This proposal setups the permissions for a Swapper contract to swap all the available aFEI to aDAI in the AAVE_MAINNET_RESERVE_FACTOR. It also immediatly tries to swap all the available aFEI to aDAI using the swapper.
 * Governance Forum Post: https://governance.aave.com/t/arc-ethereum-v2-reserve-factor-afei-holding-update/9401
 * Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0x519f6ecb17b00eb9c2c175c586173b15cfa5199247903cda9ddab48763ddb035
 */
contract RedeemFei is IProposalGenericExecutor {

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    address public constant AAVE_MAINNET_RESERVE_FACTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    IEcosystemReserveController public constant AAVE_ECOSYSTEM_RESERVE_CONTROLLER =
        IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    ISwapper public immutable SWAPPER;

    constructor (address swapper) {
        SWAPPER = ISwapper(swapper);
    }

    function execute() external override {
        AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
            AAVE_MAINNET_RESERVE_FACTOR,
            A_FEI,
            address(SWAPPER),
            type(uint256).max
        );
        SWAPPER.swapAllAvailable();
    }
}
