import { toNano } from "locklift";
import { Actors, Collections, Contracts, MultiTokens } from "./helpers";

describe("Test multi token transferring", async function () {
    it("transfer twice", async function () {
        const TOTAL = 100;
        const TRANSFER_FIRST = 70;
        const TRANSFER_SECOND = 29;

        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        
        await wallet.methods.transfer({
            count: TRANSFER_FIRST,
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

        await MultiTokens.checkBalance(wallet, TOTAL - TRANSFER_FIRST);
        await MultiTokens.checkBalance(receiverWallet, TRANSFER_FIRST);
        await MultiTokens.checkInfo(receiverWallet, {
            collection: collection.address,
            id,
            owner: receiver.address
        });

        await wallet.methods.transfer({
            count: TRANSFER_SECOND,
            recipient: receiver.address,
            deployTokenWalletValue: 0,
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, TOTAL - TRANSFER_FIRST - TRANSFER_SECOND);
        await MultiTokens.checkBalance(receiverWallet, TRANSFER_FIRST + TRANSFER_SECOND);
    });

    it("transfer + transferToWallet", async function () {
        const TOTAL = 100;
        const TRANSFER_FIRST = 70;
        const TRANSFER_SECOND = 29;

        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        
        await wallet.methods.transfer({
            count: TRANSFER_FIRST,
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

        await MultiTokens.checkBalance(wallet, TOTAL - TRANSFER_FIRST);
        await MultiTokens.checkBalance(receiverWallet, TRANSFER_FIRST);

        await wallet.methods.transferToWallet({
            count: TRANSFER_SECOND,
            recipientToken: receiverWallet.address,
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, TOTAL - TRANSFER_FIRST - TRANSFER_SECOND);
        await MultiTokens.checkBalance(receiverWallet, TRANSFER_FIRST + TRANSFER_SECOND);
    });

    it("transferToWallet to not a wallet", async function () {
        const TOTAL = 100;
        const TRANSFER = 70;

        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        
        await wallet.methods.transferToWallet({
            count: TRANSFER,
            recipientToken: receiver.address,
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, TOTAL);
    });

    it("transferToWallet to absent wallet", async function () {
        const TOTAL = 100;
        const TRANSFER = 70;

        const { account: owner, signer } = await Actors.deploy();
        const { account: receiver } = await Actors.deploy('1');
       
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);
        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);

        const receiverWalletAddress = await Collections.multiTokenWalletAddress(collection, id, receiver.address);
        await wallet.methods.transferToWallet({
            count: TRANSFER,
            recipientToken: receiverWalletAddress,
            remainingGasTo: owner.address, 
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, TOTAL);
        await Contracts.checkExists(receiverWalletAddress, false);
    });
});
