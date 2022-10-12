import { managementAccountBalanceXtc } from "../cycles";

managementAccountBalanceXtc().then((balance) =>
    console.log(
        `Management account balance: ${(Number(balance) / 10 ** 12).toFixed(
            1
        )}T XTC`
    )
);
