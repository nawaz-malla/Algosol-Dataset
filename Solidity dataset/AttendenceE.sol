// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProofOfAttendance is ERC721URIStorage, Ownable {
    uint256 public maxAttendees;
    uint256 public totalAttendees = 0;
    string public assetBaseURI;
    mapping(address => bool) private hasClaimedPOA;

    event AttendanceConfirmed(address indexed attendee, uint256 tokenId);
    event POAClaimed(address indexed attendee, uint256 tokenId);

    constructor(string memory _assetBaseURI, uint256 _maxAttendees) ERC721("ProofOfAttendance", "POA") {
        assetBaseURI = _assetBaseURI;
        maxAttendees = _maxAttendees;
    }

    /**
     * @notice Initialize the max attendees and asset base URI
     */
    function init(uint256 _maxAttendees, string memory _assetBaseURI) external onlyOwner {
        require(totalAttendees == 0, "Already initialized");
        maxAttendees = _maxAttendees;
        assetBaseURI = _assetBaseURI;
    }

    /**
     * @notice Confirm attendance and mint a unique NFT for the attendee
     */
    function confirmAttendance() external {
        require(totalAttendees < maxAttendees, "Max attendees reached");
        require(!hasClaimedPOA[msg.sender], "Already claimed POA");

        uint256 newTokenId = totalAttendees + 1;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(assetBaseURI, uintToString(newTokenId))));

        hasClaimedPOA[msg.sender] = true;
        totalAttendees++;

        emit AttendanceConfirmed(msg.sender, newTokenId);
    }

    /**
     * @notice Claim POA if you have attended
     */
    function claimPOA() external view returns (uint256) {
        require(hasClaimedPOA[msg.sender], "Attendance not confirmed");
        uint256 tokenId = findTokenId(msg.sender);
        emit POAClaimed(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @notice Find the token ID of the attendee
     */
    function findTokenId(address attendee) internal view returns (uint256) {
        for (uint256 i = 1; i <= totalAttendees; i++) {
            if (ownerOf(i) == attendee) {
                return i;
            }
        }
        revert("Token ID not found");
    }

    /**
     * @notice Utility function to convert uint to string
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
