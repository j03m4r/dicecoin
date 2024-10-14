// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {DiceCoin} from "../src/DiceCoin.sol";
import {DeployDiceCoin} from "../script/DeployDiceCoin.s.sol";

contract TestDiceCoin is Test {
    DiceCoin DC;

    function setUp() external {
        DeployDiceCoin DDC = new DeployDiceCoin();

        DC = DDC.run();
        console.log("Sender address", address(this));
        console.log("Other address", msg.sender);
    }

    function testPublicVariables() public view {
        assertEq(DC.INITIAL_SUPPLY(), 1000000);
        assertEq(DC._payoutExact(), 5);
        assertEq(DC._payoutEvenOrOdd(), 2);
    }

    function testBuyIn() public {
        uint256 wallet = DC.getDCWallet();
        DC.buyIn();
        if (wallet == 0) {
            assertEq(DC.getDCWallet(), 5);
        } else {
            assertEq(DC.getDCWallet(), wallet);
        }
    }

    function testPlaceEvenOddWager() public {
        DC.buyIn();

        uint256 evenOddMultiplier = DC._payoutEvenOrOdd();
        uint256 wallet = DC.getDCWallet();

        uint256 wager = 1;

        console.log("Sender balance (pre-wager):", DC.getDCWallet());
        uint256 roll = DC.placeWager(wager, true);
        console.log("Sender balance (post-wager):", DC.getDCWallet());
        if (roll % 2 == 0) {
            assertEq(DC.getDCWallet(), wallet + wager * evenOddMultiplier);
        } else {
            assertEq(DC.getDCWallet(), wallet - wager);
        }
    }

    function testRandNonce() public {
        uint256 r1 = DC.randNonce();
        DC._generateRandRoll();
        uint256 r2 = DC.randNonce();
        assertEq(r1 + 1, r2);
    }

    function testPlaceExactWager() public {
        DC.buyIn();

        uint256 exactMultiplier = DC._payoutExact();
        uint256 wallet = DC.getDCWallet();

        uint256 wager = 1;
        uint256 guess = 5;

        console.log("Sender balance (pre-wager):", DC.getDCWallet());
        uint256 roll = DC.placeWager(wager, guess);
        console.log("Sender balance (post-wager):", DC.getDCWallet());
        if (roll == guess) {
            assertEq(DC.getDCWallet(), wallet + wager * exactMultiplier);
        } else {
            assertEq(DC.getDCWallet(), wallet - wager);
        }
    }
}
