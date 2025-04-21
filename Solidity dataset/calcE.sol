// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
    // Event to log results
    event Calculation(string expression, uint256 result);

    // Constants for actions
    uint8 private constant ADD = 1;
    uint8 private constant SUB = 2;
    uint8 private constant MUL = 3;
    uint8 private constant DIV = 4;

    // Main function to perform the calculation
    function calculate(uint8 action, uint256 a, uint256 b) public returns (uint256) {
        uint256 result;

        if (action == ADD) {
            result = add(a, b);
        } else if (action == SUB) {
            result = sub(a, b);
        } else if (action == MUL) {
            result = mul(a, b);
        } else if (action == DIV) {
            require(b != 0, "Division by zero is not allowed");
            result = div(a, b);
        } else {
            revert("Invalid operation");
        }

        // Log the result as an event
        emit Calculation(_buildExpression(action, a, b, result), result);

        return result;
    }

    // Add two numbers
    function add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    // Subtract two numbers
    function sub(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    // Multiply two numbers
    function mul(uint256 a, uint256 b) private pure returns (uint256) {
        return a * b;
    }

    // Divide two numbers
    function div(uint256 a, uint256 b) private pure returns (uint256) {
        return a / b;
    }

    // Helper function to build the result expression
    function _buildExpression(uint8 action, uint256 a, uint256 b, uint256 result) 
        private 
        pure 
        returns (string memory) 
    {
        string memory op = _getOperator(action);
        return string(
            abi.encodePacked(
                uintToString(a),
                op,
                uintToString(b),
                " = ",
                uintToString(result)
            )
        );
    }

    // Get operator symbol for the action
    function _getOperator(uint8 action) private pure returns (string memory) {
        if (action == ADD) return " + ";
        if (action == SUB) return " - ";
        if (action == MUL) return " * ";
        if (action == DIV) return " / ";
        return " ?";
    }

    // Utility to convert uint to string
    function uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
    event Calculation(string expression, uint256 result);

    uint8 private constant ADD = 1;
    uint8 private constant SUB = 2;
    uint8 private constant MUL = 3;
    uint8 private constant DIV = 4;

    function calculate(uint8 action, uint256 a, uint256 b) public returns (uint256) {
        uint256 result;

        if (action == ADD) {
            result = add(a, b);
        } else if (action == SUB) {
            result = sub(a, b);
        } else if (action == MUL) {
            result = mul(a, b);
        } else if (action == DIV) {
            require(b != 0, "Division by zero is not allowed");
            result = div(a, b);
        } else {
            revert("Invalid operation");
        }

        emit Calculation(_buildExpression(action, a, b, result), result);

        return result;
    }

    function add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) private pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) private pure returns (uint256) {
        return a / b;
    }

    function _buildExpression(uint8 action, uint256 a, uint256 b, uint256 result) 
        private 
        pure 
        returns (string memory) 
    {
        string memory op = _getOperator(action);
        return string(
            abi.encodePacked(
                uintToString(a),
                op,
                uintToString(b),
                " = ",
                uintToString(result)
            )
        );
    }

    function _getOperator(uint8 action) private pure returns (string memory) {
        if (action == ADD) return " + ";
        if (action == SUB) return " - ";
        if (action == MUL) return " * ";
        if (action == DIV) return " / ";
        return " ?";
    }

    function uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
