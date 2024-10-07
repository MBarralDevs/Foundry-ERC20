// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public token;
    DeployOurToken public deployer;

    address public martin;
    address public nicole;

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places

    function setUp() public {
        deployer = new DeployOurToken();
        token = deployer.run();

        martin = makeAddr("bob");
        nicole = makeAddr("alice");

        vm.prank(msg.sender);
        token.transfer(martin, STARTING_BALANCE);
    }

    // Test for initial total supply
    function testInitialSupply() public view {
        assertEq(token.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        //Martin approves Nicole to spend tokens on her behalf
        vm.prank(martin);
        token.approve(nicole, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(nicole);
        token.transferFrom(martin, nicole, transferAmount);

        assertEq(token.balanceOf(nicole), transferAmount);
        assertEq(token.balanceOf(martin), STARTING_BALANCE - transferAmount);
    }

    // Test that transferFrom fails without sufficient allowance
    function testTransferFromFailsWithoutSufficientAllowance() public {
        uint256 allowanceAmount = 1000;
        uint256 transferAmount = 1500;

        // Owner approves user1 to spend only a limited amount
        vm.prank(martin);
        token.approve(nicole, allowanceAmount);

        vm.prank(martin);
        vm.expectRevert();
        token.transferFrom(martin, nicole, transferAmount);
    }

    // Test for allowance updates after approval
    function testAllowance() public {
        uint256 approveAmount = 2000;

        // Approve user1 to spend tokens on owner's behalf
        token.approve(martin, approveAmount);

        // Check that allowance is set correctly
        assertEq(token.allowance(address(this), martin), approveAmount);

        // Increase allowance
        uint256 newAllowance = 3000;
        token.approve(martin, newAllowance);

        assertEq(token.allowance(address(this), martin), newAllowance);
    }

    // Test transfer reverts if sender doesn't have enough balance
    function testTransferFailsWhenInsufficientBalance() public {
        uint256 transferAmount = deployer.INITIAL_SUPPLY() + 1;

        // Attempt to transfer more than available balance
        vm.expectRevert();
        token.transfer(martin, transferAmount);
    }
}
