// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Web3PayId {
    mapping(string => address) public ids;

    // calldata is used for saving gas by making the input read-only
    function register(string calldata name) external {
        // prevent duplication
        require(ids[name] == address(0), "Name already taken");
        ids[name] = msg.sender;
    }

    function resolve(string calldata name) external view returns(address) {
        return ids[name];
    }
}