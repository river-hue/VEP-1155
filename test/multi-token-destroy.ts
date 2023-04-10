import { toNano, zeroAddress } from "locklift";
import { Actors, Collections, Contracts, MultiTokens } from "./helpers";

describe("Test multi token destroying", async function () {
    it("Destroy with non zero balance", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const TOTAL = 100;

        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        await wallet.methods.destroy({
            remainingGasTo: owner.address, 
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await Contracts.checkExists(wallet.address, true);
        await MultiTokens.checkBalance(wallet, TOTAL);
    });

    it("Destroy with zero balance", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const TOTAL = 100;

        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        await wallet.methods.burn({
            count: TOTAL,
            remainingGasTo: owner.address, 
            callbackTo: zeroAddress,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await wallet.methods.destroy({
            remainingGasTo: owner.address, 
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await Contracts.checkExists(wallet.address, false);
    });
});
