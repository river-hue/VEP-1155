import { toNano, zeroAddress } from "locklift";
import { Account } from "everscale-standalone-client/nodejs";
import {
    Actors,
    AnyMultiTokenCollectionContract,
    AnyMultiTokenWalletContract,
    Collections,
    Contracts,
    Indexes,
    MultiTokens
} from "./helpers";
import BigNumber from "bignumber.js";
import { expect } from "chai";

describe("Test indexes", async function () {
    const testIndexes = async (
        collection: AnyMultiTokenCollectionContract,
        owner: Account,
        wallet: AnyMultiTokenWalletContract
    ) => {
        const byOwnerAddress = (await wallet.methods.resolveIndex({
            answerId: 0,
            collection: zeroAddress,
            owner: owner.address
        }).call()).index;

        const byOwnerAndCollectionAddress = (await wallet.methods.resolveIndex({
            answerId: 0,
            collection: collection.address,
            owner: owner.address
        }).call()).index;

        expect(byOwnerAddress.equals(byOwnerAndCollectionAddress)).to.be.false;

        Contracts.checkExists(byOwnerAddress, true);
        Contracts.checkExists(byOwnerAndCollectionAddress, true);

        const expectedInfo = {
            collection: collection.address,
            owner: owner.address,
            nft: wallet.address
        };

        const byOwner = Indexes.attachDeployed(byOwnerAddress);
        await Indexes.checkInfo(byOwner, expectedInfo);

        const byOwnerAndCollection = Indexes.attachDeployed(byOwnerAndCollectionAddress);
        await Indexes.checkInfo(byOwnerAndCollection, expectedInfo);
    }

    it("Index contracts of initial wallet", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        
        await testIndexes(collection, owner, wallet);
    });

    it("Index contracts of secondary wallet", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        
        await wallet.methods.transfer({
            count: 50,
            recipient: receiver.address,
            deployTokenWalletValue: toNano(1),
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        const receiverWalletAddress = await Collections.multiTokenWalletAddress(collection, id, receiver.address);
        const receiverWallet = MultiTokens.attachDeployedWithRoyalty(receiverWalletAddress);

        await testIndexes(collection, receiver, receiverWallet);
    });

    it("Search by code hash", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');

        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        const { wallet: otherWallet, id: otherId } = await Collections.mintTokenWithRoyalty(collection, owner, 100);
        
        await wallet.methods.transfer({
            count: 50,
            recipient: receiver.address,
            deployTokenWalletValue: toNano(1),
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });
        const receiverWalletAddress = await Collections.multiTokenWalletAddress(collection, id, receiver.address);

        const { codeHash } = await collection.methods.multiTokenCodeHash({ answerId: 0 }).call();
        const { accounts } = await locklift.provider.getAccountsByCodeHash({ codeHash: new BigNumber(codeHash).toString(16) });
        expect(accounts.length).to.be.eq(3);

        const foundAddresses = accounts.map(item => item.toString());
        expect(foundAddresses.indexOf(wallet.address.toString()) >= 0).to.be.true;
        expect(foundAddresses.indexOf(receiverWalletAddress.toString()) >= 0).to.be.true;
        expect(foundAddresses.indexOf(otherWallet.address.toString()) >= 0).to.be.true;
    });
});
