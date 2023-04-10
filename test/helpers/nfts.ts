
import { Address, Contract } from 'locklift';
import { FactorySource } from 'build/factorySource';
import { calculateRoyalty } from "./royalty";
import { expect } from "chai";

export declare type NftContract = Contract<FactorySource["Nft"]>;
export declare type NftWithRoyaltyContract = Contract<FactorySource["NftWithRoyalty"]>;
export declare type AnyNftContract = NftContract | NftWithRoyaltyContract;

export class Nfts {
    static attachDeployed(address: Address): NftContract {
        return locklift.factory.getDeployedContract(
            'Nft',
            address
        );
    }
    
    static attachDeployedWithRoyalty(address: Address): NftWithRoyaltyContract {
        return locklift.factory.getDeployedContract(
            'NftWithRoyalty',
            address
        );
    }

    static async getInfo(contract: AnyNftContract): Promise<{
        collection: Address;
        id: string;
        owner: Address;
        manager: Address;
    }> {
        return await contract.methods.getInfo({ answerId: 0 }).call();
    }

    static async getJson(contract: AnyNftContract): Promise<string> {
        return (await contract.methods.getJson({ answerId: 0 }).call()).json;
    }

    static async checkInfo(
        contract: AnyNftContract,
        expected: {
            collection?: Address;
            id?: string;
            owner?: Address;
            manager?: Address;
        }
    ) {
        const actual = await Nfts.getInfo(contract);
        if (expected.collection !== undefined) {
            expect(actual.collection.toString()).to.be.eq(
                expected.collection.toString(),
                "Wrong NFT collection"
            );
        }
        if (expected.id !== undefined) {
            expect(actual.id).to.be.eq(expected.id, "Wrong NFT id");
        }
        if (expected.owner !== undefined) {
            expect(actual.owner.toString()).to.be.eq(
                expected.owner.toString(),
                "Wrong NFT owner"
            );
        }
        if (expected.manager !== undefined) {
            expect(actual.manager.toString()).to.be.eq(
                expected.manager.toString(),
                "Wrong NFT manager"
            );
        }
    }

    static async checkJson(contract: AnyNftContract, expected: string) {
        const actual = await Nfts.getJson(contract);
        expect(actual).to.be.eq(expected, "Wrong NFT JSON");
    }

    static async getRoyaltyInfo(contract: NftWithRoyaltyContract): Promise<{
        royalty: number;
        royaltyAddress: Address;
    }> {
        const salePrice = 1_000_000;
        const actual = await contract.methods
            .royaltyInfo({ answerId: 0, salePrice: 1_000_000 })
            .call();
        return {
            royalty: calculateRoyalty(salePrice, Number(actual.royaltyAmount)),
            royaltyAddress: actual.receiver,
        };
    }

    static async checkRoyaltyInfo(
        contract: NftWithRoyaltyContract,
        expected: {
            royalty?: number;
            royaltyAddress?: Address;
        }
    ) {
        const actual = await Nfts.getRoyaltyInfo(contract);
        if (expected.royalty !== undefined) {
            expect(actual.royalty).to.be.eq(expected.royalty, "Wrong NFT royalty");
        }
        if (expected.royaltyAddress !== undefined) {
            expect(actual.royaltyAddress.toString()).to.be.eq(
                expected.royaltyAddress.toString(),
                "Wrong NFT royalty address"
            );
        }
    }
}
