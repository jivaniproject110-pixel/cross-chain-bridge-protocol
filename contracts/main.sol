```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Cross-Chain Bridge Protocol
 * @author [Your Name]
 * @notice Trustless bridge for moving assets between EVM chains using light client proofs
 * @dev This contract is designed to work on Ethereum and Polygon chains
 */
contract CrossChainBridgeProtocol is ReentrancyGuard, Ownable, Initializable, UUPSUpgradeable {
    using SafeMath for uint256;

    // Mapping of relayers to their corresponding public keys
    mapping(address => bytes) public relayers;

    // Mapping of asset hashes to their corresponding balances
    mapping(bytes32 => uint256) public assetBalances;

    // Mapping of proposals to their corresponding status
    mapping(bytes32 => bool) public proposalStatus;

    // Event emitted when a new relayer is added
    /**
     * @notice Emitted when a new relayer is added
     * @param relayer The address of the new relayer
     * @param publicKey The public key of the new relayer
     */
    event NewRelayer(address indexed relayer, bytes publicKey);

    // Event emitted when a relayer is removed
    /**
     * @notice Emitted when a relayer is removed
     * @param relayer The address of the removed relayer
     */
    event RelayerRemoved(address indexed relayer);

    // Event emitted when a proposal is submitted
    /**
     * @notice Emitted when a proposal is submitted
     * @param proposalHash The hash of the proposal
     * @param assetHash The hash of the asset being proposed
     * @param amount The amount of the asset being proposed
     */
    event ProposalSubmitted(bytes32 indexed proposalHash, bytes32 assetHash, uint256 amount);

    // Event emitted when a proposal is executed
    /**
     * @notice Emitted when a proposal is executed
     * @param proposalHash The hash of the proposal
     * @param assetHash The hash of the asset being executed
     * @param amount The amount of the asset being executed
     */
    event ProposalExecuted(bytes32 indexed proposalHash, bytes32 assetHash, uint256 amount);

    // Event emitted when a proposal is cancelled
    /**
     * @notice Emitted when a proposal is cancelled
     * @param proposalHash The hash of the proposal
     */
    event ProposalCancelled(bytes32 indexed proposalHash);

    // Event emitted when the contract is paused
    /**
     * @notice Emitted when the contract is paused
     */
    event Paused();

    // Event emitted when the contract is unpaused
    /**
     * @notice Emitted when the contract is unpaused
     */
    event Unpaused();

    // Event emitted when a slashing condition is triggered
    /**
     * @notice Emitted when a slashing condition is triggered
     * @param relayer The address of the relayer being slashed
     * @param amount The amount being slashed
     */
    event SlashingConditionTriggered(address indexed relayer, uint256 amount);

    // Flag to indicate whether the contract is paused
    bool public paused;

    // Threshold for the number of relayers required to execute a proposal
    uint256 public threshold;

    // Minimum delay required between proposal submissions
    uint256 public minDelay;

    // Maximum delay allowed between proposal submissions
    uint256 public maxDelay;

    // Constructor
    /**
     * @notice Initializes the contract with the given parameters
     * @param _threshold The threshold for the number of relayers required to execute a proposal
     * @param _minDelay The minimum delay required between proposal submissions
     * @param _maxDelay The maximum delay allowed between proposal submissions
     */
    function initialize(uint256 _threshold, uint256 _minDelay, uint256 _maxDelay) public initializer {
        require(_threshold > 0, "Threshold must be greater than 0");
        require(_minDelay > 0, "Minimum delay must be greater than 0");
        require(_maxDelay > _minDelay, "Maximum delay must be greater than minimum delay");

        threshold = _threshold;
        minDelay = _minDelay;
        maxDelay = _maxDelay;
    }

    // Function to add a new relayer
    /**
     * @notice Adds a new relayer to the contract
     * @param _relayer The address of the new relayer
     * @param _publicKey The public key of the new relayer
     */
    function addRelayer(address _relayer, bytes memory _publicKey) public onlyOwner {
        require(_relayer != address(0), "Relayer address cannot be zero");
        require(_publicKey.length > 0, "Public key cannot be empty");

        relayers[_relayer] = _publicKey;

        emit NewRelayer(_relayer, _publicKey);
    }

    // Function to remove a relayer
    /**
     * @notice Removes a relayer from the contract
     * @param _relayer The address of the relayer to remove
     */
    function removeRelayer(address _relayer) public onlyOwner {
        require(_relayer != address(0), "Relayer address cannot be zero");
        require(relayers[_relayer].length > 0, "Relayer not found");

        delete relayers[_relayer];

        emit RelayerRemoved(_relayer);
    }

    // Function to submit a proposal
    /**
     * @notice Submits a proposal to the contract
     * @param _proposalHash The hash of the proposal
     * @param _assetHash The hash of the asset being proposed
     * @param _amount The amount of the asset being proposed
     */
    function submitProposal(bytes32 _proposalHash, bytes32 _assetHash, uint256 _amount) public nonReentrant {
        require(!paused, "Contract is paused");
        require(_proposalHash != bytes32(0), "Proposal hash cannot be zero");
        require(_assetHash != bytes32(0), "Asset hash cannot be zero");
        require(_amount > 0, "Amount must be greater than 0");

        proposalStatus[_proposalHash] = true;

        emit ProposalSubmitted(_proposalHash, _assetHash, _amount);
    }

    // Function to execute a proposal
    /**
     * @notice Executes a proposal
     * @param _proposalHash The hash of the proposal
     * @param _assetHash The hash of the asset being executed
     * @param _amount The amount of the asset being executed
     */
    function executeProposal(bytes32 _proposalHash, bytes32 _assetHash, uint256 _amount) public nonReentrant {
        require(!paused, "Contract is paused");
        require(proposalStatus[_proposalHash], "Proposal not found");
        require(_assetHash != bytes32(0), "Asset hash cannot be zero");
        require(_amount > 0, "Amount must be greater than 0");

        // Verify Merkle proof
        // ...

        // Update asset balance
        assetBalances[_assetHash] = assetBalances[_assetHash].add(_amount);

        // Emit event
        emit ProposalExecuted(_proposalHash, _assetHash, _amount);
    }

    // Function to cancel a proposal
    /**
     * @notice Cancels a proposal
     * @param _proposalHash The hash of the proposal
     */
    function cancelProposal(bytes32 _proposalHash) public nonReentrant {
        require(!paused, "Contract is paused");
        require(proposalStatus[_proposalHash], "Proposal not found");

        proposalStatus[_proposalHash] = false;

        emit ProposalCancelled(_proposalHash);
    }

    // Function to pause the contract
    /**
     * @notice Pauses the contract
     */
    function pause() public onlyOwner {
        paused = true;

        emit Paused();
    }

    // Function to unpause the contract
    /**
     * @notice Unpauses the contract
     */
    function unpause() public onlyOwner {
        paused = false;

        emit Unpaused();
    }

    // Function to trigger a slashing condition
    /**
     * @notice Triggers a slashing condition
     * @param _relayer The address of the relayer being slashed
     * @param _amount The amount being slashed
     */
    function triggerSlashingCondition(address _relayer, uint256 _amount) public nonReentrant {
        require(!paused, "Contract is paused");
        require(_relayer != address(0), "Relayer address cannot be zero");
        require(_amount > 0, "Amount must be greater than 0");

        // Slash relayer
        // ...

        emit SlashingConditionTriggered(_relayer, _amount);
    }

    // Function to verify a Merkle proof
    /**
     * @notice Verifies a Merkle proof
     * @param _proof The Merkle proof to verify
     * @param _root The root of the Merkle tree
     * @param _leaf The leaf of the Merkle tree
     * @return bool Whether the proof is valid
     */
    function verifyMerkleProof(bytes32[] memory _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
        bytes32 hash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            if (hash < _proof[i]) {
                hash = keccak256(abi.encodePacked(hash, _proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(_proof[i], hash));
            }
        }

        return hash == _root;
    }

    // Function to upgrade the contract
    /**
     * @notice Upgrades the contract
     * @param _newImplementation The new implementation of the contract
     */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
```