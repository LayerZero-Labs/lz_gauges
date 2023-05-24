const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")
const verify = require('@layerzerolabs/verify-contract')

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)

    let delegationHooks = {
        "arbitrum": "0x12Ca9De662A7Bf5Dc89e034a5083eF751B08EDe7",
        "avalanche": "0x4638ab64022927C9bD5947607459D13f57f1551C",
        "bsc": "0x20AabBC59F3cE58e0ef931380d8Bf2A6fE681019",
        "gnosis": "0xeb151668006CD04DAdD098AFd0a82e78F77076c3",
        "optimism": "0xbef13D1e54D0c79DA8B0AD704883E1Cea7EB2100",
        "polygon": "0xB98F54A74590a6e681fF664b2Fa22EBfFe1a929E",
        "zkevm": "0xDEd7Fef7D8eCdcB74F22f0169e1A9EC696e6695d",
    }

    let delegationHook = delegationHooks[hre.network.name]
    if (!delegationHook) {
        throw `Invalid network: ${hre.network.name}`
    }

    await deploy("OmniVotingEscrowChild", {
        from: deployer,
        args: [lzEndpointAddress, delegationHook],
        log: true,
        waitConfirmations: 1,
    })

    await verify(hre.network.name, "OmniVotingEscrowChild")
}

module.exports.tags = ["OmniVotingEscrowChild"]
