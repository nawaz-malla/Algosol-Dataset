from algopy import Account, ARC4Contract, Box, BoxMap, Global, Txn, UInt64, arc4, itxn, subroutine

class Reentrance(ARC4Contract):
    """
    @title Reentrance
    @notice A contract demonstrating reentrancy vulnerabilities and fixes
    """
    
    def __init__(self) -> None:
        # Initialize user balances using box storage
        self.balances = BoxMap(Account, UInt64, key_prefix=b"balance_")

    @arc4.abimethod
    def get_balance(self, user: arc4.Address) -> arc4.UInt64:
        """
        Get the balance of a user
        @param user: Address to check balance for
        @return The user's balance
        """
        balance = self.balances[Account(user.bytes)]
        return arc4.UInt64(balance)

    @arc4.abimethod
    def add_to_balance(self) -> None:
        """Add to sender's balance"""
        # Get the payment from the transaction
        assert Txn.amount > UInt64(0), "PAYMENT_REQUIRED"
        
        # Add to user's balance
        current_balance = self.balances[Txn.sender]
        self.balances[Txn.sender] = current_balance + Txn.amount

    @arc4.abimethod
    def withdraw_balance_unsafe(self) -> None:
        """
        Withdraw balance - UNSAFE version demonstrating reentrancy vulnerability
        While Algorand's atomic transaction groups make this less dangerous than Ethereum,
        it's still not recommended to structure code this way
        """
        balance = self.balances[Txn.sender]
        assert balance > UInt64(0), "NO_BALANCE"
        
        # Send payment first (potentially dangerous as it allows reentrancy)
        itxn.Payment(
            receiver=Txn.sender,
            amount=balance,
            fee=0
        ).submit()
        
        # Update balance after payment (vulnerable)
        self.balances[Txn.sender] = UInt64(0)

    @arc4.abimethod
    def withdraw_balance_fixed(self) -> None:
        """
        Withdraw balance - Fixed version that prevents reentrancy
        by updating state before making payment
        """
        # Get and verify balance
        balance = self.balances[Txn.sender]
        assert balance > UInt64(0), "NO_BALANCE"
        
        # Update state before payment (safe)
        self.balances[Txn.sender] = UInt64(0)
        
        # Send payment after state update
        itxn.Payment(
            receiver=Txn.sender,
            amount=balance,
            fee=0
        ).submit()

    @arc4.abimethod
    def withdraw_balance_fixed_2(self) -> None:
        """
        Withdraw balance - Alternative fixed version
        While Algorand doesn't have the same gas concerns as Ethereum,
        this demonstrates the principle of the Solidity transfer() approach
        """
        # Get and verify balance
        balance = self.balances[Txn.sender]
        assert balance > UInt64(0), "NO_BALANCE"
        
        # Update state first
        self.balances[Txn.sender] = UInt64(0)
        
        # Send payment
        itxn.Payment(
            receiver=Txn.sender,
            amount=balance,
            fee=0
        ).submit()
