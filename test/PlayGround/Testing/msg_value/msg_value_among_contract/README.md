## Behavior
1. `ContractA` sends X amount of native via `msg.value` to `ContractB`
2. `ContractB` calls `ContractC` without forwarding `msg.value`
3. `ContractC` calls `ContractB` (No reentrancy, a normal callback) and validates ContractB has access to the `msg.value` that `ContractA` sent on step1
4. `ConctractB` receives callback from `ContractC`, no msg.value passed, and `ContractB` still has the native received from `ContractA` on step1