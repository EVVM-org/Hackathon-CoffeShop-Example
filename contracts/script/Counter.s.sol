// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {CoffeShop} from "../src/CoffeShop.sol";

contract CoffeShopScript is Script {
    CoffeShop public coffeShop;

    address constant evvmAddress = 0xF817e9ad82B4a19F00dA7A248D9e556Ba96e6366;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        coffeShop = new CoffeShop(evvmAddress, msg.sender);

        vm.stopBroadcast();
    }
}
