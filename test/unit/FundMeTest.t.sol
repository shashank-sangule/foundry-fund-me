// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant AMOUNT = 1 ether;
    uint256 constant START_BAL = 100 ether;
    uint256 constant TX_GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, START_BAL);
    }
    
    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: AMOUNT}();
        vm.stopPrank();
        uint256 amountFunded = fundMe.getAmountFunded(USER);
        assertEq(amountFunded, AMOUNT);
    }
    
    function testAddsFundersToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: AMOUNT}();
        vm.stopPrank();
        
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: AMOUNT}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(address(3));
        fundMe.withdraw();
    }

    function testWithdrawWithSingleOwner() public funded {
        // Arrange
        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialContractBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalContractBalance = address(fundMe).balance;

        assertEq(finalContractBalance, 0);
        assertEq(finalOwnerBalance, initialOwnerBalance + initialContractBalance);
    }

    function testWithdrawWithMultipleOwners() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndexOfFunders = 1;

        for (uint160 i = startingIndexOfFunders; i < numberOfFunders; i++) {
            hoax(address(i), START_BAL);
            fundMe.fund{value: AMOUNT}();
        }

        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialContractBalance = address(fundMe).balance;

        vm.txGasPrice(TX_GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalContractBalance = address(fundMe).balance;

        assertEq(finalContractBalance, 0);
        assertEq(finalOwnerBalance, initialOwnerBalance + initialContractBalance);
    }

    function testWithdrawWithMultipleOwnersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndexOfFunders = 1;

        for (uint160 i = startingIndexOfFunders; i < numberOfFunders; i++) {
            hoax(address(i), START_BAL);
            fundMe.fund{value: AMOUNT}();
        }

        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialContractBalance = address(fundMe).balance;

        vm.txGasPrice(TX_GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalContractBalance = address(fundMe).balance;

        assertEq(finalContractBalance, 0);
        assertEq(finalOwnerBalance, initialOwnerBalance + initialContractBalance);
    }

}
