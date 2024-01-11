// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {HorseStore} from "../src/HorseStore.sol";
import {Test, console2, StdInvariant} from "forge-std/Test.sol";

abstract contract Base_Test is StdInvariant, Test {
    HorseStore horseStore;
    address user = makeAddr("user");
    string public constant NFT_NAME = "HorseStore";
    string public constant NFT_SYMBOL = "HS";

    function setUp() public virtual {
        horseStore = new HorseStore();
    }

    function testName() public {
        string memory name = horseStore.name();
        assertEq(name, NFT_NAME);
    }

    function testMintingHorseAssignsOwner(address randomOwner) public {
        vm.assume(randomOwner != address(0));
        vm.assume(!_isContract(randomOwner));

        uint256 horseId = horseStore.totalSupply();
        vm.prank(randomOwner);
        horseStore.mintHorse();
        assertEq(horseStore.ownerOf(horseId), randomOwner);
    }

    function testFeedingHorseUpdatesTimestamps() public {
        uint256 horseId = horseStore.totalSupply();
        vm.warp(10);
        vm.roll(10);
        vm.prank(user);
        horseStore.mintHorse();

        uint256 lastFedTimeStamp = block.timestamp;
        horseStore.feedHorse(horseId);

        assertEq(horseStore.horseIdToFedTimeStamp(horseId), lastFedTimeStamp);
    }

    function testFeedingMakesHappyHorse() public {
        uint256 horseId = horseStore.totalSupply();
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.prank(user);
        horseStore.mintHorse();
        horseStore.feedHorse(horseId);
        assertEq(horseStore.isHappyHorse(horseId), true);
    }

    function testNotFeedingMakesUnhappyHorse() public {
        uint256 horseId = horseStore.totalSupply();
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.prank(user);
        horseStore.mintHorse();
        assertEq(horseStore.isHappyHorse(horseId), false);
    }
    // Horses must be able to be fed at all times

    function statefulFuzz_HorsesAreAbleToBeFedAlways() public {
        uint256 horseId = horseStore.totalSupply();
        console2.log("horseId", horseId);
        vm.prank(user);
        horseStore.mintHorse();
        console2.log("horseId", horseId);
        horseStore.isHappyHorse(horseId);

        // e vm.warp(1641070800)  Sets block.timestamp. -> emit log_uint(block.timestamp); // 1641070800
        // emit log_uint(block.timestamp); // 1641070800
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());

        horseStore.feedHorse(horseId);
        assertEq(horseStore.isHappyHorse(horseId), true);
    }

    function test_HorsesAreAbleToBeFedAlways() public {
        uint256 horseId = horseStore.totalSupply(); // 0
        console2.log("horseId", horseId); // horseId is 0
        vm.prank(user);
        horseStore.mintHorse(); // this is the first horse an has tokenId 0
        horseId = horseStore.totalSupply(); // Update horseId after minting
        console2.log("horseId", horseId); // indeed logs 1

        // Check if the horse has never been fed
        bool isHappyBeforeFeeding = horseStore.isHappyHorse(horseId);
        console2.log("isHappyBeforeFeeding", isHappyBeforeFeeding);
        assertEq(isHappyBeforeFeeding, false);

        // bool isHappy = horseStore.isHappyHorse(horseId); // arithemetic error?
        // console2.log("isHappy", isHappy);

        // vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        // vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());

        // horseStore.feedHorse(horseId);
        // assertEq(horseStore.isHappyHorse(horseId), true);
    }

    function testMintedHorseIsNotHappyInitially() public {
        // Mint a horse
        vm.prank(user);
        horseStore.mintHorse();

        // Get the ID of the minted horse
        uint256 horseId = horseStore.totalSupply() - 1; // Assuming totalSupply increments on mint
        horseId = 2;
        console2.log("horseId", horseId);
        // Check that the minted horse is not happy initially
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());

        bool isHappy = horseStore.isHappyHorse(horseId);
        assertEq(isHappy, false);
    }

    function testGetFedTimeStamp() public {
        uint256 horseId = horseStore.totalSupply();
        uint256 fedTimeStamp = horseStore.getLastFedTimeStamp(horseId);
        console2.log("fedTimeStamp", fedTimeStamp); // logs 0
        console2.log("block.timestamp", block.timestamp); // logs 1
        // below calculation is: delta = 1 - 86400 = -86399
        int256 delta = int256(block.timestamp) - int256(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        console2.log("delta", delta); // logs  -86399
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // Borrowed from an Old Openzeppelin codebase
    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
