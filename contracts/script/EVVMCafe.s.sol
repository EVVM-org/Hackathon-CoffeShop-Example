// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {EVVMCafe} from "../src/EVVMCafe.sol";

contract EVVMCafeScript is Script {
    EVVMCafe public coffeShop;

    address constant evvmAddress = 0xF817e9ad82B4a19F00dA7A248D9e556Ba96e6366;
    address constant shopOwner = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309; // Replace with actual shop owner address
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        coffeShop = new EVVMCafe(evvmAddress, shopOwner);

        vm.stopBroadcast();
    }
}
