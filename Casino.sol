// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

contract Casino {
    // Define a structure for the player information
    struct Player {
        uint256 commitment; // The amount of Wei the player has committed
        uint256 balance;    // The player's balance, initially set to the committed amount
        bytes32 secretHash; // Hash of the player's choice and secret
        bool revealed;      // Flag to indicate if the player has revealed their choice
        uint256 bet;        // The player's bet
    }

    Player[2] public players;          // Array to hold information for both players
    address[2] public playerAddresses; // Array to keep track of the players' addresses
    uint8 public numPlayers;           // Counter for the number of players
    bool public gameStarted;           // Flag to indicate if the game has started
    uint256 public revealDeadline;     // Block number by which players must reveal their bets

    // Modifier to restrict certain functions to only the participants of the game
    modifier onlyPlayers() {
        require(msg.sender == playerAddresses[0] || msg.sender == playerAddresses[1], "Not a participant");
        _;
    }

    // Function for players to submit their hashed bet and secret, along with their bet amount
    function commit(bytes32 secretHash) external payable {
        require(numPlayers < 2, "Game is full");
        require(msg.value > 0, "Send some wei to bet");

        // Record the player's commitment, balance, and the hash of their bet and secret
        players[numPlayers] = Player({
            commitment: msg.value,
            balance: msg.value,
            secretHash: secretHash,
            revealed: false,
            bet: 0
        });

        // Store the address of the player
        playerAddresses[numPlayers] = msg.sender;
        numPlayers++;

        // If two players have joined, start the game and set the deadline for revealing bets
        if (numPlayers == 2) {
            gameStarted = true;
            revealDeadline = block.number + 3; // Players have 3 blocks to reveal their bet
        }
    }

    // Function for players to reveal their bet and secret
    function reveal(uint256 bet, bytes32 secret) external onlyPlayers {
        require(gameStarted, "Game has not started");
        require(block.number <= revealDeadline, "Reveal phase has ended");

        // Determine which player is revealing based on the sender's address
        Player storage player = players[msg.sender == playerAddresses[0] ? 0 : 1];

        // Check if the hash of the revealed bet and secret matches the stored hash
        require(keccak256(abi.encodePacked(bet, secret)) == player.secretHash, "Invalid secret or bet");

        // Set the revealed flag to true and record the player's bet
        player.revealed = true;
        player.bet = bet;

        // If both players have revealed, resolve the game
        if (players[0].revealed && players[1].revealed) {
            playGame();
        }
    }

    // Internal function to determine the winner and distribute the winnings
    function playGame() internal {
        require(players[0].revealed && players[1].revealed, "Not all players have revealed");

        // Calculate the winning bet
        uint256 winningBet = players[0].bet % 2 == players[1].bet % 2 ? players[0].bet : address(this).balance;

        // Loop through both players to determine the winner and transfer winnings
        for (uint8 i = 0; i < 2; i++) {
            if (players[i].bet == winningBet) {
                // Winner gets double their commitment
                payable(playerAddresses[i]).transfer(players[i].balance * 2);
            }

            // Reset player information for a new game
            players[i] = Player({
                commitment: 0,
                balance: 0,
                secretHash: 0,
                revealed: false,
                bet: 0
            });
        }

        // Reset the game
        numPlayers = 0;
        gameStarted = false;
    }

    // Fallback function to handle direct ether transfers to the contract
    receive() external payable {}
}
