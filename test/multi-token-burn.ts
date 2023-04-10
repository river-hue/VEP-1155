import { toNano, zeroAddress } from "locklift";
import { Actors, Collections, Contracts, MultiTokens } from "./helpers";
import { expect } from "chai"

describe("Test multi token burning", async function () {
    it("Burn more than balance", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const TOTAL = 100;

        const { wallet } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        await wallet.methods.burn({
            count: TOTAL + 1,
            remainingGasTo: owner.address, 
            callbackTo: zeroAddress,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        });

        await MultiTokens.checkBalance(wallet, TOTAL);
    });

    it("Burn twice", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const TOTAL = 100;
        const BURN_FIRST = 10;
        const BURN_SECOND = TOTAL - BURN_FIRST;

        const { wallet, id } = await Collections.mintTokenWithRoyalty(collection, owner, TOTAL);
        const burn = async (count: number) => {
            const { traceTree } = await locklift.tracing.trace(wallet.methods.burn({
                count,
                remainingGasTo: owner.address, 
                callbackTo: zeroAddress,
                payload: ''
            }).send({
                from: owner.address,
                amount: toNano(2)
            }));

            const event = Contracts.getFirstEvent(traceTree, collection, 'MultiTokenBurned');
            expect(Number(event.id)).to.be.eq(Number(id));
            expect(Number(event.count)).to.be.eq(Number(count));
            expect(event.owner.equals(owner.address)).to.be.true;
        }

        await burn(BURN_FIRST);
        await MultiTokens.checkBalance(wallet, TOTAL - BURN_FIRST);
        await Collections.checkTotalMultiTokenSupply(collection, id, TOTAL - BURN_FIRST);

        await burn(BURN_SECOND);
        await MultiTokens.checkBalance(wallet, TOTAL - BURN_FIRST - BURN_SECOND);
        await Collections.checkTotalMultiTokenSupply(collection, id, TOTAL - BURN_FIRST - BURN_SECOND);
    });
});
