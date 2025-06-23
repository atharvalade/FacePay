const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const PYUSD_ADDRESS = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9";

module.exports = buildModule("PaymentHubModule", (m) => {
  const pyusdAddress = m.getParameter("pyusdAddress", PYUSD_ADDRESS);

  const paymentHub = m.contract("PaymentHub", [pyusdAddress]);

  return { paymentHub };
}); 