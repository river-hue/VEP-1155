import { Actors, Collections, Contracts } from "./helpers";
import BigNumber from "bignumber.js";
import { expect } from "chai";

describe("Test indexes", async function () {
    it("IndexBasis contract", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const indexAddress = (await collection.methods.resolveIndexBasis({ answerId: 0 }).call()).indexBasis;
        const indexContract = locklift.factory.getDeployedContract(
            'IndexBasis',
            indexAddress
        );
        const indexCodeHash = (await indexContract.getFullState()).state.codeHash;
        const expectedCodeHashRaw = (await collection.methods.indexBasisCodeHash({ answerId: 0 }).call()).hash;
        const expectedCodeHash = new BigNumber(expectedCodeHashRaw).toString(16);
        expect(indexCodeHash).to.be.eq(expectedCodeHash);
       
        const { collection: indexCollectionAddress } = await indexContract.methods.getInfo({ answerId: 0 }).call();
        expect(collection.address.equals(indexCollectionAddress)).to.be.true;
    });
});
