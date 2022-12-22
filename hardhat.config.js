/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-waffle");
module.exports = {
    solidity: "0.8.0",
    networks: {
        hardhat: {
            chainId: 31337,
        },
    },
};