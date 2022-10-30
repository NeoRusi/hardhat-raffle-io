const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers, network } = require("hardhat")
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

developmentChains.includes(network.name)
    ? describe.skib
    : describe("Raffle Stagging tests", async () => {
          let raffle, raffleEntranceFee, deployer
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              raffle = await ethers.getContract("Raffle", deployer)
              raffleEntranceFee = await raffle.getEntranceFee()
          })
      })
describe("fulfillRandomWords", async () => {
    it("works with live chainlink keepers and Chainlink VRF, we get a random winner", async function () {
        //Enter the raffle
        const startingTimeStamp = await raffle.getLatestTimeStamp()
        const accounts = ethers.getSigners()
        // set up the listener before we enter the raffle contract
        //Just in case the blockchain moves realy fast
        await new Promise(async (resolve, reject) => {
            raffle.once("WinnerPicked", async () => {
                console.log("WinnerPicked event fired!")
                resolve()
                try {
                    //Add our assets here
                    const recentWinner = await raffle.getRecentWinner()
                    const raffleState = await raffle.getRaffleState()
                    const winnerEndingBalance = await accounts[0].getBalance()
                    const endingTimeStamp = await raffle.getLatestTimeStamp()
                    await expect(raffle.getPlayer(0)).to.be.reverted
                    assert.equal(recentWinner.toString(), accounts[0].address)
                    assert.equal(raffleState.toString(), "0")
                    assert.equal(
                        winnerEndingBalance.toString(),
                        winnerStartingBalance.add(raffleEntranceFee).toString()
                    )
                    assert(endingTimeStamp > startingTimeStamp)
                    resolve()
                } catch (e) {
                    reject()
                }
            })
            //Then entering the raffle
            await raffle.enterRaffle({ value: raffleEntranceFee })
            const winnerStartingBalance = await accounts[0].getBalance()
            //And this code womt be complete until our listener finished listening!
        })
    })
})
