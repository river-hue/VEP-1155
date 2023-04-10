import { Actors, Collections } from "./helpers";
import { expect } from "chai";

describe("Test minting", async function () {
    it("Deploy collection and mint NFT", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deploy(owner.address, signer.publicKey);

        const { id: firstId } = await Collections.mintNFT(collection, owner);
        await Collections.checkTotalSupply(collection, 1);

        const { id: secondId } = await Collections.mintNFT(collection, owner);
        await Collections.checkTotalSupply(collection, 2);

        expect(firstId).to.be.not.eq(secondId);
    });

    it("Deploy collection and mint token", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deploy(owner.address, signer.publicKey);

        const { id: firstId } = await Collections.mintToken(collection, owner, 100);
        await Collections.checkTotalSupply(collection, 1);
        await Collections.checkTotalMultiTokenSupply(collection, firstId, 100);

        const { id: secondId } = await Collections.mintToken(collection, owner, 200);
        await Collections.checkTotalSupply(collection, 2);
        await Collections.checkTotalMultiTokenSupply(collection, secondId, 200);

        expect(firstId).to.be.not.eq(secondId);
    });

    it("Deploy collection with royalty support and mint NFT", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const { id: firstId } = await Collections.mintNFTWithRoyalty(collection, owner);
        await Collections.checkTotalSupply(collection, 1);

        const { id: secondId } = await Collections.mintNFTWithRoyalty(collection, owner);
        await Collections.checkTotalSupply(collection, 2);  
        
        expect(firstId).to.be.not.eq(secondId);
    });

    it("Deploy collection with royalty support and mint token", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const { id: firstId } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        await Collections.checkTotalSupply(collection, 1);
        await Collections.checkTotalMultiTokenSupply(collection, firstId, 100);

        const { id: secondId } = await Collections.mintTokenWithRoyalty(collection, owner, 200);
        await Collections.checkTotalSupply(collection, 2);
        await Collections.checkTotalMultiTokenSupply(collection, secondId, 200);

        expect(firstId).to.be.not.eq(secondId);
    });
});
