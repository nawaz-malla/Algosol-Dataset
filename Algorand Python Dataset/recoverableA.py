from algopy import Account, ARC4Contract, Asset, Bytes, Global, Txn, UInt64, arc4, itxn, subroutine

class Recoverable(ARC4Contract):
    """
    @title Recoverable
    @notice A contract that allows the owner to recover ASAs sent to it
    @dev Inherits ownership functionality from ARC4Contract
    """
    
    def __init__(self) -> None:
        # Initialize owner to the creator of the contract
        self.owner = Global.creator_address
        # Initialize new owner to zero address
        self.new_owner = Account(Bytes(b"\x00" * 32))
        
    @subroutine
    def only_owner(self) -> None:
        """Modifier equivalent to check if sender is owner"""
        assert Txn.sender == self.owner, "NOT_OWNER"

    @arc4.abimethod
    def recover_asset(self, token: Asset) -> None:
        """
        Allows the owner to recover ASAs sent to the contract
        @param token: The ASA to recover
        """
        # Check sender is current owner
        self.only_owner()
        
        # Get the amount of tokens to be returned
        amount = self.tokens_to_be_returned(token)
        
        # Create and submit the asset transfer inner transaction
        itxn.AssetTransfer(
            xfer_asset=token,
            asset_amount=amount,
            asset_receiver=self.owner,
            fee=0
        ).submit()

    @arc4.abimethod
    def tokens_to_be_returned(self, token: Asset) -> UInt64:
        """
        Returns the amount of tokens the contract owns
        @param token: The ASA to check balance for
        @return The amount of tokens the contract owns
        """
        return token.balance(Global.current_application_address)

    @arc4.abimethod(create="require")
    def init(self) -> None:
        """Constructor equivalent - initializes the contract"""
        pass

    @arc4.abimethod
    def transfer_ownership(self, new_owner: arc4.Address) -> None:
        """
        Initiates ownership transfer to a new address
        @param new_owner: The address to transfer ownership to
        """
        self.only_owner()
        assert new_owner != arc4.Address(Bytes(b"\x00" * 32)), "INVALID_OWNER"
        self.new_owner = Account(new_owner.bytes)
        arc4.emit("OwnershipTransferPrepared", arc4.Address(self.owner.bytes), new_owner)

    @arc4.abimethod
    def claim_ownership(self) -> None:
        """
        Completes the ownership transfer process. Must be called by the new owner.
        """
        assert Txn.sender == self.new_owner, "INVALID_CLAIM"
        arc4.emit("OwnershipTransferred", 
                 arc4.Address(self.owner.bytes), 
                 arc4.Address(self.new_owner.bytes))
        self.owner = self.new_owner
        self.new_owner = Account(Bytes(b"\x00" * 32))