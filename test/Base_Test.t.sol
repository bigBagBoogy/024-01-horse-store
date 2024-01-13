// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {HorseStore} from "../src/HorseStore.sol";
import {Test, console2, StdInvariant} from "forge-std/Test.sol";

abstract contract Base_Test is StdInvariant, Test {
    HorseStore horseStore;
    address user = makeAddr("user");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

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
        vm.warp(100000);
        // vm.roll(100000);
        vm.prank(user);
        horseStore.mintHorse();

        uint256 lastFedTimeStamp = block.timestamp;
        horseStore.feedHorse(horseId);

        assertEq(horseStore.horseIdToFedTimeStamp(horseId), lastFedTimeStamp); // 10
        console2.log("horseStore.horseIdToFedTimeStamp(horseId)", horseStore.horseIdToFedTimeStamp(horseId));
        assert(horseStore.isHappyHorse(horseId) == true);
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
        console2.log("horseId", horseId);

        horseId = 2;
        console2.log("horseId", horseId); // 0
        // Check that the minted horse is not happy initially
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());

        bool isHappy = horseStore.isHappyHorse(horseId);
        assertEq(isHappy, false);
    }

    function testGetFedTimeStamp() public view {
        uint256 horseId = horseStore.totalSupply();
        uint256 fedTimeStamp = horseStore.getLastFedTimeStamp(horseId);
        console2.log("fedTimeStamp", fedTimeStamp); // logs 0
        console2.log("block.timestamp", block.timestamp); // logs 1
        // below calculation is: delta = 1 - 86400 = -86399
        int256 delta = int256(block.timestamp) - int256(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
        console2.log("delta", delta); // logs  -86399
    }

    function testMintingHorseDoesNotAssignOwner(address randomOwner) public {
        vm.prank(user);
        horseStore.mintHorse(); // this is the first horse an has tokenId 0
        vm.assume(randomOwner != address(0));
        vm.assume(!_isContract(randomOwner));

        // totalSupply increments on mint and should now be 1
        uint256 horseId = horseStore.totalSupply();
        console2.log("horseId", horseId);
        vm.prank(randomOwner);
        horseStore.mintHorse();
        assertEq(horseStore.ownerOf(horseId), randomOwner);
        horseId = horseStore.totalSupply();
        console2.log("horseId", horseId);
    }

    function test_canMintTwoHorses() public {
        vm.startPrank(user);
        horseStore.mintHorse(); // horseId 0
        horseStore.mintHorse(); // horseId 1    --  only solidity permits 2nd mint
        vm.stopPrank();
        console2.log("block.timeStamp", block.timestamp);
        vm.warp(1 days);
        vm.roll(1 days);
        console2.log("block.timeStamp", block.timestamp);
        uint256 horseId = horseStore.totalSupply() - 1;
        console2.log("horseId", horseId); // 1
        address owner = horseStore.ownerOf(horseId);
        console2.log("owner", owner);
    }

    function test_aliceFeedsBobsHorse() public {
        vm.prank(alice);
        horseStore.mintHorse(); // horse 0
        vm.prank(bob);
        horseStore.feedHorse(0); // by feeding horse 0, bob claims spot 0 in horseIdToFedTimeStamp array
        vm.warp(1 days);
        vm.roll(1 days);
        uint256 horseId = horseStore.totalSupply() - 1;
        address owner = horseStore.ownerOf(horseId);
        console2.log("owner", owner);
    }

    function test_ownerOfbalanceOfIsHappy() public {
        vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN()); // prevents arithmetic error
        vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN()); // due to lack of initialization

        vm.startPrank(user);
        horseStore.mintHorse(); // horse 0
        console2.log("block.timeStamp", block.timestamp);
        vm.warp(block.timestamp + 100000 seconds); // little over 24 hours
        vm.roll(block.timestamp + 100000 seconds);
        console2.log("block.timeStamp", block.timestamp);
        uint256 horseId = horseStore.totalSupply() - 1; // 0
        horseStore.feedHorse(horseId); // underflows in huff.  why? In this function, we're trying to record the block.timestamp. Maybe if this timestamp is in the past, it will cause an arithmetic error. (be negative)
        horseStore.getLastFedTimeStamp(horseId); // logs 0
        horseStore.isHappyHorse(horseId);
        vm.warp(block.timestamp + 100000 seconds); // little over 24 hours
        vm.roll(block.timestamp + 100000 seconds);
        console2.log("block.timeStamp", block.timestamp);
        horseStore.getLastFedTimeStamp(horseId); // logs 100001
        horseStore.isHappyHorse(horseId);
        vm.warp(block.timestamp + 100000 seconds); // little over 24 hours
        vm.roll(block.timestamp + 100000 seconds);
        console2.log("block.timeStamp", block.timestamp);
        horseStore.getLastFedTimeStamp(horseId); // logs logs 100001
        horseStore.isHappyHorse(horseId);
        vm.warp(block.timestamp + 100000 seconds); // little over 24 hours
        vm.roll(block.timestamp + 100000 seconds);
        console2.log("block.timeStamp", block.timestamp);
        horseStore.getLastFedTimeStamp(horseId); // logs logs 100001
        horseStore.isHappyHorse(horseId);
        horseStore.feedHorse(horseId);
        vm.warp(block.timestamp + 43200 seconds); // 12 hours
        vm.roll(block.timestamp + 43200 seconds);
        console2.log("block.timeStamp", block.timestamp);
        horseStore.getLastFedTimeStamp(horseId); // logs logs 100001
        horseStore.isHappyHorse(horseId);

        // owner = horseStore.ownerOf(horseId);
        // console2.log("owner", owner);
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
