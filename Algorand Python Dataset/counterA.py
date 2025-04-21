from algopy import Contract, GlobalState, Txn, UInt64, log

class CounterContract(Contract):
    def __init__(self) -> None:
        # Define a global state variable to store the counter
        self.counter = GlobalState(UInt64(0))  # Initialize counter to 0

    def approval_program(self) -> bool:
        if Txn.application_args.length() > 0:
            action = Txn.application_args(0)

            if action == b"increment":
                self.counter.value += 1
                log(b"Counter incremented: " + self.counter.value.to_bytes())

            elif action == b"decrement":
                assert self.counter.value > 0, "Counter cannot go below 0"
                self.counter.value -= 1
                log(b"Counter decremented: " + self.counter.value.to_bytes())

            elif action == b"reset":
                self.counter.value = UInt64(0)
                log(b"Counter reset to: 0")

            else:
                log(b"Invalid action: " + action)

        return True

    def clear_state_program(self) -> bool:
        return True
