// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    // Voting round state variables
    struct VotingRound {
        string voteId;
        bytes snapshotPublicKey;
        string metadataIpfsCid;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        uint256 voterCount;
        uint256 nftAssetId;
        bool isBootstrapped;
        bool isClosed;
        uint256[] optionCounts;
        mapping(address => bool) hasVoted;
        mapping(uint256 => uint256) tallies; // Maps option index to votes
    }

    mapping(string => VotingRound) public votingRounds;
    address public creator;

    // Constants
    uint256 public constant BOX_FLAT_MIN_BALANCE = 2500;
    uint256 public constant BOX_BYTE_MIN_BALANCE = 400;
    uint256 public constant ASSET_MIN_BALANCE = 100000;

    // Modifier to restrict actions to the creator
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this");
        _;
    }

    constructor() {
        creator = msg.sender;
    }

    // Create a new voting round
    function createVotingRound(
        string memory voteId,
        bytes memory snapshotPublicKey,
        string memory metadataIpfsCid,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory optionCounts,
        uint256 quorum
    ) external onlyCreator {
        require(startTime < endTime, "End time must be after start time");
        require(endTime > block.timestamp, "End time must be in the future");
        require(votingRounds[voteId].startTime == 0, "Voting round already exists");

        // Initialize the voting round
        VotingRound storage round = votingRounds[voteId];
        round.voteId = voteId;
        round.snapshotPublicKey = snapshotPublicKey;
        round.metadataIpfsCid = metadataIpfsCid;
        round.startTime = startTime;
        round.endTime = endTime;
        round.quorum = quorum;
        round.optionCounts = optionCounts;
        round.voterCount = 0;
        round.isBootstrapped = false;
        round.isClosed = false;
    }

    // Bootstrap the voting round
    function bootstrapVotingRound(string memory voteId) external payable {
        VotingRound storage round = votingRounds[voteId];
        require(!round.isBootstrapped, "Voting round already bootstrapped");
        require(round.startTime > 0, "Voting round does not exist");

        // Calculate the minimum balance requirement
        uint256 totalOptions = 0;
        for (uint256 i = 0; i < round.optionCounts.length; i++) {
            totalOptions += round.optionCounts[i];
        }
        uint256 tallyBoxSize = totalOptions * 8; // Each tally is 8 bytes
        uint256 minBalanceReq = (ASSET_MIN_BALANCE * 2) + 1000 + BOX_FLAT_MIN_BALANCE + (tallyBoxSize * BOX_BYTE_MIN_BALANCE);
        require(msg.value == minBalanceReq, "Insufficient bootstrap payment");

        round.isBootstrapped = true;
    }

    // Vote in the voting round
    function vote(
        string memory voteId,
        uint256[] memory answerIds
    ) external {
        VotingRound storage round = votingRounds[voteId];
        require(round.isBootstrapped, "Voting round not bootstrapped");
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Voting not open");
        require(!round.hasVoted[msg.sender], "Already voted");
        require(answerIds.length == round.optionCounts.length, "Invalid number of answers");

        // Record the votes
        for (uint256 i = 0; i < answerIds.length; i++) {
            require(answerIds[i] < round.optionCounts[i], "Invalid vote option");
            round.tallies[i] += 1;
        }

        round.hasVoted[msg.sender] = true;
        round.voterCount += 1;
    }

    // Close the voting round
    function closeVotingRound(string memory voteId) external onlyCreator {
        VotingRound storage round = votingRounds[voteId];
        require(round.isBootstrapped, "Voting round not bootstrapped");
        require(!round.isClosed, "Voting round already closed");
        require(block.timestamp > round.endTime, "Voting round not ended");

        round.isClosed = true;

        // Generate the NFT metadata
        string memory metadata = string(
            abi.encodePacked(
                '{"standard":"arc69","description":"This is a voting result NFT for voting round with ID ',
                round.voteId,
                '.","properties":{"metadata":"ipfs://',
                round.metadataIpfsCid,
                '","id":"',
                round.voteId,
                '","quorum":',
                uintToString(round.quorum),
                ',"voterCount":',
                uintToString(round.voterCount),
                ',"tallies":['
            )
        );

        for (uint256 i = 0; i < round.optionCounts.length; i++) {
            if (i > 0) {
                metadata = string(abi.encodePacked(metadata, ","));
            }
            metadata = string(abi.encodePacked(metadata, uintToString(round.tallies[i])));
        }

        metadata = string(abi.encodePacked(metadata, "]}}"));

        // Mint the NFT
        round.nftAssetId = uint256(keccak256(abi.encodePacked(metadata)));
    }

    // Helper function to convert uint to string
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




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    struct VotingRound {
        string voteId;
        bytes snapshotPublicKey;
        string metadataIpfsCid;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        uint256 voterCount;
        uint256 nftAssetId;
        bool isBootstrapped;
        bool isClosed;
        uint256[] optionCounts;
        mapping(address => bool) hasVoted;
        mapping(uint256 => uint256) tallies;
    }

    mapping(string => VotingRound) public votingRounds;
    address public creator;

    uint256 public constant BOX_FLAT_MIN_BALANCE = 2500;
    uint256 public constant BOX_BYTE_MIN_BALANCE = 400;
    uint256 public constant ASSET_MIN_BALANCE = 100000;

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this");
        _;
    }

    constructor() {
        creator = msg.sender;
    }

    function createVotingRound(
        string memory voteId,
        bytes memory snapshotPublicKey,
        string memory metadataIpfsCid,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory optionCounts,
        uint256 quorum
    ) external onlyCreator {
        require(startTime < endTime, "End time must be after start time");
        require(endTime > block.timestamp, "End time must be in the future");
        require(votingRounds[voteId].startTime == 0, "Voting round already exists");

        VotingRound storage round = votingRounds[voteId];
        round.voteId = voteId;
        round.snapshotPublicKey = snapshotPublicKey;
        round.metadataIpfsCid = metadataIpfsCid;
        round.startTime = startTime;
        round.endTime = endTime;
        round.quorum = quorum;
        round.optionCounts = optionCounts;
        round.voterCount = 0;
        round.isBootstrapped = false;
        round.isClosed = false;
    }

    function bootstrapVotingRound(string memory voteId) external payable {
        VotingRound storage round = votingRounds[voteId];
        require(!round.isBootstrapped, "Voting round already bootstrapped");
        require(round.startTime > 0, "Voting round does not exist");

        uint256 totalOptions = 0;
        for (uint256 i = 0; i < round.optionCounts.length; i++) {
            totalOptions += round.optionCounts[i];
        }
        uint256 tallyBoxSize = totalOptions * 8;
        uint256 minBalanceReq = (ASSET_MIN_BALANCE * 2) + 1000 + BOX_FLAT_MIN_BALANCE + (tallyBoxSize * BOX_BYTE_MIN_BALANCE);
        require(msg.value == minBalanceReq, "Insufficient bootstrap payment");

        round.isBootstrapped = true;
    }

    function vote(
        string memory voteId,
        uint256[] memory answerIds
    ) external {
        VotingRound storage round = votingRounds[voteId];
        require(round.isBootstrapped, "Voting round not bootstrapped");
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Voting not open");
        require(!round.hasVoted[msg.sender], "Already voted");
        require(answerIds.length == round.optionCounts.length, "Invalid number of answers");

        for (uint256 i = 0; i < answerIds.length; i++) {
            require(answerIds[i] < round.optionCounts[i], "Invalid vote option");
            round.tallies[i] += 1;
        }

        round.hasVoted[msg.sender] = true;
        round.voterCount += 1;
    }

    function closeVotingRound(string memory voteId) external onlyCreator {
        VotingRound storage round = votingRounds[voteId];
        require(round.isBootstrapped, "Voting round not bootstrapped");
        require(!round.isClosed, "Voting round already closed");
        require(block.timestamp > round.endTime, "Voting round not ended");

        round.isClosed = true;

        string memory metadata = string(
            abi.encodePacked(
                '{"standard":"arc69","description":"This is a voting result NFT for voting round with ID ',
                round.voteId,
                '.","properties":{"metadata":"ipfs://',
                round.metadataIpfsCid,
                '","id":"',
                round.voteId,
                '","quorum":',
                uintToString(round.quorum),
                ',"voterCount":',
                uintToString(round.voterCount),
                ',"tallies":['
            )
        );

        for (uint256 i = 0; i < round.optionCounts.length; i++) {
            if (i > 0) {
                metadata = string(abi.encodePacked(metadata, ","));
            }
            metadata = string(abi.encodePacked(metadata, uintToString(round.tallies[i])));
        }

        metadata = string(abi.encodePacked(metadata, "]}}"));

        round.nftAssetId = uint256(keccak256(abi.encodePacked(metadata)));
    }

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
