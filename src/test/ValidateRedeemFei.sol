// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {AaveV2Helpers, ReserveConfig} from "./utils/AaveV2Helpers.sol";
import {AaveGovHelpers, IAaveGov} from "./utils/AaveGovHelpers.sol";

import {RedeemFei} from "../RedeemFei.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external;
}

contract ValidationRedeemFei is Test {
    address internal constant AAVE_WHALE =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    address internal constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant AAVE_MAINNET_RESERVE_FACTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // can't be constant for some reason
    string internal MARKET_NAME = "AaveV2Ethereum";

    RedeemFei fei;

    function setUp() public {
        fei = new RedeemFei();
    }

    function testProposalPostPayload() public {

        uint256 aFeiAmount = 300_000e18;
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);

        address[] memory targets = new address[](1);
        targets[0] = address(fei);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = AaveGovHelpers._createProposal(
            vm,
            AAVE_WHALE,
            IAaveGov.SPropCreateParams({
                executor: AaveGovHelpers.SHORT_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        AaveGovHelpers._passVote(vm, AAVE_WHALE, proposalId);

        uint256 minBalance = aFeiAmount - (aFeiAmount * 3 / 10_000);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        assertEq(daiBalanceAfter, daiBalanceBefore + minBalance);

    }
}
