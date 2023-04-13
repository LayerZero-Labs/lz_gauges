// import * as bip39 from ‘bip39’

module.exports = async function (taskArgs, hre) {
    const bip39 = require("bip39")

    const mnemonic = bip39.generateMnemonic()
    console.log(mnemonic)

    let mnemonicWallet = ethers.Wallet.fromMnemonic(mnemonic)
    console.log(mnemonicWallet.privateKey)
    console.log(mnemonicWallet.publicKey)
}
