// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {EVVMCafe} from "../src/EVVMCafe.sol";

contract EVVMCafeScript is Script {
    EVVMCafe public coffeShop;

    address constant evvmAddress = 0xF817e9ad82B4a19F00dA7A248D9e556Ba96e6366;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        coffeShop = new EVVMCafe(evvmAddress, msg.sender);

        vm.stopBroadcast();
    }
}
