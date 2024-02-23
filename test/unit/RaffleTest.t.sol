// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/test.sol";

contract RaffleTest is Test {

  address public PLAYER = makeAddr("player");
  uint256 public constant STARTING_USER_BALANCE = 10 ether;

  Raffle raffle;
  HelperConfig helperConfig;
  
  uint256 entranceFee; 
  uint256 interval;
  address vrfCoordinator;
  bytes32 keyHash;
  uint64 subscriptionId;
  uint32 callbackGasLimit;


  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.run();
    (
      entranceFee,
      interval,
      vrfCoordinator,
      keyHash,
      subscriptionId,
      callbackGasLimit
    ) = helperConfig.activeNetworkConfig();
  }

  function testRaffleinitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
  }
}


