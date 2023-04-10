pragma ton-solidity >= 0.58.0;

library TokenErrors {
    uint16 constant NOT_DEPLOYER                = 2300;
    uint16 constant SEND_NOT_TOKEN_OWNER        = 2301;
    uint16 constant EMPTY_VALUE                 = 2302;
    uint16 constant SENDER_NOT_COLLECTION       = 2303;
    uint16 constant VALUE_TOO_LOW               = 2304;
    uint16 constant WRONG_COUNT                 = 2305;
    uint16 constant NOT_ENOUGH_BALANCE          = 2306;
    uint16 constant WRONG_RECIPIENT             = 2307;
    uint16 constant SENDER_IS_NOT_VALID_TOKEN   = 2308;
    uint16 constant NON_EMPTY_BALANCE           = 2309;
    uint16 constant EMPTY_SALT                  = 2310;
    uint16 constant NO_OWNER                    = 2311;
}