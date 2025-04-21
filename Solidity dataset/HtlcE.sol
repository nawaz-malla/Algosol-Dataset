// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashedTimeLockedContract {
    address public seller;
    address public buyer;
    uint256 public feeLimit;
    bytes32 public secretHash;
    uint256 public timeout;
    bool public isSecretRevealed = false;
    bytes32 public revealedSecret;

    event PaymentReleased(address indexed to, uint256 amount);
    event Refund(address indexed to, uint256 amount);

    constructor(
        address _seller,
        address _buyer,
        uint256 _feeLimit,
        bytes32 _secretHash,
        uint256 _timeout
    ) {
        seller = _seller;
        buyer = _buyer;
        feeLimit = _feeLimit;
        secretHash = _secretHash;
        timeout = _timeout;
    }

    /**
     * @notice Seller claims payment by revealing the correct secret.
     * @param secret The secret that matches the `secretHash`.
     */
    function claimPayment(bytes32 secret) external {
        require(msg.sender == seller, "Only seller can claim payment");
        require(!isSecretRevealed, "Secret already revealed");
        require(keccak256(abi.encodePacked(secret)) == secretHash, "Incorrect secret");
        require(address(this).balance > 0, "Insufficient contract balance");

        // Mark secret as revealed
        isSecretRevealed = true;
        revealedSecret = secret;

        // Transfer funds to the seller
        uint256 paymentAmount = address(this).balance;
        payable(seller).transfer(paymentAmount);

        emit PaymentReleased(seller, paymentAmount);
    }

    /**
     * @notice Buyer refunds their Ether after the timeout.
     */
    function refund() external {
        require(msg.sender == buyer, "Only buyer can refund");
        require(block.timestamp > timeout, "Timeout not reached");
        require(address(this).balance > 0, "Insufficient contract balance");

        // Transfer funds to the buyer
        uint256 refundAmount = address(this).balance;
        payable(buyer).transfer(refundAmount);

        emit Refund(buyer, refundAmount);
    }

    /**
     * @notice Fallback function to receive Ether.
     */
    receive() external payable {
        require(msg.value <= feeLimit, "Fee exceeds limit");
    }
}
