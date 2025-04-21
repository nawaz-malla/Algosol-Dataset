#1010.sol
from algopy import (
    Account,
    ARC4Contract,
    Global,
    LocalState,
    Txn,
    UInt64,
    BoxMap,
    Bytes,
    arc4,
    log,
    op,
    subroutine,
    itxn,
)

class DSWP(ARC4Contract):
    def __init__(self) -> None:
        self.name = Bytes(b"Darkswap")
        self.symbol = Bytes(b"DSWP")
        self.decimals = UInt64(18)
        self.total_supply = UInt64(1) ** UInt64(22)
        self.balance_of = LocalState(UInt64, key=b"bal")
        self.allowance = BoxMap(Bytes, UInt64, key_prefix=b"allow")

        # Initialize creator's balance
        self.balance_of[Global.creator_address] = self.total_supply

    @arc4.abimethod
    def transfer(self, target: Account, qty: UInt64) -> bool:
        sender = Txn.sender
        sender_balance = self.balance_of.get(sender, UInt64(0))
        assert sender_balance >= qty, "Insufficient balance"
        self.balance_of[sender] = sender_balance - qty

        target_balance = self.balance_of.get(target, UInt64(0))
        self.balance_of[target] = target_balance + qty

        log(op.itob(qty) + b" transferred from " + sender.bytes + b" to " + target.bytes)
        return True

    @arc4.abimethod
    def transfer_with_data(self, target: Account, qty: UInt64, data: Bytes) -> bool:
        self.transfer(target, qty)
        # Simulate tokenFallback call
        itxn.Payment(
            receiver=target,
            amount=0,
            note=data,
        ).submit()
        return True

    @arc4.abimethod
    def transfer_from(self, from_acc: Account, to_acc: Account, qty: UInt64) -> bool:
        spender = Txn.sender
        allowance_key = op.concat(from_acc.bytes, spender.bytes)
        # Fixed BoxMap access with explicit type handling
        current_allowance: UInt64 = self.allowance[allowance_key] if allowance_key in self.allowance else UInt64(0)
        
        assert current_allowance >= qty, "Allowance exceeded"
        assert self.balance_of.get(from_acc, UInt64(0)) >= qty, "Insufficient balance"

        # Update balances and allowance
        self.balance_of[from_acc] = self.balance_of.get(from_acc, UInt64(0)) - qty
        self.allowance[allowance_key] = current_allowance - qty
        self.balance_of[to_acc] = self.balance_of.get(to_acc, UInt64(0)) + qty

        log(op.itob(qty) + b" transferred from " + from_acc.bytes + b" to " + to_acc.bytes)
        return True

    @arc4.abimethod
    def approve(self, spender: Account, qty: UInt64) -> bool:
        owner = Txn.sender
        allowance_key = op.concat(owner.bytes, spender.bytes)
        self.allowance[allowance_key] = qty
        log(b"Approval: " + owner.bytes + b" approves " + spender.bytes + b" for " + op.itob(qty))
        return True

    def clear_state_program(self) -> bool:
        return True
