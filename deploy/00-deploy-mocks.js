const { network } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const BASE_FEE = ethers.utils.parseEther("0.25") // 0.25 is premium. It costs 0.25 link
const GAS_PRICE_LINK = 1e9
// calculated value based of the gas price of the chain
//If the eth price grows up
//Chainlink nodes may pay the gas fees to give us randomness & do external exedcution
//So the price of requests changes according to the gas price

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    if (chainId == 31337) {
        log("Local network detected! Deploying mocks....")
        //deploy amock vrfcoordinator ?
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK],
        })
        log("Mocks deployed !")
        log("__________________________________________________")
        log("You are deploying to a local network, you'll need a local network running to interact")
        log("Please run `npx hardhat console` to interact with the deployed smart contracts!")
        log("__________________________________________________")
    }
}

module.exports.tags = ["all", "mocks"]
