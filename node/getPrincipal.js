const { getAuthKey } = require('./agent');

const myArgs = process.argv.slice(2);

const identity = getAuthKey(myArgs[0]);
console.log(identity.getPrincipal().toText());
