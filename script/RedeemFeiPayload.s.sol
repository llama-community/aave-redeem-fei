// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import "src/RedeemFei.sol";


contract RedeemFeiDeployScript is Script {

    function run() external {
        vm.startBroadcast();

        RedeemFei fei = new RedeemFei();

        vm.stopBroadcast();
    }
}