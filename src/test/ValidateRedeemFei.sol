// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {AaveV2Helpers, ReserveConfig} from "./utils/AaveV2Helpers.sol";
import {AaveGovHelpers, IAaveGov} from "./utils/AaveGovHelpers.sol";

import {RedeemFei} from "../RedeemFei.sol";

contract ValidationRedeemFei is Test {
    address internal constant AAVE_WHALE =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    address internal constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    // can't be constant for some reason
    string internal MARKET_NAME = "AaveV2Ethereum";

    function setUp() public {}

    /// @dev Uses an already deployed payload on the target network
    function testProposalPostPayload() public {
        /// deploy payload
        RedeemFei fei = new RedeemFei();
        _testProposal(address(fei));
    }

    function _testProposal(address payload) internal {
        ReserveConfig[] memory allConfigsBefore = AaveV2Helpers
            ._getReservesConfigs(false, MARKET_NAME);

        address[] memory targets = new address[](1);
        targets[0] = payload;
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

        // TODO confirm we get the DAI

        // ReserveConfig[] memory allConfigsAfter = AaveV2Helpers
        //     ._getReservesConfigs(false, MARKET_NAME);

        // ReserveConfig memory feiConfigBefore = AaveV2Helpers._findReserveConfig(allConfigsBefore, "FEI", true);
        // ReserveConfig memory feiConfigAfter = AaveV2Helpers._findReserveConfig(allConfigsAfter, "FEI", true);

        // require(!feiConfigBefore.isFrozen);
        // require(feiConfigAfter.isFrozen);

    }
}
