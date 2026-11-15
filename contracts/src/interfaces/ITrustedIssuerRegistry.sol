// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITrustedIssuerRegistry {
    enum IssuerStatus { Inactive, Pending, Active, Suspended, Revoked }

    struct IssuerInfo {
        address issuerAddress;
        string organizationName;
        uint256 publicKeyX;
        uint256 publicKeyY;
        IssuerStatus status;
        uint64 registeredAt;
    }

    event IssuerRegistered(address indexed issuer, string organizationName, uint256 pubKeyX, uint256 pubKeyY);
    event IssuerStatusChanged(address indexed issuer, IssuerStatus oldStatus, IssuerStatus newStatus);
    event IssuerKeyRotated(address indexed issuer, uint256 newPubKeyX, uint256 newPubKeyY);

    error IssuerAlreadyExists(address issuer);
    error IssuerNotFound(address issuer);
    error IssuerNotActive(address issuer, IssuerStatus status);
    error UnauthorizedAdmin(address caller);

    function registerIssuer(string calldata orgName, uint256 pubKeyX, uint256 pubKeyY) external;
    function setIssuerStatus(address issuer, IssuerStatus status) external;
    function rotateIssuerKey(uint256 newPubKeyX, uint256 newPubKeyY) external;
    function getIssuer(address issuer) external view returns (IssuerInfo memory);
    function isIssuerActive(address issuer) external view returns (bool);
}
