const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)

    let votingEscrowRemapper

    if (hre.network.name == "ethereum") {
        votingEscrowRemapper = "0xa523f47A933D5020b23629dDf689695AA94612Dc"
    // } else if (hre.network.name == "goerli") {
    //     votingEscrowRemapper = "0x33A99Dcc4C85C014cf12626959111D5898bbCAbF"
    } else if (hre.network.name == "hardhat"){
        votingEscrowRemapper = await deployments.get("VotingEscrowMock")
    } else {
        throw `Cant deploy OmniVotingEscrow.sol on ${hre.network.name}`
    }

    await deploy("OmniVotingEscrow", {
        from: deployer,
        args: [lzEndpointAddress, votingEscrowRemapper],
        log: true,
        waitConfirmations: 1,
    })
}

module.exports.tags = ["OmniVotingEscrow"]
module.exports.dependencies = ["VotingEscrowMock"]