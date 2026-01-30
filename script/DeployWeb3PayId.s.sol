// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Web3PayId} from "../src/Web3PayId.sol";

contract DeployWeb3PayIdScript is Script {
    Web3PayId public web3PayId;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        web3PayId = new Web3PayId();

        vm.stopBroadcast();
    }
}
