// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankingContract {
    // Define a mapping to store account balances
    mapping(address => uint256) public balances;

    // Deposit function
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Increment the sender's balance
        balances[msg.sender] += msg.value;

        // Emit an event for deposit (optional)
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    // Withdraw function
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Deduct the amount from the sender's balance
        balances[msg.sender] -= amount;

        // Transfer the amount back to the sender
        payable(msg.sender).transfer(amount);

        // Emit an event for withdrawal (optional)
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    // Check balance function
    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Events for logging
    event Deposit(address indexed account, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed account, uint256 amount, uint256 remainingBalance);
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankingContract {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    event Deposit(address indexed account, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed account, uint256 amount, uint256 remainingBalance);

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }

    function transferFunds(address to, uint256 amount) public onlyPositiveAmount(amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
}