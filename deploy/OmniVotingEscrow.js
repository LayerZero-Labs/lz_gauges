const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)

    let votingEscrowAddress

    if (hre.network.name == "ethereum") {
        votingEscrowAddress = "0xC128a9954e6c874eA3d62ce62B468bA073093F25"
    } else if (hre.network.name == "goerli") {
        votingEscrowAddress = "0x33A99Dcc4C85C014cf12626959111D5898bbCAbF"
    } else if (hre.network.name == "hardhat"){
        votingEscrowAddress = await deployments.get("VotingEscrowMock")
    } else {
        throw `Cant deploy OmniVotingEscrow.sol on ${hre.network.name}`
    }

    await deploy("OmniVotingEscrow", {
        from: deployer,
        args: [lzEndpointAddress, votingEscrowAddress],
        log: true,
        waitConfirmations: 1,
    })
}

module.exports.tags = ["OmniVotingEscrow"]
module.exports.dependencies = ["VotingEscrowMock"]