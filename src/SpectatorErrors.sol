// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.24;

contract SpectatorErrors {
    error InvalidTokens();
    error OnlyAdmin();
    error Existing();
    error CantRemoveSelf();
    error AddressInvalid();
    error AgentAlreadyExists();
    error AgentDoesntExist();

    error NoClaim();

    error BalanceInvalid();
    error BadUserInput();
}
