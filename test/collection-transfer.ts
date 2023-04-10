import { toNano } from "locklift";
import { Actors, Collections, Contracts } from "./helpers";
import { expect } from "chai";

describe("Test collection transferring", async function () {
    it("transferOwnership", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const { account: newOwner } = await Actors.deploy('1');
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const { traceTree } = await locklift.tracing.trace(collection.methods.transferOwnership({
            newOwner: newOwner.address
        }).send({
            from: owner.address,
            amount: toNano(2)
        }));

        const event = Contracts.getFirstEvent(traceTree, collection, 'OwnershipTransferred');
        expect(event.oldOwner.equals(owner.address)).to.be.true;
        expect(event.newOwner.equals(newOwner.address)).to.be.true;

        Collections.checkOwner(collection, newOwner.address);
    });
});
