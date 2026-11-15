// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITrustedIssuerRegistry} from "./interfaces/ITrustedIssuerRegistry.sol";

contract TrustedIssuerRegistry is ITrustedIssuerRegistry {
    address public admin;

    mapping(address => IssuerInfo) private _issuers;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert UnauthorizedAdmin(msg.sender);
        _;
    }

    constructor(address initialAdmin) {
        admin = initialAdmin == address(0) ? msg.sender : initialAdmin;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Zero address");
        admin = newAdmin;
    }

    function registerIssuer(
        string calldata orgName,
        uint256 pubKeyX,
        uint256 pubKeyY
    ) external override {
        if (_issuers[msg.sender].registeredAt != 0) revert IssuerAlreadyExists(msg.sender);

        _issuers[msg.sender] = IssuerInfo({
            issuerAddress: msg.sender,
            organizationName: orgName,
            publicKeyX: pubKeyX,
            publicKeyY: pubKeyY,
            status: IssuerStatus.Pending,
            registeredAt: uint64(block.timestamp)
        });

        emit IssuerRegistered(msg.sender, orgName, pubKeyX, pubKeyY);
    }

    function setIssuerStatus(address issuer, IssuerStatus newStatus) external override onlyAdmin {
        IssuerInfo storage info = _issuers[issuer];
        if (info.registeredAt == 0) revert IssuerNotFound(issuer);

        IssuerStatus oldStatus = info.status;
        info.status = newStatus;

        emit IssuerStatusChanged(issuer, oldStatus, newStatus);
    }

    function rotateIssuerKey(uint256 newPubKeyX, uint256 newPubKeyY) external override {
        IssuerInfo storage info = _issuers[msg.sender];
        if (info.registeredAt == 0) revert IssuerNotFound(msg.sender);
        if (info.status != IssuerStatus.Active) revert IssuerNotActive(msg.sender, info.status);

        info.publicKeyX = newPubKeyX;
        info.publicKeyY = newPubKeyY;

        emit IssuerKeyRotated(msg.sender, newPubKeyX, newPubKeyY);
    }

    function getIssuer(address issuer) external view override returns (IssuerInfo memory) {
        IssuerInfo memory info = _issuers[issuer];
        if (info.registeredAt == 0) revert IssuerNotFound(issuer);
        return info;
    }

    function isIssuerActive(address issuer) external view override returns (bool) {
        return _issuers[issuer].status == IssuerStatus.Active;
    }
}
