This smart contract allows two Players to wager against each other, getting real life English Premier League scores to determine the winner.

Users place wagers that are stored in the contract itself, and then automatically sent to the winner when the Chainlink request for the score is sent and fulfilled.

This effictively eliminates any trust issues, between two friends, a bookie and a client, or any other relationship.

There are multiple checks in place to assure that the contract is transparent, and both players must agree on each other's wagers before they are locked in.

Here are the steps to using the contract:
"Players" are the addresses that wagered for a team.

1) Call placeWagerForAwayTeam or placeWagerForHomeTeam. When calling it, attach the amount of ETH you want to wager. 100% of the ETH attached will go into the contract as your wager. Once one of these two functions have been called, the players cannot be changed or reset. However, if the caller of the function would like to make another wager, they are able to call the same function and follow the same procedeer, attaching the additonal ETH they would like to wager.
   
2) Once wagers for both the Home Team and Away Team have been placed, you can see the addresses of the players by calling getPlayers. You can also see the total sum of both parties' wagers by calling getSumOfWagers.

3) If both Players are satisfied with the total wagered sum, they can call player1Agrees and player2Agrees, respectively. Only once both players have agreed by calling these functions, the bool BothPlayersAgree will be set to true. Only if this is set to true, can the wager proceed. The status of both players agreeance can be checked by calling Player1Agreed, Player2Agreed, and/or getPlayerAgreementStatus, which will show either true or false. True means both Players have agreed.

4) If both players have agreed, callRequestsForScoresThenSendFundsToWinner can be called. Once this is called, the request to the chainlink oracle that will provide the score to the game will be sent and fulfilled automatically. Once the request is fulfilled and data returned, 100% of the wagered funds will be automatically to the winner. In the case of a tie, the wager will be split 50/50 between the players and sent back. Be Aware of this, because even if one player wagered more than another, it will still be split 50/50. In other words, you will not necessarily recieve back your initial wager.

@dev
The path and URL of the API can easily be changed without redeploying the contract, in order to change the game being wagered on, by calling the function updatePathandURLParameters.
