import { toNano, zeroAddress } from "locklift";
import { Actors, Collections, Contracts, MultiTokens } from "./helpers";
import { expect } from "chai"

describe("Test multi token resalting", async function () {

    it("Salt with Zero with zero balance on burn", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const TOTAL = 100;

        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        const salted = await Contracts.getCodeHash(wallet.address)

        await wallet.methods.burn({
            count: TOTAL,
            remainingGasTo: owner.address, 
            callbackTo: zeroAddress,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, 0);
        const unsalted = await Contracts.getCodeHash(wallet.address)
        expect(unsalted).to.be.not.eq(salted, "Codehash must have changed")
    });

    it("Unsalt with non zero balance", async function () {
        const TOTAL = 100;
        const TRANSFER_FIRST = 30;

        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('3');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        
        const salted = await Contracts.getCodeHash(wallet.address)

        await wallet.methods.transfer({
            count: TOTAL,
            recipient: receiver.address,
            deployTokenWalletValue: toNano(1),
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        const unsalted = await Contracts.getCodeHash(wallet.address)

        expect(unsalted).to.be.not.eq(salted, "Codehash must have changed")

        const receiverWalletAddress = await Collections.multiTokenWalletAddress(collection, id, receiver.address);
        const receiverWallet = MultiTokens.attachDeployedWithRoyalty(receiverWalletAddress);

        await MultiTokens.checkBalance(wallet, 0);
        await MultiTokens.checkBalance(receiverWallet, TOTAL);
        await MultiTokens.checkInfo(receiverWallet, {
            collection: collection.address,
            id,
            owner: receiver.address
        });

        await receiverWallet.methods.transfer({
            count: TRANSFER_FIRST,
            recipient: owner.address,
            deployTokenWalletValue: 0,
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: receiver.address,
            amount: toNano(2)
        });
        await MultiTokens.checkBalance(wallet, TRANSFER_FIRST);
        await MultiTokens.checkBalance(receiverWallet, TOTAL - TRANSFER_FIRST);

        const saltedAfter = await Contracts.getCodeHash(wallet.address)
        expect(saltedAfter).to.be.eq(salted, "Codehash must have been restored")

    });
});
