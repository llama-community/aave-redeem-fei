// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import "src/RedeemFei.sol";
import {AFeiToDaiSwapper} from "src/AFeiToDaiSwapper.sol";

contract RedeemFeiDeployScript is Script {

    function run() external {
        vm.startBroadcast();

        AFeiToDaiSwapper swapper = new AFeiToDaiSwapper();
        RedeemFei fei = new RedeemFei(address(swapper));

        vm.stopBroadcast();
    }
}