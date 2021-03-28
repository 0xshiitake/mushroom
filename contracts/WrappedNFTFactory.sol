pragma solidity ^0.8.0;

import "./WrappedNFT.sol"
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WrappedNFTFactory is Ownable, Pausable {

    // Mapping between baseNFTContracts and wrapperNFTContracts;
    mapping(address => address) wrappedNFTContracts;

    /**
     * @dev Initializes the contract settings
     */
    constructor() public {}

    /**
     * @dev Gets address of the underlying base NFT contract
     */
    function newWrappedNFTContract(address baseNFTContract)
        public
        returns (address)
    {
        require(wrapperContracts[baseNFTContract] == address(0), "Wrapped NFT Factory: wrapper for this NFT address already exists");
        WrappedNFT wnft = new WrappedNFT(baseNFTContract);
        wrappedNFTContracts[baseNFTContract] = wnft;
        return wnft;
    }

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }
}