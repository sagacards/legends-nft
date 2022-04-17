import fs from 'fs';
import fetch from 'cross-fetch';
import { IDL } from '@dfinity/candid';
import { HttpAgent, Actor, Identity, ActorSubclass } from '@dfinity/agent';
import { Ed25519KeyIdentity } from '@dfinity/identity';
import { uniqueNamesGenerator, adjectives, colors, animals } from 'unique-names-generator';

const enviros = {
    ic: {
        name: "ic",
        url: "https://ic0.app",
    },
};

const KEY_FILE = `keys.json`;
const getKey = (keyfile: string) => fs.readFileSync(keyfile).toString();
const saveKey = (keyfile: string, data: string) => fs.writeFileSync(keyfile, data);

/** A user which should be granted elevated permissions. */
export const admin = { name: "admin", key: getAuthKey("admin") };

/**
 * Generate a new identity with a random name and key pair.
 * @returns A new random user
 */
export function randomUser () {
    const name = uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals] });
    return { name, key: getAuthKey(name) };
};

export function getAuthKey(
    name: string = 'default',
): Ed25519KeyIdentity {
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
        saveKey(KEY_FILE, JSON.stringify({ [name]: key }, null, 4));
    }
    return key;
}

export function getActor<T>(
    idlFactory: IDL.InterfaceFactory,
    canisterId: string,
    key: Identity,
): ActorSubclass<T> {
    const agent = new HttpAgent({
        fetch,
        identity: key,
        host: enviros.ic.url,
    });
    const actorConstructor = Actor.createActorClass(idlFactory);

    return new actorConstructor({
        agent,
        canisterId: canisterId
    }) as unknown as ActorSubclass<T>;
};
