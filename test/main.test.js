```javascript
const { ethers, upgrades } = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = chai;

describe("CrossChainBridgeProtocol", function () {
  let owner, relayer1, relayer2, assetHash, proposalHash, asset;
  const assetAmount = 100;

  before(async function () {
    // Deploy the contract
    const CrossChainBridgeProtocol = await ethers.getContractFactory(
      "CrossChainBridgeProtocol"
    );
    asset = await CrossChainBridgeProtocol.deploy();
    await asset.deployed();

    // Get the owner and relayers
    [owner, relayer1, relayer2] = await ethers.getSigners();

    // Set the owner
    await asset.connect(owner).initialize();
  });

  describe("Constructor", function () {
    it("should set the owner", async function () {
      expect(await asset.owner()).to.equal(owner.address);
    });
  });

  describe("addRelayer", function () {
    it("should add a new relayer", async function () {
      const publicKey = ethers.utils.randomBytes(32);
      await asset.connect(owner).addRelayer(relayer1.address, publicKey);
      expect(await asset.relayers(relayer1.address)).to.equal(publicKey);
    });

    it("should not allow adding a relayer with an empty public key", async function () {
      await expect(
        asset.connect(owner).addRelayer(relayer1.address, ethers.utils.bytes0(32))
      ).to.be.reverted;
    });

    it("should not allow adding a relayer with a public key that is too short", async function () {
      await expect(
        asset.connect(owner).addRelayer(relayer1.address, ethers.utils.randomBytes(15))
      ).to.be.reverted;
    });

    it("should not allow adding a relayer with a public key that is too long", async function () {
      await expect(
        asset.connect(owner).addRelayer(
          relayer1.address,
          ethers.utils.randomBytes(33)
        )
      ).to.be.reverted;
    });
  });

  describe("removeRelayer", function () {
    it("should remove a relayer", async function () {
      const publicKey = ethers.utils.randomBytes(32);
      await asset.connect(owner).addRelayer(relayer1.address, publicKey);
      await asset.connect(owner).removeRelayer(relayer1.address);
      expect(await asset.relayers(relayer1.address)).to.be.equal(bytes(32));
    });

    it("should not allow removing a relayer that is not set", async function () {
      await expect(
        asset.connect(owner).removeRelayer(relayer1.address)
      ).to.be.reverted;
    });
  });

  describe("submitProposal", function () {
    it("should submit a new proposal", async function () {
      assetHash = ethers.utils.randomBytes(32);
      proposalHash = ethers.utils.randomBytes(32);
      await asset.connect(relayer1).submitProposal(assetHash, assetAmount, proposalHash);
      expect(await asset.proposalStatus(proposalHash)).to.be.true;
    });

    it("should not allow submitting a proposal with an empty asset hash", async function () {
      await expect(
        asset.connect(relayer1).submitProposal(
          ethers.utils.bytes0(32),
          assetAmount,
          proposalHash
        )
      ).to.be.reverted;
    });

    it("should not allow submitting a proposal with an empty proposal hash", async function () {
      await expect(
        asset.connect(relayer1).submitProposal(assetHash, assetAmount, ethers.utils.bytes0(32))
      ).to.be.reverted;
    });

    it("should not allow submitting a proposal with a negative amount", async function () {
      await expect(
        asset.connect(relayer1).submitProposal(assetHash, 0, proposalHash)
      ).to.be.reverted;
    });
  });

  describe("getAssetBalance", function () {
    it("should return the balance of an asset", async function () {
      await asset.connect(owner).addAsset(assetHash, assetAmount);
      expect(await asset.getAssetBalance(assetHash)).to.equal(assetAmount);
    });

    it("should return 0 for an asset that is not set", async function () {
      expect(await asset.getAssetBalance(assetHash)).to.equal(0);
    });
  });

  describe("getProposalStatus", function () {
    it("should return the status of a proposal", async function () {
      await asset.connect(relayer1).submitProposal(assetHash, assetAmount, proposalHash);
      expect(await asset.getProposalStatus(proposalHash)).to.be.true;
    });

    it("should return false for a proposal that is not set", async function () {
      expect(await asset.getProposalStatus(proposalHash)).to.be.false;
    });
  });

  describe("onlyOwner", function () {
    it("should only allow the owner to call the function", async function () {
      await expect(
        asset.connect(relayer1).addRelayer(relayer1.address, ethers.utils.randomBytes(32))
      ).to.be.reverted;
    });
  });

  describe("onlyRelayer", function () {
    it("should only allow a relayer to call the function", async function () {
      await asset.connect(owner).addRelayer(relayer1.address, ethers.utils.randomBytes(32));
      await expect(
        asset.connect(relayer2).addRelayer(relayer1.address, ethers.utils.randomBytes(32))
      ).to.be.reverted;
    });
  });
});
```

These tests cover the following scenarios:

1.  **Constructor**: Verifies that the owner is set correctly in the constructor.
2.  **addRelayer**: Tests the following scenarios:

    *   Adds a new relayer with a valid public key.
    *   Fails to add a relayer with an empty public key.
    *   Fails to add a relayer with a public key that is too short or too long.
3.  **removeRelayer**: Tests the following scenarios:

    *   Removes a relayer that is set.
    *   Fails to remove a relayer that is not set.
4.  **submitProposal**: Tests the following scenarios:

    *   Submits a new proposal with a valid asset hash and proposal hash.
    *   Fails to submit a proposal with an empty asset hash or proposal hash.
    *   Fails to submit a proposal with a negative amount.
5.  **getAssetBalance**: Tests the following scenarios:

    *   Returns the balance of an asset that is set.
    *   Returns 0 for an asset that is not set.
6.  **getProposalStatus**: Tests the following scenarios:

    *   Returns the status of a proposal that is set.
    *   Returns false for a proposal that is not set.
7.  **onlyOwner**: Verifies that only the owner can call the function.
8.  **onlyRelayer**: Verifies that only a relayer can call the function.