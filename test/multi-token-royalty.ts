import { Address } from "locklift";
import { Actors, Collections, calculateRoyaltyAmount } from "./helpers";
import { expect } from "chai";

describe("Test multi token royalty", async function () {
    it("royaltyInfo calculation", async function () {
        const { account: owner, signer } = await Actors.deploy();
        const collection = await Collections.deployWithRoyalty(owner.address, signer.publicKey);

        const ROAYLTY = 170_000; //17%
        const ROAYLTY_ADDRESS = new Address('0:ece57bcc6c530283becbbd8a3b24d3c5987cdddc3c8b7b33be6e4a6312490415'); //some
        const SALE_PRICE = 3_000_000_000;

        const { wallet } = await Collections.mintTokenWithRoyalty(
            collection,
            owner,
            100,
            {
                royalty: ROAYLTY,
                royaltyAddress: ROAYLTY_ADDRESS
            }
        );
        const actual = await wallet.methods.royaltyInfo({ answerId: 0, salePrice: SALE_PRICE }).call();

        expect(Number(actual.royaltyAmount)).to.be.eq(calculateRoyaltyAmount(SALE_PRICE, ROAYLTY));
        expect(actual.receiver.equals(ROAYLTY_ADDRESS)).to.be.true;
    });
});