import { Address, Contract } from "locklift";
import { FactorySource } from "build/factorySource";
import { expect } from "chai";

export declare type IndexContract = Contract<FactorySource['Index']>;

export class Indexes {
    static attachDeployed(address: Address): IndexContract {
        return locklift.factory.getDeployedContract(
            'Index',
            address
        );
    }

    static async getInfo(contract: IndexContract): Promise<{
        collection: Address;
        owner: Address;
        nft: Address;
    }> {
        return contract.methods.getInfo({ answerId:  0 }).call();
    }

    static async checkInfo(
        contract: IndexContract,
        expected: {
            collection?: Address;
            owner?: Address;
            nft?: Address;
        }
    ) {
        const actual = await Indexes.getInfo(contract);
        if (expected.collection !== undefined) {
            expect(actual.collection.toString()).to.be.eq(
                expected.collection.toString(),
                "Wrong index collection"
            );
        }
        if (expected.owner !== undefined) {
            expect(actual.owner.toString()).to.be.eq(
                expected.owner.toString(),
                "Wrong index owner"
            );
        }
        if (expected.nft !== undefined) {
            expect(actual.nft.toString()).to.be.eq(
                expected.nft.toString(),
                "Wrong index token address"
            );
        }
    }
}