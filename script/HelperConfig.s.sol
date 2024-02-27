// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
  struct NetworkConfig {
    uint256 entranceFee; 
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
  }

  NetworkConfig public activeNetworkConfig;

  constructor() {
    if (block.chainid == 11155111) {
      activeNetworkConfig = getSepoliaEthConfig();
    } else {
      activeNetworkConfig = getOrCreateAnvilEthConfig();
    }
  }

  function getSepoliaEthConfig() public returns (NetworkConfig memory) {
    return NetworkConfig({
      entranceFee: 0.01 ether,
      interval: 30,
      vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
      keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
      subscriptionId: 9494,
      callbackGasLimit: 500000,
      link: address(new LinkToken()) //TODO: find sep link
    });
  }

  
  function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {

    if (activeNetworkConfig.vrfCoordinator != address(0)) {
      return activeNetworkConfig;
    }

    // return NetworkConfig({
    //   entranceFee: 0.01 ether,
    //   interval: 30,
    //   vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
    //   keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
    //   subscriptionId: 9494,
    //   callbackGasLimit: 500000
    // });

    uint96 baseFee = 0.25 ether;
    uint96 gasPriceLink = 1e9;

    vm.startBroadcast();
    VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
    LinkToken link = new LinkToken();
    vm.stopBroadcast();

    return NetworkConfig({
      entranceFee: 0.01 ether,
      interval: 30,
      vrfCoordinator: address(vrfCoordinatorMock),
      keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
      subscriptionId: 0, //added via script?
      callbackGasLimit: 500000,
      link: address(link)
    });
  }

}