// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/test.sol";

contract RaffleTest is Test {

  /** Events */
  event EnteredRaffle(address indexed player);

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
  address link;


  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.run();
    (
      entranceFee,
      interval,
      vrfCoordinator,
      keyHash,
      subscriptionId,
      callbackGasLimit,
      link
    ) = helperConfig.activeNetworkConfig();
    vm.deal(PLAYER, STARTING_USER_BALANCE);
  }

  function testRaffleinitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
  }

  function testRaffleRevertsWhenYouDontPayEnough() public {
    // ARRANGE
    vm.prank(PLAYER);

    // ACT & assert

    vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);

    raffle.enterRaffle();
  }

  function testRaffleRecordsPlayerWhenTheyEnter () public {
    // ARRANGE
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
  }

  function testEmitsEventOnEntrance() public {
    // ARRANGE
    vm.prank(PLAYER);
    vm.expectEmit(true, false, false, false, address(raffle));
    emit EnteredRaffle(PLAYER);

    // ACT
    raffle.enterRaffle{value: entranceFee}();
  }

  function testCantEnterWhenRaffleIsCalculating() public {
    // ARRANGE
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    // ACT
    vm.expectRevert(Raffle.Raffle__NotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
  }

}


