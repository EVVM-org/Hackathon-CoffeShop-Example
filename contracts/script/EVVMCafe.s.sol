// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {EVVMCafe} from "../src/EVVMCafe.sol";

contract EVVMCafeScript is Script {
    EVVMCafe public coffeShop;

    address constant evvmAddress = 0x9902984d86059234c3B6e11D5eAEC55f9627dD0f;
    address constant stakingContract = 0x2FE943eE9bD346aF46d46BD36c9ccb86201Da21A; // Replace with actual staking contract address
    address constant shopOwner = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309; // Replace with actual shop owner address
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        coffeShop = new EVVMCafe(evvmAddress, stakingContract, shopOwner);

        vm.stopBroadcast();
    }
}
