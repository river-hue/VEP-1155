import { Address, Contract } from "locklift";
import { calculateRoyalty } from "./royalty";
import { FactorySource } from "build/factorySource";
import { expect } from "chai";

export declare type MultiTokenWalletContract = Contract<FactorySource['MultiTokenWallet']>;
export declare type MultiTokenWalletWithRoyaltyContract = Contract<FactorySource['MultiTokenWalletWithRoyalty']>;
export declare type AnyMultiTokenWalletContract = MultiTokenWalletContract | MultiTokenWalletWithRoyaltyContract;

export class MultiTokens {
    static attachDeployed(address: Address): MultiTokenWalletContract {
        return locklift.factory.getDeployedContract(
            'MultiTokenWallet',
            address
        );
    }
    
    static attachDeployedWithRoyalty(address: Address): MultiTokenWalletWithRoyaltyContract {
        return locklift.factory.getDeployedContract(
            'MultiTokenWalletWithRoyalty',
            address
        );
    }

    static async getInfo(contract: AnyMultiTokenWalletContract): Promise<{
        collection?: Address;
        id?: string;
        owner?: Address;
    }> {
        return contract.methods.getInfo({ answerId: 0 }).call();
    }

    static async getJson(contract: AnyMultiTokenWalletContract): Promise<string> {
        return (await contract.methods.getJson({ answerId: 0 }).call()).json;
    }

    static async getBalance(contract: AnyMultiTokenWalletContract): Promise<number> {
        return Number(
            (await contract.methods.balance({ answerId: 0 }).call()).value
        );
    }

    static async checkInfo(
        contract: AnyMultiTokenWalletContract,
        expected: {
            collection?: Address;
            id?: string;
            owner?: Address;
        }
    ) {
        const actual = await MultiTokens.getInfo(contract);
        if (expected.collection !== undefined) {
            expect(actual.collection.toString()).to.be.eq(
                expected.collection.toString(),
                "Wrong token collection"
            );
        }
        if (expected.id !== undefined) {
            expect(actual.id).to.be.eq(expected.id, "Wrong token id");
        }
        if (expected.owner !== undefined) {
            expect(actual.owner.toString()).to.be.eq(
                expected.owner.toString(),
                "Wrong token owner"
            );
        }
    }

    static async checkJson(contract: AnyMultiTokenWalletContract, expected: string) {
        const actual = await MultiTokens.getJson(contract);
        expect(actual).to.be.eq(expected, "Wrong token JSON");
    }

    static async checkBalance(
        contract: AnyMultiTokenWalletContract,
        expected: number
    ) {
        const actual = await MultiTokens.getBalance(contract);
        expect(actual).to.be.eq(expected, "Wrong token balance");
    }


    static async getRoyaltyInfo(
        contract: MultiTokenWalletWithRoyaltyContract
    ): Promise<{
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
        contract: MultiTokenWalletWithRoyaltyContract,
        expected: {
            royalty?: number;
            royaltyAddress?: Address;
        }
    ) {
        const actual = await MultiTokens.getRoyaltyInfo(contract);
        if (expected.royalty !== undefined) {
            expect(actual.royalty).to.be.eq(expected.royalty, "Wrong token royalty");
        }
        if (expected.royaltyAddress !== undefined) {
            expect(actual.royaltyAddress.toString()).to.be.eq(
                expected.royaltyAddress.toString(),
                "Wrong token royalty address"
            );
        }
    }
}
