// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AppStateContract {
    // Global state variables
    uint256 public globalIntFull = 55;
    uint256 public globalIntSimplified = 33;
    uint256 public globalIntNoDefault; // Default is 0 in Solidity
    bool public globalIntNoDefaultExists = false;

    bytes public globalBytesFull = "Hello";
    bytes public globalBytesSimplified = "Hello";
    bytes public globalBytesNoDefault;
    bool public globalBytesNoDefaultExists = false;

    bool public globalBoolFull = false;
    bool public globalBoolSimplified = true;
    bool public globalBoolNoDefault; // Default is false
    bool public globalBoolNoDefaultExists = false;

    address public globalAsset; // Simulating Asset with address
    address public globalApplication; // Simulating Application with address
    address public globalAccount; // Simulating Account with address

    // Update globalIntNoDefault
    function updateGlobalIntNoDefault(uint256 newValue) public {
        globalIntNoDefault = newValue;
        globalIntNoDefaultExists = true;
    }

    // Read globalIntNoDefault
    function readGlobalIntNoDefault() public view returns (uint256, bool) {
        return (globalIntNoDefault, globalIntNoDefaultExists);
    }

    // Update globalBytesNoDefault
    function updateGlobalBytesNoDefault(bytes memory newValue) public {
        globalBytesNoDefault = newValue;
        globalBytesNoDefaultExists = true;
    }

    // Delete globalBytesNoDefault
    function deleteGlobalBytesNoDefault() public {
        globalBytesNoDefault = "";
        globalBytesNoDefaultExists = false;
    }

    // Read globalBytesNoDefault
    function readGlobalBytesNoDefault() public view returns (bytes memory, bool) {
        return (globalBytesNoDefault, globalBytesNoDefaultExists);
    }

    // Update globalBoolNoDefault
    function updateGlobalBoolNoDefault(bool newValue) public {
        globalBoolNoDefault = newValue;
        globalBoolNoDefaultExists = true;
    }

    // Add 1 to a global state value
    function getGlobalStatePlus1(uint256 stateValue) public pure returns (uint256) {
        return stateValue + 1;
    }

    // Read a global uint value by key (simulated with parameter)
    function readGlobalUint64(string memory key) public view returns (uint256) {
        if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("globalIntNoDefault"))) {
            require(globalIntNoDefaultExists, "Global uint not set");
            return globalIntNoDefault;
        }
        revert("Unknown key");
    }

    // Read a global bytes value by key (simulated with parameter)
    function readGlobalBytes(string memory key) public view returns (bytes memory) {
        if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("globalBytesNoDefault"))) {
            require(globalBytesNoDefaultExists, "Global bytes not set");
            return globalBytesNoDefault;
        }
        revert("Unknown key");
    }

    // Approval logic (simulating the approval_program)
    function approvalProgram() public view returns (bool) {
        require(globalIntSimplified == 33, "globalIntSimplified assertion failed");
        require(globalIntFull > 0, "globalIntFull assertion failed");
        require(globalIntFull == 55, "globalIntFull value mismatch");

        require(globalBytesSimplified.length > 0, "globalBytesSimplified assertion failed");
        require(globalBytesFull.length > 0, "globalBytesFull assertion failed");
        require(keccak256(globalBytesFull) == keccak256(bytes("Hello")), "globalBytesFull value mismatch");

        // Test Global Bool states
        require(globalBoolFull == false, "globalBoolFull assertion failed");
        require(globalBoolSimplified == true, "globalBoolSimplified assertion failed");

        return true;
    }

    // Clear state logic (simulating the clear_state_program)
    function clearStateProgram() public pure returns (bool) {
        return true;
    }
}
