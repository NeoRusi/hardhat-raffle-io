const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("1")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let vrfCoordinatorV2Address, subscriptionId
    const entranceFee = networkConfig[chainId]["entranceFee"]
    const gasLane = networkConfig[chainId]["gasLAne"]
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit "]
    const interval = networkConfig[chainId]["interval"]
    const arguments = [
        vrfCoordinatorV2Address,
        entranceFee,
        gasLAne,
        subscriptionId,
        callbackGasLimit,
        interval,
    ]
    const raffle = await deploy("Raffle", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    if (chainId == 31337) {
        const vrfCoordinatorV2Mock = ethres.getContract("VRFCoordinatorV2Mock ")
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const transactionResponse = await vrfCoordinatorV2Mock.createSubscriprion()
        const transactionReceipt = await transactionResponse.wait(1)
        subscriptionId = transactionReceipt.events[0].args.subId
        //Fund the subscription
        //Usually to fund the subscription you need link token on a real network
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT)
    } else {
        vrfCoordinatorV2Address = network.config[chainId]["VRFCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }
    if (!developmentChains.includes(network.name) && procces.env.ETHERSCAN_API_KEY) {
        log("Verifiying .....")
        await verify(raffle.address, arguments)
    }
    log("____________________________________")
}
module.exports.tags = ["all", "raffle "]
