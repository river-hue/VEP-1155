import { WalletTypes, toNano } from "locklift";
import { Account, Signer } from "everscale-standalone-client/nodejs";
import { Contracts } from "./contracts";
import { expect } from "chai";

export class Actors {
    static async deploy(idx = '0', initial_balance = 10): Promise<{
        account: Account;
        signer: Signer
    }> {
        const signer = await locklift.keystore.getSigner(idx);
        const account = (await locklift.factory.accounts.addNewAccount({
            type: WalletTypes.EverWallet,
            value: toNano(initial_balance),
            publicKey: signer.publicKey,
        })).account;
    
        expect(await Contracts.getContractBalance(account.address)).to.be.above(0);
    
        return { account, signer };
    }
}