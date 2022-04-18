export function sleep(
    ms: number,
): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
};

export function isJSON(
    str: string
) {
    try {
        const json = JSON.parse(str);
        if (Object.prototype.toString.call(json).slice(8, -1) !== 'Object') {
            return false
        }
    } catch (e) {
        return false
    }
    return true
}