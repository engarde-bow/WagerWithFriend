//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 */
contract GettingTwoScores is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    address private oracleAddress;
    bytes32 private jobId;
    uint256 private fee;

    // Errors //
    error WagerMoreThanZero();
    error MustbeCorrectPlayer();
    error bothPlayersMustAgree();
    error tie();

    // Booleans //
    bool public player1Agreed = false;
    bool public player2Agreed = false;
    bool public bothPlayersAgreed = false;

    // State variables for the two responses
    uint256 public s_response1;
    uint256 public s_response2;
    address payable s_player1; // Player 1 is Always Betting on Away Team to Win. Nobody wins in case of tie.
    address payable s_player2; // Player 2 is Always Betting on Home Team to Win. Nobody wins in case of tie.

    // Define request parameters as state variables
    string public method;
    string public url;
    string public headers;
    string public body;
    string public contact;
    string public path1;
    string public path2;
    int256 public multiplier;

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setOracleAddress(0x0FaCf846af22BCE1C7f88D1d55A038F27747eD2B);
        setJobId("a8356f48569c434eaa4ac5fcb4db5cc0");
        setFeeInHundredthsOfLink(0); // 0 LINK

        // Initialize request parameters
        method = "GET";
        url = "https://api.sportsdata.io/v4/soccer/scores/json/ScoresBasic/EPL/2024-02-03?key={YourAPIKEY}";
        headers = '["content-type","application/json"]';
        body = "";
        contact = "";
        path1 = "1,AwayTeamScore";
        path2 = "1,HomeTeamScore";
        multiplier = 1;
    }

    /*function setRequestParameters(string memory _method, string memory _url, string memory _headers, string memory _body, string memory _contact, string memory _path1, string memory _path2, int256 _multiplier) public onlyOwner {
    method = _method;
    url = _url;
    headers = _headers;
    body = _body;
    contact = _contact;
    path1 = _path1;
    path2 = _path2;
    multiplier = _multiplier;
    }
    */

    function setPlayers(address payable player1, address payable player2) public {
        s_player1 = player1;
        s_player2 = player2;
    }

    function getPlayers() public view returns (address, address) {
        return (s_player1, s_player2);
    }

    // function placeWager(uint256 amount) public {
    //      if (amount <= 0) {
    //         revert BetMoreThanZero();
    //     }
    //     address(this).transfer(msg.sender(amount));
    // }

    function placeWager() public payable {
        if (msg.value <= 0) {
            revert WagerMoreThanZero();
        }
        // address(this).transfer(msg.value);
    }

    function getSumOfWagers() public view returns (uint256) {
        return address(this).balance;
    }

    function player1Agrees() public {
        if (msg.sender != s_player1) {
            revert MustbeCorrectPlayer();
        }
        player1Agreed = true;
    }

    function player2Agrees() public {
        if (msg.sender != s_player2) {
            revert MustbeCorrectPlayer();
        }
        player2Agreed = true;
    }

    function lockInBet() public {
        if (player1Agreed == true && player2Agreed == true) {
            bothPlayersAgreed = true;
        }
    }

    function getPlayerAgreement() public view returns (bool) {
        return bothPlayersAgreed;
    }

    //Call both requests in one transaction
    function callBothRequests() public {
        if (bothPlayersAgreed != true) {
            revert bothPlayersMustAgree();
        }
        request1();
        request2();
    }

    // Request data from the first path
    function request1() internal {
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfill1.selector);
        // Set request parameters for the first path...
        // Use state variables for request parameters
        req.add("method", method);
        req.add("url", url);
        req.add("headers", headers);
        req.add("body", body);
        req.add("contact", contact);
        req.add("path", path1);
        req.addInt("multiplier", multiplier);
        // send request
        sendOperatorRequest(req, fee);
    }

    // Request data from the second path
    function request2() internal {
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfill2.selector);
        // Set request parameters for the second path...
        // Use state variables for request parameters
        req.add("method", method);
        req.add("url", url);
        req.add("headers", headers);
        req.add("body", body);
        req.add("contact", contact);
        req.add("path", path2);
        req.addInt("multiplier", multiplier);
        sendOperatorRequest(req, fee);
    }

    // Fulfill the first request
    function fulfill1(bytes32 requestId, uint256 data1) public recordChainlinkFulfillment(requestId) {
        s_response1 = data1;
    }

    // Fulfill the second request
    function fulfill2(bytes32 requestId, uint256 data2) public recordChainlinkFulfillment(requestId) {
        s_response2 = data2;
    }

    // Update oracle address
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
        setChainlinkOracle(_oracleAddress);
    }

    function getOracleAddress() public view onlyOwner returns (address) {
        return oracleAddress;
    }

    // Update jobId
    function setJobId(string memory _jobId) public onlyOwner {
        jobId = bytes32(bytes(_jobId));
    }

    function getJobId() public view onlyOwner returns (string memory) {
        return string(abi.encodePacked(jobId));
    }

    // Update fees
    function setFeeInJuels(uint256 _feeInJuels) public onlyOwner {
        fee = _feeInJuels;
    }

    function setFeeInHundredthsOfLink(uint256 _feeInHundredthsOfLink) public onlyOwner {
        setFeeInJuels((_feeInHundredthsOfLink * LINK_DIVISIBILITY) / 100);
    }

    function getFeeInHundredthsOfLink() public view onlyOwner returns (uint256) {
        return (fee * 100) / LINK_DIVISIBILITY;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function sendWagerSumToWinner() public {
        if (s_response1 > s_response2) {
            s_player1.transfer(address(this).balance);
        } else if (s_response2 > s_response1) {
            s_player2.transfer(address(this).balance);
        } else if (s_response2 == s_response1) {
            revert tie();
        }
    }

    function updatePathParameters(string memory _path1, string memory _path2) public onlyOwner {
        path1 = _path1;
        path2 = _path2;
    }
}

