from algopy import (
    ARC4Contract,
    UInt64,
    Bytes,
    arc4,
    subroutine,
    log
)

@subroutine
def itoa(i: UInt64) -> Bytes:
    digits = Bytes(b"0123456789")
    radix = digits.length
    if i < radix:
        return digits[i]
    return itoa(i // radix) + digits[i % radix]

class CalculatorContract(ARC4Contract):
    @arc4.abimethod
    def add(self, a: UInt64, b: UInt64) -> UInt64:
        """Add two numbers and log the calculation."""
        result = a + b
        log_msg = itoa(a) + Bytes(b" + ") + itoa(b) + Bytes(b" = ") + itoa(result)
        log(log_msg)
        return result

    @arc4.abimethod
    def subtract(self, a: UInt64, b: UInt64) -> UInt64:
        """Subtract b from a and log the calculation."""
        result = a - b
        log_msg = itoa(a) + Bytes(b" - ") + itoa(b) + Bytes(b" = ") + itoa(result)
        log(log_msg)
        return result

    @arc4.abimethod
    def multiply(self, a: UInt64, b: UInt64) -> UInt64:
        """Multiply two numbers and log the calculation."""
        result = a * b
        log_msg = itoa(a) + Bytes(b" * ") + itoa(b) + Bytes(b" = ") + itoa(result)
        log(log_msg)
        return result

    @arc4.abimethod
    def divide(self, a: UInt64, b: UInt64) -> UInt64:
        """Divide a by b and log the calculation."""
        # Check for division by zero
        assert b != UInt64(0), "Cannot divide by zero"
        result = a // b
        log_msg = itoa(a) + Bytes(b" / ") + itoa(b) + Bytes(b" = ") + itoa(result)
        log(log_msg)
        return result

    def clear_state_program(self) -> bool:
        return True
