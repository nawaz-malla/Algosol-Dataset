import algopy
from algopy import (
    Account,
    GlobalState,
    BoxMap,
    Txn,
    UInt64,
    log,
    Bytes
)

class Coin(algopy.ARC4Contract):
    def __init__(self) -> None:
        # State variables
        self.minter = GlobalState(Account)  # Contract creator's address
        self.balances = BoxMap(Account, UInt64)  # Mapping of address to balance
    
    @algopy.arc4.abimethod(create="require")
    def create(self) -> None:
        """
        Constructor equivalent - initialize contract state
        """
        self.minter.value = Txn.sender
    
    @algopy.arc4.abimethod
    def mint(self, receiver: Account, amount: UInt64) -> None:
        """
        Mint new coins and send to receiver
        Only callable by contract creator
        """
        # Check sender is minter
        assert Txn.sender == self.minter.value, "Only minter can mint coins"
        
        # Get current balance or 0 if not exists
        current_balance = self.balances.get(receiver, default=UInt64(0))
        
        # Update receiver's balance
        self.balances[receiver] = current_balance + amount
        
        # Log mint event using concatenation of byte strings
        log(Bytes(b"Minted coins") + Bytes(b" to receiver"))
    
    @algopy.arc4.abimethod
    def send(self, receiver: Account, amount: UInt64) -> None:
        """
        Send coins from sender to receiver
        Can be called by anyone with sufficient balance
        """
        # Get sender's current balance
        sender_balance = self.balances.get(Txn.sender, default=UInt64(0))
        
        # Check sufficient balance with literal string
        assert sender_balance >= amount, "Insufficient balance"
        
        # Get receiver's current balance or 0 if not exists
        receiver_balance = self.balances.get(receiver, default=UInt64(0))
        
        # Update balances
        self.balances[Txn.sender] = sender_balance - amount
        self.balances[receiver] = receiver_balance + amount
        
        # Log event using byte string
        log(Bytes(b"Transfer completed"))
    
    @algopy.arc4.abimethod(readonly=True)
    def get_balance(self, account: Account) -> UInt64:
        """
        Get the balance of an account
        """
        return self.balances.get(account, default=UInt64(0))
