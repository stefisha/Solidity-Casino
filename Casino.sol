// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

contract Casino{
    mapping (address => uint256) public gameWei;
    mapping (address => uint256) public blockHashesToBeUsed;

    function playGame() external payable {
        if (blockHashesToBeUsed[msg.sender] == 0) {
            blockHashesToBeUsed[msg.sender] = block.number + 2;
            gameWei[msg.sender] = msg.value;
            return;
        }

        require(
            msg.value == 0, 
            "Lottery: Finish current game before staring new one"
            );

        require(
            blockhash(blockHashesToBeUsed[msg.sender]) != 0, 
            "Lottery: Block not mined yet"
            );

        uint256 randomNumber = uint256(blockhash(blockHashesToBeUsed[msg.sender]));

        if (randomNumber % 2 == 0){
            uint256 winningAmount = gameWei[msg.sender] * 2;
            (bool success, ) = msg.sender.call{value: winningAmount}("");
            require(success, "Lottery: Winning payout failed");
        }

        blockHashesToBeUsed[msg.sender] = 0;
        gameWei[msg.sender] = 0;
    }
}