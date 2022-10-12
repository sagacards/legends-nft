import {
    canisterBalances,
    initCanisterActors,
    localCanisterIds,
    parseCanisterIds,
} from "../cycles";

const canisters = parseCanisterIds(localCanisterIds());
const actors = initCanisterActors(canisters);
canisterBalances(actors).then(console.log);
