// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CounterContract {
    uint256 public counter; // Define a state variable to store the counter

    // Event to log counter updates
    event CounterUpdated(string action, uint256 newValue);

    constructor() {
        counter = 0; // Initialize counter to 0
    }

    // Function to increment the counter
    function increment() public {
        counter += 1;
        emit CounterUpdated("increment", counter);
    }

    // Function to decrement the counter
    function decrement() public {
        require(counter > 0, "Counter cannot go below 0");
        counter -= 1;
        emit CounterUpdated("decrement", counter);
    }

    // Function to reset the counter
    function reset() public {
        counter = 0;
        emit CounterUpdated("reset", counter);
    }

    // Function to retrieve the counter (getter is implicitly defined for public variable `counter`)
    function getCounter() public view returns (uint256) {
        return counter;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CounterContract {
    uint256 public counter;
    event CounterUpdated(string action, uint256 newValue);

    constructor() {
        counter = 0;
    }

    function increment() public {
        counter += 1;
        emit CounterUpdated("increment", counter);
    }

    function decrement() public {
        require(counter > 0, "Counter cannot go below 0");
        counter -= 1;
        emit CounterUpdated("decrement", counter);
    }

    function reset() public {
        counter = 0;
        emit CounterUpdated("reset", counter);
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}
