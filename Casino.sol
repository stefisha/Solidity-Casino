// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

contract Casino {
    struct Player {
        uint256 commitment;
        uint256 balance;
        bytes32 secretHash;
        bool revealed;
        uint256 bet;
    }

    Player[2] public players;
    address[2] public playerAddresses;
    uint8 public numPlayers;
    bool public gameStarted;
    uint256 public revealDeadline;

    modifier onlyPlayers() {
        require(msg.sender == playerAddresses[0] || msg.sender == playerAddresses[1], "Not a participant");
        _;
    }

    function commit(bytes32 secretHash) external payable {
        require(numPlayers < 2, "Game is full");
        require(msg.value > 0, "Send some wei to bet");

        players[numPlayers] = Player({
            commitment: msg.value,
            balance: msg.value,
            secretHash: secretHash,
            revealed: false,
            bet: 0
        });

        playerAddresses[numPlayers] = msg.sender;
        numPlayers++;

        if (numPlayers == 2) {
            gameStarted = true;
            revealDeadline = block.number + 3; // Players have 3 blocks to reveal their bet
        }
    }

    function reveal(uint256 bet, bytes32 secret) external onlyPlayers {
        require(gameStarted, "Game has not started");
        require(block.number <= revealDeadline, "Reveal phase has ended");

        Player storage player = players[msg.sender == playerAddresses[0] ? 0 : 1];

        require(keccak256(abi.encodePacked(bet, secret)) == player.secretHash, "Invalid secret or bet");

        player.revealed = true;
        player.bet = bet;

        if (players[0].revealed && players[1].revealed) {
            resolveGame();
        }
    }

    function resolveGame() internal {
        require(players[0].revealed && players[1].revealed, "Not all players have revealed");

        uint256 winningBet = players[0].bet % 2 == players[1].bet % 2 ? players[0].bet : address(this).balance;

        for (uint8 i = 0; i < 2; i++) {
            if (players[i].bet == winningBet) {
                payable(playerAddresses[i]).transfer(players[i].balance * 2);
            }

            // Reset the game
            players[i] = Player({
                commitment: 0,
                balance: 0,
                secretHash: 0,
                revealed: false,
                bet: 0
            });
        }

        numPlayers = 0;
        gameStarted = false;
    }

    // Fallback function to handle direct ether transfers to the contract
    receive() external payable {}
}
