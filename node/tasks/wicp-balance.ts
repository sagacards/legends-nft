import { managementAccountBalanceWicp } from "../cycles";

managementAccountBalanceWicp().then((balance) =>
    console.log(
        `Management account balance: ${(Number(balance) / 10 ** 8).toFixed(
            1
        )} wICP`
    )
);
