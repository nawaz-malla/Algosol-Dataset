from algopy import Account, ARC4Contract, Bytes, Global, Txn, arc4, subroutine

# Define event structs at module level
class OwnershipTransferred(arc4.Struct):
    previous_owner: arc4.Address
    new_owner: arc4.Address

class OwnershipTransferPrepared(arc4.Struct):
    previous_owner: arc4.Address
    new_owner: arc4.Address

class Ownable(ARC4Contract):
    """
    @title Ownable
    @author DODO Breeder (Algorand Python port)
    @notice Ownership related functions
    """

    def __init__(self) -> None:
        # Initialize owner to the creator of the contract
        self.owner = Global.creator_address
        # Initialize new owner to zero address
        self.new_owner = Account(Bytes(b"\x00" * 32))  # Zero address
        
    @subroutine
    def only_owner(self) -> None:
        """Modifier equivalent to check if sender is owner"""
        assert Txn.sender == self.owner, "NOT_OWNER"

    @arc4.abimethod(create="require")
    def init(self) -> None:
        """
        Constructor equivalent - initializes the contract
        Emits OwnershipTransferred event from zero address to creator
        """
        arc4.emit(OwnershipTransferred(
            previous_owner=arc4.Address(Bytes(b"\x00" * 32)), 
            new_owner=arc4.Address(self.owner.bytes)
        ))

    @arc4.abimethod
    def transfer_ownership(self, new_owner: arc4.Address) -> None:
        """
        Initiates ownership transfer to a new address
        @param new_owner: The address to transfer ownership to
        """
        # Check sender is current owner
        self.only_owner()
        
        # Check new owner is not zero address
        assert new_owner != arc4.Address(Bytes(b"\x00" * 32)), "INVALID_OWNER"
        
        # Store the new owner
        self.new_owner = Account(new_owner.bytes)
        
        arc4.emit(OwnershipTransferPrepared(
            previous_owner=arc4.Address(self.owner.bytes),
            new_owner=new_owner
        ))

    @arc4.abimethod
    def claim_ownership(self) -> None:
        """
        Completes the ownership transfer process. Must be called by the new owner.
        """
        # Check sender is pending new owner
        assert Txn.sender == self.new_owner, "INVALID_CLAIM"
        
        arc4.emit(OwnershipTransferred(
            previous_owner=arc4.Address(self.owner.bytes),
            new_owner=arc4.Address(self.new_owner.bytes)
        ))
        
        # Update owner to new owner
        self.owner = self.new_owner
        
        # Reset new owner to zero address
        self.new_owner = Account(Bytes(b"\x00" * 32))
