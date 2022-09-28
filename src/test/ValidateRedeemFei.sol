// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {AaveV2Helpers, ReserveConfig} from "./utils/AaveV2Helpers.sol";
import {AaveGovHelpers, IAaveGov} from "./utils/AaveGovHelpers.sol";

import {RedeemFei} from "../RedeemFei.sol";
import {AFeiToDaiSwapper} from "../AFeiToDaiSwapper.sol";

interface IFixedPricePSM {
    function redeem(address to, uint256 amountFeiIn, uint256 minAmountOut) external returns (uint256 amountOut);

    function getRedeemAmountOut(uint256 amountFeiIn) external view returns (uint256 amountTokenOut);

    function redeemFeeBasisPoints() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external;
}

contract ValidationRedeemFei is Test {
    address internal constant AAVE_WHALE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    address internal constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant A_DAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    address public constant AAVE_MAINNET_RESERVE_FACTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    address public constant AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    IFixedPricePSM public constant DAI_FIXED_PRICE_PSM = IFixedPricePSM(0x2A188F9EB761F70ECEa083bA6c2A40145078dfc2);

    // can't be constant for some reason
    string internal MARKET_NAME = "AaveV2Ethereum";

    RedeemFei feiPayload;
    AFeiToDaiSwapper swapper;

    function setUp() public {
        swapper = new AFeiToDaiSwapper();
        feiPayload = new RedeemFei(address(swapper));
    }

    function testProposalPostPayload() public {
        uint256 aFeiBalance = IERC20(FEI).balanceOf(A_FEI);
        uint256 aDaiReserveBalanceBefore = IERC20(A_DAI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        uint256 aFeiReserveBalanceBefore = IERC20(A_FEI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        uint256 minBalance = aFeiBalance;
        uint256 psmAmountOut = DAI_FIXED_PRICE_PSM.getRedeemAmountOut(aFeiBalance);

        address[] memory targets = new address[](1);
        targets[0] = address(feiPayload);
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
        uint256 aDaiReserveBalanceAfter = IERC20(A_DAI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        uint256 aFeiReserveBalanceAfter = IERC20(A_FEI).balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        emit log_named_uint("Amount of FEI in LendingPool", aFeiBalance);
        emit log_named_uint("Max DAI Redeem from PSM after 0bps fee -----------", minBalance);
        emit log_named_uint("PSM expected output amount from FEI in LendingPool", psmAmountOut);
        emit log_named_uint("aDAI balance before ----------------", aDaiReserveBalanceBefore);
        emit log_named_uint("aDAI balance after -----------------", aDaiReserveBalanceAfter);
        emit log_named_uint(
            "Difference between expected and real", aDaiReserveBalanceAfter - (aDaiReserveBalanceBefore + minBalance)
            );

        // AAVE Mainnet Reserve Factor gets some additional aTokens minted to it while redeeming
        // see: https://github.com/aave/protocol-v2/blob/baeb455fad42d3160d571bd8d3a795948b72dd85/contracts/protocol/libraries/logic/ReserveLogic.sol#L265-L325
        assertGe(aDaiReserveBalanceAfter, aDaiReserveBalanceBefore + minBalance);

        // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
        assertApproxEqAbs(aFeiReserveBalanceAfter, aFeiReserveBalanceBefore - aFeiBalance, 1);

        assertEq(IERC20(FEI).balanceOf(A_FEI), 0);

        // Confirm swapper never has any balance left over
        assertEq(IERC20(A_FEI).balanceOf(address(swapper)), 0);
        assertEq(IERC20(FEI).balanceOf(address(swapper)), 0);
        assertEq(IERC20(DAI).balanceOf(address(swapper)), 0);
        
    }
}
