// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    // Event for logging the message
    event LogMessage(string message);

    // Function to log a "Hello, [name]" message
    function sayHello(string memory name) public returns (bool) {
        string memory message = string(abi.encodePacked("Hello, ", name));
        emit LogMessage(message); // Emit the message as an event
        return true;
    }

    // Function to handle clearing or resetting state (if needed)
    function clearState() public pure returns (bool) {
        return true; // No state to clear in this example
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    event LogMessage(string message);

    function sayHello(string memory name) public returns (bool) {
        string memory message = string(abi.encodePacked("Hello, ", name));
        emit LogMessage(message);
        return true;
    }

    function clearState() public pure returns (bool) {
        return true;
    }
}