// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract LudoContract {
    
    
    
    function rollDice() external view returns (uint256) {
        uint256 random = _randomNumber();
        uint256 diceRoll = (random % 6) + 1; // Range: 1 to 6
        return diceRoll;
    }

    // function _randomNumber generates a random number using the and returns a 
    function _randomNumber() internal view returns (uint256) {

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    msg.sender
                )
            )
        );
        return random;
    }
}
