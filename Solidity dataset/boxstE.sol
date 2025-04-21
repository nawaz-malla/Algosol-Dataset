// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxContract {
    // State variables for Boxes
    uint256 public boxA;
    bytes public boxB;
    string public boxC;
    bytes public boxD;
    mapping(uint256 => string) public boxMap; // Simulating BoxMap with mapping
    mapping(uint256 => bool) public boxMapExists; // Tracking existence of keys in boxMap
    bytes public boxRef;

    constructor() {
        // Initialize any default values as needed
    }

    // Set boxes
    function setBoxes(uint256 a, bytes memory b, string memory c) public {
        boxA = a;
        boxB = b;
        boxC = c;
        boxD = b;

        // Increment boxA
        boxA += 3;

        // Validate lengths
        require(boxB.length == b.length, "Length mismatch in boxB");
        require(bytes(boxC).length == bytes(c).length, "Length mismatch in boxC");

        // Test slicing and values
        bytes memory boxBFirst5 = sliceBytes(boxB, 0, 5);
        require(boxBFirst5.length == 5, "Slicing error");
    }

    // Check keys (mimicked by variable names in Solidity)
    function checkKeys() public pure returns (bool) {
        // Solidity does not provide explicit keys like Algopy, we rely on contract design.
        return true; // Always true as keys are derived from the variable name or mapping index
    }

    // Delete boxes
    function deleteBoxes() public {
        delete boxA;
        delete boxB;
        delete boxC;

        // Default values when deleted
        require(boxA == 0, "boxA deletion failed");
        require(keccak256(boxB) == keccak256(bytes("")), "boxB deletion failed");
        require(keccak256(bytes(boxC)) == keccak256(bytes("")), "boxC deletion failed");
    }

    // Read boxes
    function readBoxes() public view returns (uint256, bytes memory, string memory) {
        return (boxA - 1, boxB, boxC);
    }

    // Check box existence
    function boxesExist() public view returns (bool, bool, bool) {
        return (boxA != 0, boxB.length > 0, bytes(boxC).length > 0);
    }

    // Slice boxD
    function sliceBox() public {
        boxD = abi.encodePacked("Testing testing 123");
        require(keccak256(sliceBytes(boxD, 0, 7)) == keccak256("Testing"), "Slice mismatch");
    }

    // Manage boxRef (Dynamic storage simulation)
    function manageBoxRef(bytes memory data) public {
        boxRef = data;

        // Resize (mimic by replacing with resized data)
        boxRef = abi.encodePacked(boxRef, new bytes(8000 - boxRef.length));
        require(boxRef.length == 8000, "Resize failed");

        // Replace a portion
        replaceBytes(boxRef, 64, bytes("hello"));

        // Delete boxRef
        delete boxRef;
        require(boxRef.length == 0, "boxRef deletion failed");
    }

    // BoxMap: Set, Get, Delete, Exists
    function boxMapSet(uint256 key, string memory value) public {
        boxMap[key] = value;
        boxMapExists[key] = true;
    }

    function boxMapGet(uint256 key) public view returns (string memory) {
        require(boxMapExists[key], "Key does not exist");
        return boxMap[key];
    }

    function boxMapDel(uint256 key) public {
        require(boxMapExists[key], "Key does not exist");
        delete boxMap[key];
        boxMapExists[key] = false;
    }

    function boxMapExistsCheck(uint256 key) public view returns (bool) {
        return boxMapExists[key];
    }

    // Utility: Slice bytes
    function sliceBytes(bytes memory data, uint256 start, uint256 end) public pure returns (bytes memory) {
        require(start <= end && end <= data.length, "Invalid slice range");
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }

    // Utility: Replace bytes at a specific position
    function replaceBytes(bytes storage original, uint256 index, bytes memory newValue) internal {
        require(index + newValue.length <= original.length, "Replace out of bounds");
        for (uint256 i = 0; i < newValue.length; i++) {
            original[index + i] = newValue[i];
        }
    }

    // Utility: Get box value + 1
    function getBoxValuePlus1(uint256 value) public pure returns (uint256) {
        return value + 1;
    }

    // Utility: Get boxRef length
    function getBoxRefLength() public view returns (uint256) {
        return boxRef.length;
    }
}



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxContract {
    uint256 public boxA;
    bytes public boxB;
    string public boxC;
    bytes public boxD;
    mapping(uint256 => string) public boxMap;
    mapping(uint256 => bool) public boxMapExists;
    bytes public boxRef;

    constructor() {}

    function setBoxes(uint256 a, bytes memory b, string memory c) public {
        boxA = a;
        boxB = b;
        boxC = c;
        boxD = b;
        boxA += 3;
        require(boxB.length == b.length, "Length mismatch in boxB");
        require(bytes(boxC).length == bytes(c).length, "Length mismatch in boxC");
        bytes memory boxBFirst5 = sliceBytes(boxB, 0, 5);
        require(boxBFirst5.length == 5, "Slicing error");
    }

    function checkKeys() public pure returns (bool) {
        return true;
    }

    function deleteBoxes() public {
        delete boxA;
        delete boxB;
        delete boxC;
        require(boxA == 0, "boxA deletion failed");
        require(keccak256(boxB) == keccak256(bytes("")), "boxB deletion failed");
        require(keccak256(bytes(boxC)) == keccak256(bytes("")), "boxC deletion failed");
    }

    function readBoxes() public view returns (uint256, bytes memory, string memory) {
        return (boxA - 1, boxB, boxC);
    }

    function boxesExist() public view returns (bool, bool, bool) {
        return (boxA != 0, boxB.length > 0, bytes(boxC).length > 0);
    }

    function sliceBox() public {
        boxD = abi.encodePacked("Testing testing 123");
        require(keccak256(sliceBytes(boxD, 0, 7)) == keccak256("Testing"), "Slice mismatch");
    }

    function manageBoxRef(bytes memory data) public {
        boxRef = data;
        boxRef = abi.encodePacked(boxRef, new bytes(8000 - boxRef.length));
        require(boxRef.length == 8000, "Resize failed");
        replaceBytes(boxRef, 64, bytes("hello"));
        delete boxRef;
        require(boxRef.length == 0, "boxRef deletion failed");
    }

    function boxMapSet(uint256 key, string memory value) public {
        boxMap[key] = value;
        boxMapExists[key] = true;
    }

    function boxMapGet(uint256 key) public view returns (string memory) {
        require(boxMapExists[key], "Key does not exist");
        return boxMap[key];
    }

    function boxMapDel(uint256 key) public {
        require(boxMapExists[key], "Key does not exist");
        delete boxMap[key];
        boxMapExists[key] = false;
    }

    function boxMapExistsCheck(uint256 key) public view returns (bool) {
        return boxMapExists[key];
    }

    function sliceBytes(bytes memory data, uint256 start, uint256 end) public pure returns (bytes memory) {
        require(start <= end && end <= data.length, "Invalid slice range");
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }

    function replaceBytes(bytes storage original, uint256 index, bytes memory newValue) internal {
        require(index + newValue.length <= original.length, "Replace out of bounds");
        for (uint256 i = 0; i < newValue.length; i++) {
            original[index + i] = newValue[i];
        }
    }

    function getBoxValuePlus1(uint256 value) public pure returns (uint256) {
        return value + 1;
    }

    function getBoxRefLength() public view returns (uint256) {
        return boxRef.length;
    }
}
