from algopy import Bytes, Contract, Txn, UInt64, log, op, subroutine

ADD = 1
SUB = 2
MUL = 3
DIV = 4


@subroutine
def itoa(i: UInt64) -> Bytes:
    digits = Bytes(b"0123456789")
    radix = digits.length
    if i < radix:
        return digits[i]
    return itoa(i // radix) + digits[i % radix]


class MyContract(Contract):
    def approval_program(self) -> UInt64:
        num_args = Txn.num_app_args
        if num_args == 0:
            a = UInt64(0)
            b = UInt64(0)
            action = UInt64(0)
            log(a)
            log(b)
        else:
            assert num_args == 3, "Expected 3 args"
            action_b = Txn.application_args(0)
            action = op.btoi(action_b)
            a_bytes = Txn.application_args(1)
            b_bytes = Txn.application_args(2)
            log(a_bytes)
            log(b_bytes)
            a = op.btoi(a_bytes)
            b = op.btoi(b_bytes)

        result = self.do_calc(action, a, b)
        result_b = itoa(a) + self.op(action) + itoa(b) + b" = " + itoa(result)
        log(result_b)
        return UInt64(1)

    @subroutine
    def op(self, action: UInt64) -> Bytes:
        if action == ADD:
            return Bytes(b" + ")
        elif action == SUB:
            return Bytes(b" - ")
        elif action == MUL:
            return Bytes(b" * ")
        elif action == DIV:
            return Bytes(b" // ")
        else:
            return Bytes(b" - ")

    @subroutine
    def do_calc(self, maybe_action: UInt64, a: UInt64, b: UInt64) -> UInt64:
        if maybe_action == ADD:
            return self.add(a, b)
        elif maybe_action == SUB:
            return self.sub(a, b)
        elif maybe_action == MUL:
            return self.mul(a, b)
        elif maybe_action == DIV:
            return self.div(a, b)
        else:
            assert False, "unknown operation"

    @subroutine
    def add(self, a: UInt64, b: UInt64) -> UInt64:
        return a + b

    @subroutine
    def sub(self, a: UInt64, b: UInt64) -> UInt64:
        return a - b

    @subroutine
    def mul(self, a: UInt64, b: UInt64) -> UInt64:
        return a * b

    @subroutine
    def div(self, a: UInt64, b: UInt64) -> UInt64:
        return a // b

    def clear_state_program(self) -> bool:
        return True