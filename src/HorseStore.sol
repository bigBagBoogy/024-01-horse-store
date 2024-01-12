// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IHorseStore} from "./IHorseStore.sol";

/* 
 * @notice An NFT that represents a horse. Horses should be fed daily to keep happy, ideally several times a day. 
 */
contract HorseStore is IHorseStore, ERC721Enumerable {
    string constant NFT_NAME = "HorseStore";
    string constant NFT_SYMBOL = "HS";
    uint256 public constant HORSE_HAPPY_IF_FED_WITHIN = 1 days;

    // @audit There's no explicit initialization of the horseIdToFedTimeStamp mapping. If the contract starts in a virgin state and the first transaction is a call to feedHorse, it may lead to unexpected behavior since the mapping has not been populated with any horse data.
    mapping(uint256 id => uint256 lastFedTimeStamp) public horseIdToFedTimeStamp;

    constructor() ERC721(NFT_NAME, NFT_SYMBOL) {}

    /*
     * @notice allows anyone to mint their own horse NFT. 
     * e totalSupply() is from ERC721Enumerable and just keeps track.
     * e no timestamp is stored, so after this mint, the new horse will not 
     * yet be in the `horseIdToFedTimeStamp` mapping
     */
    function mintHorse() external {
        _safeMint(msg.sender, totalSupply());
    }

    /* 
     * @param horseId the id of the horse to feed
     * @notice allows anyone to feed anyone else's horse. 
     */
    // @audit Default Value for Non-Existent Horse IDs:
    // The feedHorse function doesn't check whether the specified horseId exists before updating its timestamp in the horseIdToFedTimeStamp mapping. This could lead to unintended behavior where the timestamp is updated for non-existent horses.
    function feedHorse(uint256 horseId) external {
        horseIdToFedTimeStamp[horseId] = block.timestamp;
    }

    /*
     * @param horseId the id of the horse to check
     * @return true if the horse is happy, false otherwise
     * @notice a horse is happy IF it has been fed within the last HORSE_HAPPY_IF_FED_WITHIN seconds
     */
    // @audit if block.timestamp is less than 24h (HORSE_HAPPY_IF_FED_WITHIN),
    // the calculation: `block.timestamp - HORSE_HAPPY_IF_FED_WITHIN` will be negative
    // which will cause an arithmetic error.
    function isHappyHorse(uint256 horseId) external view returns (bool) {
        if (horseIdToFedTimeStamp[horseId] <= block.timestamp - HORSE_HAPPY_IF_FED_WITHIN) {
            //  100    110    - 24
            // so if block.timestamp is 110, then 110 - 24 = 86 and the horse is happy
            // if block.timestamp is 130, then 130 - 24 = 106 and the horse is not happy
            return false;
        }
        return true;
    }
    // @audit temporary helper function:
    // @notice gets the timestamp of the last time the horse was fed

    function getLastFedTimeStamp(uint256 horseId) public view returns (uint256 fedTimeStamp) {
        fedTimeStamp = horseIdToFedTimeStamp[horseId];
        return fedTimeStamp;
    }

    // if 100 < 86 ---- 100 is not less than 86 so return false, horse is not happy
    // if 100 < 106 ---- 100 is less than 106 so return true, horse is happy
    // if 0 < 10 - 24 = -14
}
