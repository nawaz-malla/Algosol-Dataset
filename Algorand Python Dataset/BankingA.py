from algopy import Contract, GlobalState, Account, Txn, UInt64, log

class BankingContract(Contract):
    def __init__(self) -> None:
        # Define a global state for storing account balances
        self.balances = GlobalState(mapping_type=Account, value_type=UInt64)

    def approval_program(self) -> bool:
        # Action based on transaction arguments
        if Txn.application_args.length() > 0:
            action = Txn.application_args(0)

            if action == b"deposit":
                self.deposit()

            elif action == b"withdraw":
                amount = Txn.application_args(1).to_uint64()
                self.withdraw(amount)

            elif action == b"check_balance":
                self.check_balance()

            else:
                log(b"Invalid action: " + action)

        return True

    def clear_state_program(self) -> bool:
        return True

    def deposit(self) -> None:
        sender = Txn.sender
        amount = Txn.amount  # Amount sent with the transaction

        # Increment the sender's balance in the GlobalState
        self.balances[sender] = self.balances.get(sender, default=UInt64(0)) + amount
        log(b"Deposit successful. Balance updated: " + self.balances[sender].to_bytes())

    def withdraw(self, amount: UInt64) -> None:
        sender = Txn.sender

        # Ensure the sender has enough balance to withdraw
        current_balance = self.balances.get(sender, default=UInt64(0))
        assert current_balance >= amount, "Insufficient balance"

        # Deduct the amount from the sender's balance
        self.balances[sender] -= amount

        # Simulate sending the amount back to the sender
        # Note: In Algorand, actual asset transfers (Algos) are handled by inner transactions.
        log(b"Withdrawal successful. Amount: " + amount.to_bytes())
        log(b"Remaining balance: " + self.balances[sender].to_bytes())

    def check_balance(self) -> None:
        sender = Txn.sender

        # Retrieve and log the sender's balance
        balance = self.balances.get(sender, default=UInt64(0))
        log(b"Your balance is: " + balance.to_bytes())
