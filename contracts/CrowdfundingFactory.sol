// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Crowdfunding} from "./Crowdfunding.sol";

contract CrowdfundingFactory {
    address public owner;
    bool public paused;

    struct Campaign {
        address campaignAddress;
        address owner;
        string name;
        uint256 creationTime;
    }

    Campaign[] public campaigns;
    mapping(address => Campaign[]) public userCampaigns;

    // Event to notify when a campaign is deleted
    event CampaignDeleted(address campaignAddress, address owner);

    // Event to notify when a campaign is created
    event CampaignCreated(address campaignAddress, address owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Factory is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to create a new campaign
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) external notPaused {
        // Creates a new campaing instance
        Crowdfunding newCampaign = new Crowdfunding(
            msg.sender,
            _name,
            _description,
            _goal,
            _durationInDays
        );

        // Stores the new contract address in the campaignAddress variable
        address campaignAddress = address(newCampaign);

        // Creates a new Campaign struct 
        Campaign memory campaign = Campaign({
            campaignAddress: campaignAddress,
            owner: msg.sender,
            name: _name,
            creationTime: block.timestamp
        });

        // Stores the new campaign to the campaign array 
        campaigns.push(campaign);
        // Store the new campaign to the user campaign map
        userCampaigns[msg.sender].push(campaign);

        // Emit an event when a campaign is created
        emit CampaignCreated(campaignAddress, msg.sender);
    }

    // Get a specific user campaign
    function getUserCampaigns(address _user) external view returns (Campaign[] memory) {
        return userCampaigns[_user];
    }

    // Retrieves all campaigns created 
    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    // Function to pause and un-pause the factory preventing creation of new campaign when paused 
    // and allows creation when unpaused 
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    // Utility function to find a campaign index by address
    function findCampaignIndex(Campaign[] storage campaignList, address _campaignAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < campaignList.length; i++) {
            if (campaignList[i].campaignAddress == _campaignAddress) {
                return i;
            }
        }
        return campaignList.length; // Will return an invalid index if not found
    }

    // Utility function to remove a campaign from an array by index
    function removeCampaignFromCampaignArray(Campaign[] storage campaignList, uint256 index) internal {
        // Remove only the campaign at the given index inside the campaign array
        if (index < campaignList.length - 1) {
            campaignList[index] = campaignList[campaignList.length - 1];
        }
        campaignList.pop();
    }

    // Delete campaign function to delete a specific campaign both from the campaign array and the userCampaign mapping
    function deleteCampaign(address _campaignAddress) external {
        // Locating the campaign in the user's campaigns
        Campaign[] storage userCampaignList = userCampaigns[msg.sender];
        uint256 campaignIndex = findCampaignIndex(userCampaignList, _campaignAddress);
        
        // Essuring that the campaign index is within the campaign array(userCampaignList.length
        require(campaignIndex < userCampaignList.length, "Campaign not found.");
        
        // Only the owner of the campaign can delete it
        require(userCampaignList[campaignIndex].owner == msg.sender, "Only campaign owner can delete a campaign.");

        // Remove campaign from the user's campaign list
        removeCampaignFromCampaignArray(userCampaignList, campaignIndex);

        // Locate the campaign in the global campaigns array
        campaignIndex = findCampaignIndex(campaigns, _campaignAddress);
        
        require(campaignIndex < campaigns.length, "Campaign not found in global campaign array.");
        
        // Remove campaign from the global campaigns array
        removeCampaignFromCampaignArray(campaigns, campaignIndex);

        // Emit an event for the deletion of a campaign
        emit CampaignDeleted(_campaignAddress, msg.sender);
    }

}