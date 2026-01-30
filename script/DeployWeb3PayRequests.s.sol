// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Web3PayRequest} from "../src/Web3PayRequest.sol";

contract DeployWeb3PayRequests is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        new Web3PayRequest();

        vm.stopBroadcast();
    }
}
