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

    enum RaffleStatus {
        OPEN,
        CLOSED
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

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_lastTimestamp = block.timestamp;
        s_status = RaffleStatus.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {

        if (s_status != RaffleStatus.OPEN) {
            revert Raffle__NotOpen();
        }

        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }

        s_status = RaffleStatus.CLOSED;
        // Will revert if subscription is not set and funded.
        uint256 requestId = i_coordinator.requestRandomWords(
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
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 index = _randomWords[0] % s_players.length;
        address payable winner = s_players[index];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_status = RaffleStatus.OPEN;
        s_lastTimestamp = block.timestamp;
        (, bool success, ) = winner.call{value: address(this).balance}("");
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
}
