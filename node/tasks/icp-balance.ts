import { managementAccountBalanceIcp } from "../cycles";

managementAccountBalanceIcp().then((balance) =>
    console.log(
        `Management account balance: ${(Number(balance) / 10 ** 8).toFixed(
            1
        )} ICP`
    )
);
