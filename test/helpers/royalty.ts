const PERCENT_PRECISION = 1_000_000;

export function calculateRoyalty(salePrice: number, royaltyAmount: number): number {
    return Math.floor((royaltyAmount * PERCENT_PRECISION) / salePrice);
}

export function calculateRoyaltyAmount(salePrice: number, royalty: number): number {
    return Math.floor((salePrice * royalty) / PERCENT_PRECISION);
}
