// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingRoundApp {
    struct VotingPreconditions {
        bool isVotingOpen;
        bool isAllowedToVote;
        bool hasAlreadyVoted;
        uint256 currentTime;
    }

    // State variables
    uint256 public voterCount;
    uint256 public closeTime;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public quorum;
    string public voteId;
    string public metadataIpfsCid;
    string public nftImageUrl;

    bool public isBootstrapped;
    uint256 public totalOptions;
    address public snapshotPublicKey;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256[]) public votesByAccount;
    mapping(uint256 => uint256) public voteTallies;

    event VoteCast(address voter, uint256[] answerIds);
    event VotingClosed(uint256 voterCount, uint256[] tallies);
    event Bootstrapped(uint256 requiredBalance);

    modifier onlyDuringVoting() {
        require(isBootstrapped, "Voting not bootstrapped");
        require(block.timestamp >= startTime, "Voting has not started");
        require(block.timestamp <= endTime, "Voting has ended");
        _;
    }

    modifier onlyAfterVoting() {
        require(closeTime > 0, "Voting is still open");
        _;
    }

    function create(
        string memory _voteId,
        address _snapshotPublicKey,
        string memory _metadataIpfsCid,
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _optionCounts,
        uint256 _quorum,
        string memory _nftImageUrl
    ) external {
        require(_startTime < _endTime, "End time should be after start time");
        require(_endTime > block.timestamp, "End time must be in the future");

        voteId = _voteId;
        snapshotPublicKey = _snapshotPublicKey;
        metadataIpfsCid = _metadataIpfsCid;
        startTime = _startTime;
        endTime = _endTime;
        quorum = _quorum;
        nftImageUrl = _nftImageUrl;

        totalOptions = 0;
        for (uint256 i = 0; i < _optionCounts.length; i++) {
            totalOptions += _optionCounts[i];
        }

        require(totalOptions <= 128, "Can't have more than 128 vote options");
    }

    function bootstrap(uint256 requiredBalance) external payable {
        require(!isBootstrapped, "Already bootstrapped");
        require(msg.value == requiredBalance, "Incorrect balance sent");

        isBootstrapped = true;

        emit Bootstrapped(requiredBalance);
    }

    function vote(uint256[] memory answerIds) external onlyDuringVoting {
        require(!hasVoted[msg.sender], "Already voted");
        require(answerIds.length == totalOptions, "Invalid number of answers");

        for (uint256 i = 0; i < answerIds.length; i++) {
            voteTallies[i] += 1;
        }

        hasVoted[msg.sender] = true;
        votesByAccount[msg.sender] = answerIds;
        voterCount++;

        emit VoteCast(msg.sender, answerIds);
    }

    function close() external onlyDuringVoting {
        closeTime = block.timestamp;

        uint256[] memory tallies = new uint256[](totalOptions);
        for (uint256 i = 0; i < totalOptions; i++) {
            tallies[i] = voteTallies[i];
        }

        emit VotingClosed(voterCount, tallies);

        // Create an NFT for results (if supported by an external system)
        // Not directly feasible in Solidity alone
    }

    function getPreconditions(address voter) external view returns (VotingPreconditions memory) {
        return VotingPreconditions({
            isVotingOpen: block.timestamp >= startTime && block.timestamp <= endTime && isBootstrapped,
            isAllowedToVote: !hasVoted[voter],
            hasAlreadyVoted: hasVoted[voter],
            currentTime: block.timestamp
        });
    }
}



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingRoundApp {
    struct VotingPreconditions {
        bool isVotingOpen;
        bool isAllowedToVote;
        bool hasAlreadyVoted;
        uint256 currentTime;
    }

    uint256 public voterCount;
    uint256 public closeTime;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public quorum;
    string public voteId;
    string public metadataIpfsCid;
    string public nftImageUrl;

    bool public isBootstrapped;
    uint256 public totalOptions;
    address public snapshotPublicKey;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256[]) public votesByAccount;
    mapping(uint256 => uint256) public voteTallies;

    event VoteCast(address voter, uint256[] answerIds);
    event VotingClosed(uint256 voterCount, uint256[] tallies);
    event Bootstrapped(uint256 requiredBalance);

    modifier onlyDuringVoting() {
        require(isBootstrapped, "Voting not bootstrapped");
        require(block.timestamp >= startTime, "Voting has not started");
        require(block.timestamp <= endTime, "Voting has ended");
        _;
    }

    modifier onlyAfterVoting() {
        require(closeTime > 0, "Voting is still open");
        _;
    }

    function create(
        string memory _voteId,
        address _snapshotPublicKey,
        string memory _metadataIpfsCid,
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _optionCounts,
        uint256 _quorum,
        string memory _nftImageUrl
    ) external {
        require(_startTime < _endTime, "End time should be after start time");
        require(_endTime > block.timestamp, "End time must be in the future");

        voteId = _voteId;
        snapshotPublicKey = _snapshotPublicKey;
        metadataIpfsCid = _metadataIpfsCid;
        startTime = _startTime;
        endTime = _endTime;
        quorum = _quorum;
        nftImageUrl = _nftImageUrl;

        totalOptions = 0;
        for (uint256 i = 0; i < _optionCounts.length; i++) {
            totalOptions += _optionCounts[i];
        }

        require(totalOptions <= 128, "Can't have more than 128 vote options");
    }

    function bootstrap(uint256 requiredBalance) external payable {
        require(!isBootstrapped, "Already bootstrapped");
        require(msg.value == requiredBalance, "Incorrect balance sent");

        isBootstrapped = true;

        emit Bootstrapped(requiredBalance);
    }

    function vote(uint256[] memory answerIds) external onlyDuringVoting {
        require(!hasVoted[msg.sender], "Already voted");
        require(answerIds.length == totalOptions, "Invalid number of answers");

        for (uint256 i = 0; i < answerIds.length; i++) {
            voteTallies[i] += 1;
        }

        hasVoted[msg.sender] = true;
        votesByAccount[msg.sender] = answerIds;
        voterCount++;

        emit VoteCast(msg.sender, answerIds);
    }

    function close() external onlyDuringVoting {
        closeTime = block.timestamp;

        uint256[] memory tallies = new uint256[](totalOptions);
        for (uint256 i = 0; i < totalOptions; i++) {
            tallies[i] = voteTallies[i];
        }

        emit VotingClosed(voterCount, tallies);
    }

    function getPreconditions(address voter) external view returns (VotingPreconditions memory) {
        return VotingPreconditions({
            isVotingOpen: block.timestamp >= startTime && block.timestamp <= endTime && isBootstrapped,
            isAllowedToVote: !hasVoted[voter],
            hasAlreadyVoted: hasVoted[voter],
            currentTime: block.timestamp
        });
    }
}
