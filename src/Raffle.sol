// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETHSent();
    error Raffle__NotEnoughTimePassed();
    error Raffle__NotOpen();
    error Raffle__TransferFailed();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 currentPlayers, uint256 s_status);

    enum RaffleStatus {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;

    //@dev Duration of the lottery in seconds
    uint256 private immutable i_interval;

    VRFCoordinatorV2Interface private immutable i_coordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    address payable private s_recentWinner;
    uint256 private s_lastTimestamp;
    RaffleStatus private s_status;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, address link) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_lastTimestamp = block.timestamp;
        s_status = RaffleStatus.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_status != RaffleStatus.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev     Func for chainlink to call for upkeep
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool, bytes memory) {
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool isOpen = s_status == RaffleStatus.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        return (timeHasPassed && isOpen && hasBalance && hasPlayers, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_status));
        }
        s_status = RaffleStatus.CALCULATING;
        // Will revert if subscription is not set and funded.
        i_coordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // uint256 index = random() % s_players.length;
        // s_players[index].transfer(address(this).balance);
        // s_players = new address payable[](0);
    }

    function fulfillRandomWords(
        uint256 /* _requestId */,
        uint256[] memory _randomWords
    ) internal override {
        uint256 index = _randomWords[0] % s_players.length;
        address payable winner = s_players[index];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_status = RaffleStatus.OPEN;
        s_lastTimestamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            // This should never happen, but just in case.
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }

    /** Getters */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleStatus) {
        return s_status;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address payable) {
        return s_players[indexOfPlayer];
    }
}
