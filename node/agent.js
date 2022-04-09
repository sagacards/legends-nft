const { HttpAgent, Actor } = require("@dfinity/agent");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const fs = require("fs");
const fetch = require("cross-fetch");

const enviros = {
  ic: {
    name: "ic",
    url: "https://ic0.app",
  },
};

const KEY_FILE = `keys.json`;
const getKey = (keyfile) => fs.readFileSync(keyfile).toString();
const saveKey = (keyfile, data) => fs.writeFileSync(keyfile, data);

function getAuthKey(
  name = 'default',
) {
  let key = null;
  if (fs.existsSync(KEY_FILE)) {
    const keys = JSON.parse(getKey(KEY_FILE));
    key = keys[name];
    if (key) {
      return Ed25519KeyIdentity.fromParsedJson(key);
    } else {
      key = Ed25519KeyIdentity.generate();
      keys[name] = key
      saveKey(KEY_FILE, JSON.stringify(keys, null, 4));
    }
  } else {
    key = Ed25519KeyIdentity.generate();
    saveKey(KEY_FILE, JSON.stringify({[name] : key}, null, 4));
  }
  return key;
}

const getActor = (idlFactory, canisterId, key) => {
  let enviro = enviros["ic"];
  const agent = new HttpAgent({ fetch, identity: key, host: enviro.url });
  let actorConstructor = Actor.createActorClass(idlFactory);

  globalThis.ic = { HttpAgent, canister: undefined, agent };

  return new actorConstructor({ agent, canisterId: canisterId });
};

exports.getAuthKey = getAuthKey;
exports.getActor = getActor;